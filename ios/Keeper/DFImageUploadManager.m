//
//  DFImageUploadManager.m
//  Keeper
//
//  Created by Henry Bridge on 2/27/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFImageUploadManager.h"
#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/S3.h>
#import <FMDB/FMDB.h>
#import "DFNetworkingConstants.h"
#import "AppDelegate.h"
#import "DFKeeperStore.h"

@interface DFImageUploadManager()

@property (strong, nonatomic) NSURLSession *session;
@property (nonatomic, retain) NSMutableSet *uploadsInProgress;
@property (strong, nonatomic) FMDatabase *db;
@property (strong, nonatomic) FMDatabaseQueue *dbQueue;

@end

@implementation DFImageUploadManager

+ (DFImageUploadManager *)sharedManager {
  static DFImageUploadManager *defaultManager = nil;
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
    [self initDB];
    _uploadsInProgress = [[NSMutableSet alloc] init];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration
                                                backgroundSessionConfigurationWithIdentifier:BackgroundSessionUploadIdentifier];
    configuration.HTTPMaximumConnectionsPerHost = 1; // only upload one file at a time
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
  }
  return self;
}

- (void)uploadImageFile:(NSURL *)imageFile forKey:(NSString *)key {
  if ([self isUploadInProgress:key]) return;
  if (![[NSFileManager defaultManager] fileExistsAtPath:[imageFile path]]) {
    DDLogError(@"%@ asked to upload non-existent file: %@", self.class, imageFile);
    return;
  }
  DDLogInfo(@"%@ queing for upload %@", self.class, key);
  
  AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
  getPreSignedURLRequest.bucket = S3BucketName;
  getPreSignedURLRequest.key = key;
  getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodPUT;
  getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
  
  //Important: must set contentType for PUT request
  NSString *fileContentTypeStr = @"image/jpeg";
  getPreSignedURLRequest.contentType = fileContentTypeStr;
  
  [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:getPreSignedURLRequest] continueWithBlock:^id(BFTask *task) {
    if (task.error) {
      NSLog(@"%@ task error: %@", self.class, task.error);
    } else {
      NSURL *presignedURL = task.result;
      
      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
      request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
      [request setHTTPMethod:@"PUT"];
      [request setValue:fileContentTypeStr forHTTPHeaderField:@"Content-Type"];
      
      NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromFile:imageFile];
      uploadTask.taskDescription = key;
      [uploadTask resume];
    }
    return nil;
  }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
  double progress = (double)totalBytesSent / (double)totalBytesExpectedToSend;
  DDLogVerbose(@"UploadTask progress: %lf", progress);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
  if (!error) {
    NSString *urlString = [NSString stringWithFormat:@"%@://%@%@",
                           task.currentRequest.URL.scheme,
                           task.currentRequest.URL.host,
                           task.currentRequest.URL.path
                           ];
    DDLogInfo(@"S3 upload completed %@", urlString);
    [self addToDBImageForType:DFImageFull forKey:task.taskDescription];
  }else {
    DDLogError(@"S3 upload error: %@", error);
  }
  [self setKey:task.taskDescription inProgress:NO];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
  
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  if (appDelegate.backgroundUploadSessionCompletionHandler) {
    void (^completionHandler)() = appDelegate.backgroundUploadSessionCompletionHandler;
    appDelegate.backgroundUploadSessionCompletionHandler = nil;
    completionHandler();
  }
  
  DDLogInfo(@"%@ completion handler invoked, background upload task has finished.", self.class);
}

#pragma mark - Upload in progress

NSString *const syncToken = @"sync";

- (void)setKey:(NSString *)key inProgress:(BOOL)inProgress
{
  @synchronized(syncToken) {
    if (inProgress)
      [self.uploadsInProgress addObject:key];
    else
      [self.uploadsInProgress removeObject:key];
  }
}

- (BOOL)isUploadInProgress:(NSString *)key
{
  BOOL result;
  @synchronized(syncToken) {
    result = [self.uploadsInProgress containsObject:key];
  }
  return result;
}

#pragma mark - Upload DB

- (void)initDB
{
  _db = [FMDatabase databaseWithPath:[self.class dbPath]];
  
  if (![_db open]) {
    DDLogError(@"Error opening uploadedImages database, error code: %d", [_db lastErrorCode]);
    _db = nil;
  }
  if (![_db tableExists:@"uploadedImages"]) {
    [_db executeUpdate:@"CREATE TABLE uploadedImages (image_type NUMBER, photo_key STRING)"];
  }
  
  _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self.class dbPath]];
}

+ (NSString *)dbPath
{
  NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  NSURL *dbURL = [documentsURL URLByAppendingPathComponent:@"uploaded_images.db"];
  return [dbURL path];
}

- (NSSet *)uploadedKeys
{
  return [[self keysFromDBForType:DFImageFull] copy];
}

- (NSMutableSet *)keysFromDBForType:(DFImageType)type
{
  FMResultSet *results = [self.db executeQuery:@"SELECT photo_key FROM uploadedImages WHERE image_type=(?)", @(type)];
  NSMutableSet *resultIDs = [NSMutableSet new];
  while ([results next]) {
    [resultIDs addObject:[results stringForColumn:@"photo_key"]];
  }
  return resultIDs;
}

- (BOOL)isImageTypeCached:(DFImageType)type forKey:(NSString *)imageKey
{
  NSSet *ids = [self keysFromDBForType:type];
  return [ids containsObject:imageKey];
}

- (void)addToDBImageForType:(DFImageType)type forKey:(NSString *)key
{
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"INSERT INTO uploadedImages VALUES (?, ?)",
     @(type),
     key];
    DDLogInfo(@"%@ setting uploaded photo %@ type:%@", self.class,
              key,
              type == DFImageFull ? @"full" : @"thumbnail");
  }];
}




@end
