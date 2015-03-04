//
//  DFCameraRollScanDB.m
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFCameraRollScanDB.h"
#import <FMDB/FMDB.h>

@interface DFCameraRollScanDB()

@property (nonatomic, retain) FMDatabase *db;
@property (nonatomic, retain) FMDatabaseQueue *dbQueue;

@end

@implementation DFCameraRollScanDB

+ (DFCameraRollScanDB *)sharedDB {
  static DFCameraRollScanDB *defaultDB = nil;
  if (!defaultDB) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      defaultDB = [[super allocWithZone:nil] init];
    });
  }
  return defaultDB;
}

+ (id)allocWithZone:(NSZone *)zone
{
  return [self sharedDB];
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _db = [FMDatabase databaseWithPath:[self.class dbPath]];
    
    if (![_db open]) {
      DDLogError(@"Error opening camera roll scan database, error code: %d", [_db lastErrorCode]);
      _db = nil;
    }
    if (![_db tableExists:@"screenshots"]) {
      [_db executeUpdate:@"CREATE TABLE screenshots (localIdentifier STRING, state NUMBER)"];
    }
    if (![_db tableExists:@"scanned"]) {
      [_db executeUpdate:@"CREATE TABLE scanned (localIdentifier STRING, scanVersion NUMBER)"];
    }
    
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self.class dbPath]];
  }
  return self;
}

+ (NSString *)dbPath
{
  NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  NSURL *dbURL = [documentsURL URLByAppendingPathComponent:@"camera_roll.db"];
  return [dbURL path];
}

- (NSMutableSet *)localIdentifiersOfScreenshots
{
  FMResultSet *results = [self.db executeQuery:@"SELECT localIdentifier FROM screenshots"];
  NSMutableSet *resultIDs = [NSMutableSet new];
  while ([results next]) {
    [resultIDs addObject:[results stringForColumn:@"localIdentifier"]];
  }
  return resultIDs;
}

- (void)addScreenshot:(NSString *)screnshotID withState:(NSNumber *)state
{
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"INSERT INTO screenshots VALUES (?, ?)",
     screnshotID,
     state];
  }];
}

- (NSMutableSet *)scannedIdentifiersForVersion:(NSNumber *)version
{
  FMResultSet *results = [self.db executeQuery:@"SELECT localIdentifier FROM scanned WHERE scanVersion=(?)", version];
  NSMutableSet *resultIDs = [NSMutableSet new];
  while ([results next]) {
    [resultIDs addObject:[results stringForColumn:@"localIdentifier"]];
  }
  return resultIDs;
}

- (void)addScannedIdentifier:(NSString *)identifier scanVersion:(NSNumber *)version
{
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"INSERT INTO scanned VALUES (?, ?)",
     identifier,
     version];
  }];
}



@end
