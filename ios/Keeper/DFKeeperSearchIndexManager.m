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
#import <BRFullTextSearch/BRFullTextSearch.h>
#import <CLuceneSearchService.h>

@interface DFKeeperSearchIndexManager()

@property (nonatomic, retain) Firebase *searchDocsRef;
@property (nonatomic, retain) id<BRSearchService> searchService;
@property (nonatomic) dispatch_queue_t index_queue;
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
    dispatch_queue_attr_t queue_attr =  dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
                                            QOS_CLASS_DEFAULT,
                                            0);
    self.index_queue = dispatch_queue_create("KeeperSearchIndexManager", queue_attr);
    self.searchService = [[CLuceneSearchService alloc] initWithIndexPath:[self.class indexPath]];;
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
  dispatch_async(self.index_queue, ^{
    NSMutableSet *notFoundIdentifiersInIndex = [NSMutableSet new];
    [[self allResultsInIndex] iterateWithBlock:^(NSUInteger index, id<BRSearchResult> result, BOOL *stop) {
      /// the identifier has the type (?) in front of the ID, so we have to remove it 
      NSString *identifier = [[result valueForField:kBRSearchFieldNameIdentifier] substringFromIndex:1];
      [notFoundIdentifiersInIndex addObject:identifier];
    }];
    
    DDLogVerbose(@"%@ delete scan identifiers in index: %@ foundSearchDocs: %@", self.class,
                 notFoundIdentifiersInIndex,
                 foundSearchDocKeys);
    [notFoundIdentifiersInIndex minusSet:foundSearchDocKeys];
    
    if (notFoundIdentifiersInIndex.count > 0) {
      DDLogInfo(@"%@ %@ photos in index need to be deleted", self.class, @(notFoundIdentifiersInIndex.count));
      [self removeKeysFromIndex:notFoundIdentifiersInIndex.allObjects];
    }
  });
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
  dispatch_async(self.index_queue, ^{
    DDLogVerbose(@"%@ indexing %@ with value %@", self.class, key, value);
    // add a document to the index
    if (!key || !value) return;
    id<BRIndexable> doc = [[BRSimpleIndexable alloc]
                           initWithIdentifier:key
                           data:@{
                                  kBRSearchFieldNameValue : value
                                  }];
    NSError *error = nil;
    [self.searchService addObjectToIndexAndWait:doc error:&error];
    if (error) DDLogError(@"%@ error indexing: %@", self.class, error);
  });
}

- (void)removeKeysFromIndex:(NSArray *)keys
{
  dispatch_async(self.index_queue, ^{
    NSSet *keySet = [NSSet setWithArray:keys];
    NSError *error;
    [self.searchService removeObjectsFromIndexAndWait:BRSearchObjectTypeForString(@"?")
                                      withIdentifiers:keySet
                                                error:&error];
    if (error)DDLogError(@"%@ error removing keys: %@", self.class, error);
    else DDLogInfo(@"%@ removed key for objects: %@", self.class, keySet);
  });
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
  
  static NSExpression *ValueExpression; if ( ValueExpression == nil ) {
    ValueExpression = [NSExpression expressionForKeyPath:kBRSearchFieldNameValue];
  }
  NSArray *tokens = [[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                     componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:([tokens count] * 2)];
  for ( NSString *token in tokens ) {
    [predicates addObject:[NSComparisonPredicate
                           predicateWithLeftExpression:ValueExpression
                           rightExpression:[NSExpression expressionForConstantValue:token]
                           modifier:NSDirectPredicateModifier
                           type:NSLikePredicateOperatorType
                           options:0]];
    [predicates addObject:[NSComparisonPredicate
                           predicateWithLeftExpression:ValueExpression
                           rightExpression:[NSExpression expressionForConstantValue:token]
                           modifier:NSDirectPredicateModifier
                           type:NSBeginsWithPredicateOperatorType
                           options:0]];
  }
  NSPredicate *predicateQuery = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
  
  id<BRSearchResults> results = [self.searchService
                                 searchWithPredicate:predicateQuery
                                 sortBy:nil
                                 sortType:0
                                 ascending:NO];
  NSMutableArray *keys = [NSMutableArray new];
  [results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
    DDLogVerbose(@"For query %@ found result: %@", predicateQuery, [result valueForField:kBRSearchFieldNameValue]);
    DFKeeperSearchResult *searchResult = [[DFKeeperSearchResult alloc] init];
    NSString *photoKey = [result identifier];
    searchResult.objectKey = photoKey;
    searchResult.documentString = [result valueForField:kBRSearchFieldNameValue];
    [keys addObject:searchResult];
  }];
  
  completion(keys);
}

- (void)resultForKey:(NSString *)key completion:(void(^)(DFKeeperSearchResult *result))completion
{
  id<BRSearchResult> result = [self.searchService findObject:BRSearchObjectTypeForString(@"?")
                                              withIdentifier:key];
  DFKeeperSearchResult *searchResult = [[DFKeeperSearchResult alloc] init];
  searchResult.objectKey = [result identifier];
  searchResult.documentString = [result valueForField:kBRSearchFieldNameValue];
  completion(searchResult);
}

- (void)printFullIndex
{
  [[self allResultsInIndex] iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
    DDLogVerbose(@"%@ result in index: %@", self.class, [result dictionaryRepresentation]);
  }];
}

- (id<BRSearchResults>)allResultsInIndex
{
  static NSExpression *ValueExpression; if ( ValueExpression == nil ) {
    ValueExpression = [NSExpression expressionForKeyPath:kBRSearchFieldNameTimestamp];
  }
  
  NSPredicate *predicate = [NSComparisonPredicate
                            predicateWithLeftExpression:ValueExpression
                            rightExpression:[NSExpression expressionForConstantValue:@(0)]
                            modifier:NSDirectPredicateModifier
                            type:NSGreaterThanOrEqualToPredicateOperatorType
                            options:0];
  
  id<BRSearchResults> results = [self.searchService
                                 searchWithPredicate:predicate
                                 sortBy:nil
                                 sortType:0
                                 ascending:NO];
  return results;
}



+ (NSString *)indexPath
{
  NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                inDomains:NSUserDomainMask] lastObject];
  NSURL *dbURL = [documentsURL URLByAppendingPathComponent:@"searchindex.clucene"];
  return [dbURL path];
}


- (void)resetIndex
{
  DDLogInfo(@"%@ resetting index", self.class);
  NSError *error;
  [self.searchService bulkUpdateIndexAndWait:^(id<BRIndexUpdateContext> updateContext) {
    [self.searchService removeAllObjectsFromIndex:updateContext];
  } error:&error];
  
  if (error) DDLogError(@"%@ error resetting index: %@", self.class, error);
  
}


@end
