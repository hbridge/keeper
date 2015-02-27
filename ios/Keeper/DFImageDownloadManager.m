//
//  DFImageDownloadManager.m
//  Strand
//
//  Created by Derek Parham on 10/22/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "DFImageDownloadManager.h"
#import "DFKeeperStore.h"
#import "DFImageDiskCache.h"
#import "DFDeferredCompletionScheduler.h"
#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/S3.h>
#import "DFNetworkingConstants.h"
#import "AppDelegate.h"

const NSUInteger maxConcurrentImageDownloads = 2;
const NSUInteger maxDownloadRetries = 3;

@interface DFImageDownloadManager()

@property (nonatomic, retain) DFDeferredCompletionScheduler *downloadScheduler;
@property (nonatomic, retain) Firebase *imageDataRef;

@property (nonatomic) NSURLSession *session;

@end

@implementation DFImageDownloadManager

static DFImageDownloadManager *defaultManager;

+ (DFImageDownloadManager *)sharedManager {
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
    [self observeNotifications];
    self.downloadScheduler = [[DFDeferredCompletionScheduler alloc]
                              initWithMaxOperations:maxConcurrentImageDownloads
                              executionPriority:DISPATCH_QUEUE_PRIORITY_DEFAULT];
    self.imageDataRef = [[[Firebase alloc] initWithUrl:DFFirebaseRootURLString]
                         childByAppendingPath:@"imageData"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
  }
  return self;
}


- (void)observeNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(fetchNewImages)
                                               name:DFPhotosChangedNotification
                                             object:nil];
}

- (void)fetchNewImages
{
  NSArray *remotePhotos = [[DFKeeperStore sharedStore] photos];
  
  DFImageType imageTypes[1] = {DFImageFull};
  for (int i = 0; i < 1; i++) {
    //figure out which have already been download for the type
    DFImageType imageType = imageTypes[i];
    NSSet *fulfilledForType = [[DFImageDiskCache sharedStore] cachedImageKeysForType:imageType];
    for (DFKeeperPhoto *photo in remotePhotos) {
      if (![fulfilledForType containsObject:photo.key]
          && [photo.imageKey isNotEmpty]) {
        // if there's an image path for and it hasn't been fulfilled, queue it for download
        [self
         fetchImageForKey:photo.imageKey
         priority:NSOperationQueuePriorityLow // cache requests are low pri
         completionBlock:^(UIImage *image, NSError *error) {
           if (![[DFImageDiskCache sharedStore] isImageTypeCached:imageType
                                                           forKey:photo.imageKey]) {
             [[DFImageDiskCache sharedStore]
              setImage:image
              type:imageType
              forKey:photo.key
              completion:nil];
           }
         }];
      }
    }
  }
}

- (void)fetchImageForKey:(NSString *)key
              completion:(DFImageFetchCompletionBlock)completion
{
  [self fetchImageForKey:key
                   priority:NSOperationQueuePriorityHigh // interactive downloads are high priority
            completionBlock:completion];
}

- (void)fetchImageForKey:(NSString *)key
                priority:(NSOperationQueuePriority)queuePriority
         completionBlock:(DFImageFetchCompletionBlock)completion
{
  // add the operation to our local download queue so we don't swamp the network with download
  // requests and prevent others from getting scheduled
  [self.downloadScheduler
   enqueueRequestForObject:key
   withPriority:queuePriority
   executeBlockOnce:^id{
     @autoreleasepool {
       NSMutableDictionary *result = [NSMutableDictionary new];
       dispatch_semaphore_t downloadSem = dispatch_semaphore_create(0);
       AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
       getPreSignedURLRequest.bucket = S3BucketName;
       getPreSignedURLRequest.key = key;
       getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodGET;
       getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
       
       [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:getPreSignedURLRequest] continueWithBlock:^id(BFTask *task) {
         if (task.error) {
           DDLogError(@"Error: %@",task.error);
         } else {
           NSURL *presignedURL = task.result;
           DDLogVerbose(@"download presignedURL is: \n%@", presignedURL);
           
           NSURLRequest *request = [NSURLRequest requestWithURL:presignedURL];
           NSURLSessionDownloadTask *downloadTask =
           [self.session
            downloadTaskWithRequest:request
            completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
              if (error) {
                DDLogError(@"download error: %@", error);
                result[@"error"] = error;
              } else {
                NSData *imageData = [NSData dataWithContentsOfURL:location];
                UIImage *image = [UIImage imageWithData:imageData];
                if (image)
                  result[@"image"] = image;
                else {
                  DDLogError(@"%@ server returned invalid image",
                             [DFImageDownloadManager class]);
                  result[@"error"] = [NSError errorWithDomain:@"com.duffyapp.keeper"
                                                         code:-1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Server returned invalid image data"}];
                }
              }
              dispatch_semaphore_signal(downloadSem);
            }];
           [downloadTask resume];
         }
         return nil;
       }];
       
       dispatch_semaphore_wait(downloadSem, DISPATCH_TIME_FOREVER);
       
       return result;
     }
   } completionHandler:^(NSDictionary *resultDict) {
     completion(resultDict[@"image"], resultDict[@"error"]);
   }];
}


@end
