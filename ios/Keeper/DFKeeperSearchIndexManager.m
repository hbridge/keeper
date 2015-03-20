//
//  DFKeeperSearchIndexManager.m
//  Keeper
//
//  Created by Henry Bridge on 3/6/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperSearchIndexManager.h"
#import <Firebase/Firebase.h>
#import "DFKeeperStore.h"
#import "DFUser.h"
#import <FMDB/FMDB.h>
#import "DFSQLRankFunc.h"

@interface DFKeeperSearchIndexManager()

@property (nonatomic, retain) Firebase *searchDocsRef;
@property (nonatomic, retain) FMDatabaseQueue *dbQueue;


@end

@implementation DFKeeperSearchIndexManager

+ (DFKeeperSearchIndexManager *)sharedManager {
  static DFKeeperSearchIndexManager *defaultManager = nil;
  if (!defaultManager) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      defaultManager = [[super allocWithZone:nil] init];
    });
  }
  return defaultManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
  return [self sharedManager];
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self.class indexPath]];
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
      [db executeUpdate:@"CREATE VIRTUAL TABLE IF NOT EXISTS docs USING fts4(id, contents);"];
      sqlite3 *sqllite_db = [db sqliteHandle];
      sqlite3_create_function(sqllite_db, "rank", -1, SQLITE_UTF8, NULL,
                              &rankfunc, NULL, NULL);
      
    }];
    
    self.searchDocsRef= [[[Firebase alloc] initWithUrl:DFFirebaseRootURLString]
                    childByAppendingPath:@"searchDocs"];
    [self printFullIndex];
  }
  return self;
}

- (void)resumeIndexing
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self observeSearchDocChanges];
  });
}

- (void)scanForDeletedDocs:(NSSet *)foundSearchDocKeys
{
  
//  dispatch_async(self.index_queue, ^{
//    NSMutableSet *notFoundIdentifiersInIndex = [NSMutableSet new];
//    [[self allResultsInIndex] iterateWithBlock:^(NSUInteger index, id<BRSearchResult> result, BOOL *stop) {
//      /// the identifier has the type (?) in front of the ID, so we have to remove it 
//      NSString *identifier = [[result valueForField:kBRSearchFieldNameIdentifier] substringFromIndex:1];
//      [notFoundIdentifiersInIndex addObject:identifier];
//    }];
//    
//    DDLogVerbose(@"%@ delete scan identifiers in index: %@ foundSearchDocs: %@", self.class,
//                 notFoundIdentifiersInIndex,
//                 foundSearchDocKeys);
//    [notFoundIdentifiersInIndex minusSet:foundSearchDocKeys];
//    
//    if (notFoundIdentifiersInIndex.count > 0) {
//      DDLogInfo(@"%@ %@ photos in index need to be deleted", self.class, @(notFoundIdentifiersInIndex.count));
//      [self removeKeysFromIndex:notFoundIdentifiersInIndex.allObjects];
//    }
//  });
}

- (void)observeSearchDocChanges
{
  [self.searchDocsRef removeAllObservers];
  [[[self.searchDocsRef queryOrderedByChild:@"user"]
    queryEqualToValue:[DFUser loggedInUser]]
   observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *allDocsSnapshot) {
     NSMutableSet *allKeys = [NSMutableSet new];
     
     
     for (FDataSnapshot *snapshot in allDocsSnapshot.children) {
       [allKeys addObject:snapshot.key];
       NSString *key = snapshot.key;
       NSString *value = snapshot.value[@"text"];
       [self indexKey:key value:value];
     }
     
     [self scanForDeletedDocs:allKeys];
   }];
}

- (void)indexKey:(NSString *)key value:(NSString *)value
{
  [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    FMResultSet *resultSet = [db executeQuery:@"SELECT id FROM docs WHERE id = ?", key];
    if ([resultSet next]) {
      [db executeUpdate:@"UPDATE docs SET contents = ? WHERE id like ?", value, key];
    } else {
      [db executeUpdate:@"INSERT INTO docs (id, contents) VALUES(?, ?);", key, value];
    }
  }];
}

- (void)removeKeysFromIndex:(NSArray *)keys
{
  for (NSString *key in keys) {
    [self.dbQueue inDatabase:^(FMDatabase *db) {
      [db executeUpdate:@"DELETE FROM docs WHERE id = ?", key];
    }];
  }
}

- (void)deleteIndexedDocumentForObject:(NSString *)objectKey
{
  Firebase *docRef = [self.searchDocsRef childByAppendingPath:objectKey];
  [docRef setValue:nil];
}

- (void)keysMatchingSearch:(NSString *)searchString completion:(void(^)(NSArray *results))completion
{
  if (![searchString isNotEmpty]) {
    completion(nil);
    return;
  }
  
  // split into tokens, add asterisks and make them match for substrings
  NSMutableArray *tokens = [[[searchString lowercaseString] componentsSeparatedByString:@" "] mutableCopy];
  for (NSInteger i = tokens.count - 1; i >= 0; i--) {
    NSString *token = tokens[i];
    if ([token isNotEmpty]) {
      tokens[i] = [token stringByAppendingString:@"*"];
    } else {
      [tokens removeObjectAtIndex:i];
    }
  }

  NSString *queryString = [NSString stringWithFormat:@" '%@'", [tokens componentsJoinedByString:@" OR "]];
  NSMutableString *sqlString = [@"SELECT id, contents FROM docs JOIN(" mutableCopy];
  [sqlString appendString:@"SELECT docid, id, rank(matchinfo(docs)) AS rank"];
  [sqlString appendString:@" FROM docs"];
  [sqlString appendString:@" WHERE docs MATCH"];
  [sqlString appendString:queryString];
  [sqlString appendString:@" ORDER BY rank DESC"];
  [sqlString appendString:@" LIMIT 10 OFFSET 0"];
  [sqlString appendString:@") AS ranktable USING(id)"];
  [sqlString appendString:@" ORDER BY ranktable.rank DESC"];
  DDLogVerbose(@"Query:%@", sqlString);
  
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    NSMutableArray *results = [NSMutableArray array];
    FMResultSet *resultSet = [db executeQuery:sqlString];
    while ([resultSet next]) {
      DFKeeperSearchResult *result = [DFKeeperSearchResult new];
      result.objectKey = [resultSet stringForColumn:@"id"];
      result.documentString = [resultSet stringForColumn:@"contents"];
      [results addObject:result];
    }
    completion(results);
  }];
}

- (void)resultForKey:(NSString *)key completion:(void(^)(DFKeeperSearchResult *result))completion
{
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    NSMutableArray *results = [NSMutableArray array];
    FMResultSet *resultSet = [db executeQuery:@"SELECT id, contents FROM docs WHERE id = ?", key];
    while ([resultSet next]) {
      DFKeeperSearchResult *result = [DFKeeperSearchResult new];
      result.objectKey = [resultSet stringForColumn:@"id"];
      result.documentString = [resultSet stringForColumn:@"contents"];
      [results addObject:result];
    }
    completion(results.firstObject);
  }];
}

- (void)printFullIndex
{
  [self fetchAllResults:^(FMResultSet *resultSet) {
    while ([resultSet next]) {
      DDLogVerbose(@"%@ result in index: %@: %@", self.class,
                   [resultSet stringForColumn:@"id"],
                   [resultSet stringForColumn:@"contents"]);
    }
  }];
}

- (void)fetchAllResults:(void(^)(FMResultSet *resultSet))completion
{
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet *resultSet = [db executeQuery:@"SELECT * FROM docs"];
    completion(resultSet);
  }];
}

+ (NSString *)indexPath
{
  NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                inDomains:NSUserDomainMask] lastObject];
  NSURL *dbURL = [documentsURL URLByAppendingPathComponent:@"searchindex.db"];
  return [dbURL path];
}


- (void)resetIndex
{
  DDLogInfo(@"%@ resetting index", self.class);
  NSError *error;
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"DROP TABLE docs"];
  }];
  
  if (error) DDLogError(@"%@ error resetting index: %@", self.class, error);
}







@end
