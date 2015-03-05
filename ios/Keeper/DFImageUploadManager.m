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
#import "AppDelegate.h"

@interface DFImageUploadManager()

@property (strong, nonatomic) NSURLSession *session;
@property (nonatomic, retain) NSMutableSet *uploadsInProgress;

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

- (void)deleteImageWithKey:(NSString *)key
{
    DDLogInfo(@"%@ deleting image with key: %@", self.class, key);
    AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
    getPreSignedURLRequest.bucket = S3BucketName;
    getPreSignedURLRequest.key = key;
    getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodDELETE;
    getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
    
    [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:getPreSignedURLRequest] continueWithBlock:^id(BFTask *task) {
      if (task.error) {
        NSLog(@"%@ task error: %@", self.class, task.error);
      } else {
        NSURL *presignedURL = task.result;
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        [request setHTTPMethod:@"DELETE"];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [connection start];
        });
      }
      return nil;
    }];
  
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  NSString *urlString = [NSString stringWithFormat:@"%@://%@%@",
                         connection.currentRequest.URL.scheme,
                         connection.currentRequest.URL.host,
                         connection.currentRequest.URL.path
                         ];
  DDLogInfo(@"S3 delete completed with response %@ for: %@",
            @(httpResponse.statusCode),
            urlString);
  
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  DDLogError(@"S3 delete failed: %@", error);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
  if (!error) {
    NSString *urlString = [NSString stringWithFormat:@"%@://%@%@",
                           task.currentRequest.URL.scheme,
                           task.currentRequest.URL.host,
                           task.currentRequest.URL.path
                           ];
    
    DDLogInfo(@"S3 upload completed %@", urlString);
    NSDictionary *userInfo;
    if (task.taskDescription) userInfo = @{DFImageUploadedNotificationImageKey : task.taskDescription};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DFImageUploadedNotification
     object:self
     userInfo:userInfo];
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


@end
