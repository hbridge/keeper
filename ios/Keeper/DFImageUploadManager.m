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
    [self createCacheDirectories];
    _uploadsInProgress = [[NSMutableSet alloc] init];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration
                                                backgroundSessionConfigurationWithIdentifier:BackgroundSessionUploadIdentifier];
    configuration.HTTPMaximumConnectionsPerHost = 1; // only upload one file at a time
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
  }
  return self;
}

- (void)createCacheDirectories
{
  NSFileManager *fm = [NSFileManager defaultManager];
  
  NSArray *directoriesToCreate = @[[[self.class uploadsFolderURL] path]];
  
  for (NSString *path in directoriesToCreate) {
    if (![fm fileExistsAtPath:path]) {
      NSError *error;
      [fm createDirectoryAtPath:path withIntermediateDirectories:NO
                     attributes:nil
                          error:&error];
      if (error) {
        DDLogError(@"Error creating cache directory: %@, error: %@", path, error.description);
        abort();
      }
    }
    
  }
}

- (void)resumeUploads
{
  NSError *error;
  NSArray *filesToUpload = [[NSFileManager defaultManager]
                            contentsOfDirectoryAtURL:[self.class uploadsFolderURL]
                            includingPropertiesForKeys:nil
                            options:0
                            error:&error];
  if (!error) {
    DDLogInfo(@"%@ resuming %@ uploads.", self.class, @(filesToUpload.count));
  } else {
    DDLogError(@"%@ error enumerating uploads directory: %@", self.class, error);
  }
  
  for (NSURL *fileURL in filesToUpload) {
    [self uploadImageFile:fileURL];
  }
}

- (void)uploadImageFile:(NSURL *)imageFile
            contentType:(NSString *)contentType
                 forKey:(NSString *)key
{
  NSURL *copyDestUrl = [self.class fileURLForKey:key contentType:contentType];
  NSError *error;
  [[NSFileManager defaultManager] copyItemAtURL:imageFile toURL:copyDestUrl error:&error];
  if (error) DDLogError(@"%@ couldn't copy file for upload: %@", self.class, error);
  [self uploadImageFile:copyDestUrl];
}

- (void)uploadImageData:(NSData *)imageData contentType:(NSString *)contentType forKey:(NSString *)key
{
  NSURL *fileURL = [self.class fileURLForKey:key contentType:contentType];
  [imageData writeToURL:fileURL atomically:YES];
  [self uploadImageFile:fileURL];
}

+ (NSURL *)fileURLForKey:(NSString *)key contentType:(NSString *)contentType
{
  // write the image data to a locally controlled uploads folder
  NSString *extension = [[contentType componentsSeparatedByString:@"/"] objectAtIndex:1];
  NSURL *fileURL = [[[self.class uploadsFolderURL]
                     URLByAppendingPathComponent:key]
                    URLByAppendingPathExtension:extension];
  return fileURL;
}

- (void)uploadImageFile:(NSURL *)imageFile
{
  NSString *key = [[imageFile lastPathComponent] stringByDeletingPathExtension];
  if ([self isUploadInProgress:key]) return;
  if (![[NSFileManager defaultManager] fileExistsAtPath:[imageFile path]]) {
    DDLogError(@"%@ asked to upload non-existent file: %@", self.class, imageFile);
    return;
  }
  DDLogInfo(@"%@ queing for upload %@", self.class, key);
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
    getPreSignedURLRequest.bucket = S3BucketName;
    getPreSignedURLRequest.key = key;
    getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodPUT;
    getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
    
    //Important: must set contentType for PUT request
    NSString *fileContentTypeStr = [@"image/" stringByAppendingString:imageFile.pathExtension];
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
        
        NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request
                                                                        fromFile:imageFile];
        uploadTask.taskDescription = imageFile.absoluteString;
        [uploadTask resume];
      }
      return nil;
    }];

  });
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
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
  if (!error && httpResponse.statusCode == 200) {
    NSString *urlString = [NSString stringWithFormat:@"%@://%@%@",
                           task.currentRequest.URL.scheme,
                           task.currentRequest.URL.host,
                           task.currentRequest.URL.path
                           ];
    
    DDLogInfo(@"S3 upload completed %@ with response:%@", urlString, @(httpResponse.statusCode));
    
    NSURL *fileURL = [NSURL URLWithString:task.taskDescription];
    NSString *key = [[fileURL lastPathComponent] stringByDeletingPathExtension];
    
    NSDictionary *userInfo;
    if (task.taskDescription) userInfo = @{DFImageUploadedNotificationImageKey : key};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DFImageUploadedNotification
     object:self
     userInfo:userInfo];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
    if (error) DDLogError(@"error removing upload file: %@", error);
  } else {
    DDLogError(@"S3 upload error: %@, response: %@", error, task.response);
  }
  [self setKey:task.taskDescription inProgress:NO];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
  DDLogError(@"%@ urlSession didBecomeInvalidWithError:%@", self.class, error);
}

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
  DDLogVerbose(@"%@ urlSession didReceiveChallenge:%@ credential:%@", self.class, challenge, challenge.proposedCredential);
  completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
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

+ (NSURL *)uploadsFolderURL
{
  NSArray* paths = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
  
  if ([paths count] > 0)
  {
    NSURL *documentsDir = [paths objectAtIndex:0];
    return [documentsDir URLByAppendingPathComponent:@"uploads" isDirectory:YES];
  }
  return nil;
}


@end
