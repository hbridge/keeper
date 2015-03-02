//
//  DFImageManager.m
//  Strand
//
//  Created by Henry Bridge on 10/28/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "DFImageManager.h"
#import "DFImageDiskCache.h"
#import "DFImageDownloadManager.h"
#import "DFPhotoResizer.h"
#import <Photos/Photos.h>
#import "DFImageUploadManager.h"
#import "DFKeeperStore.h"
#import "DFUser.h"
#import "UIImage+Resize.h"

@interface DFImageManager()

@property (readonly, atomic, retain) NSMutableDictionary *deferredCompletionBlocks;
@property (readonly, atomic, retain) NSMutableDictionary *photoIDsToDeferredRequests;
@property (atomic) dispatch_semaphore_t deferredCompletionSchedulerSemaphore;
@property (readonly, atomic) dispatch_queue_t imageRequestQueue;
@property (readonly, atomic) dispatch_queue_t cacheRequestQueue;
@property (readonly, atomic, retain) NSMutableDictionary *imageRequestCache;
@property (atomic) dispatch_semaphore_t imageRequestCacheSemaphore;

@property (atomic, readonly, retain) NSMutableSet *cacheRequestsInFlight;
@property (atomic) dispatch_semaphore_t cacheRequestsInFlightSemaphore;
@property (nonatomic, retain) PHCachingImageManager *cacheImageManager;

@end

static BOOL logRouting = NO;

@implementation DFImageManager

@synthesize deferredCompletionBlocks = _deferredCompletionBlocks;

+ (DFImageManager *)sharedManager {
  static DFImageManager *defaultManager = nil;
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
    _deferredCompletionBlocks = [NSMutableDictionary new];
    _photoIDsToDeferredRequests = [NSMutableDictionary new];
    _deferredCompletionSchedulerSemaphore = dispatch_semaphore_create(1);
    
    
    dispatch_queue_attr_t imageReqAttrs;
    dispatch_queue_attr_t cache_attrs;
    if (dispatch_queue_attr_make_with_qos_class != NULL) {
      imageReqAttrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,
                                                              QOS_CLASS_DEFAULT,
                                                              0);
      cache_attrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
                                                            QOS_CLASS_BACKGROUND,
                                                            0);
      _imageRequestQueue = dispatch_queue_create("ImageReqQueue", imageReqAttrs);
      _cacheRequestQueue = dispatch_queue_create("ImageCacheReqQueue", cache_attrs);
    } else {
      _imageRequestQueue = dispatch_queue_create("ImageReqQueue", DISPATCH_QUEUE_CONCURRENT);
      dispatch_set_target_queue(_imageRequestQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
      _cacheRequestQueue = dispatch_queue_create("ImageCacheReqQueue", DISPATCH_QUEUE_SERIAL);
      dispatch_set_target_queue(_cacheRequestQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    }
    
    // setup the cache
    _imageRequestCache = [NSMutableDictionary new];
    _imageRequestCacheSemaphore = dispatch_semaphore_create(1);
    
    _cacheRequestsInFlight = [NSMutableSet new];
    _cacheRequestsInFlightSemaphore = dispatch_semaphore_create(1);

    _cacheImageManager = [[PHCachingImageManager alloc] init];
    
    [self observeNotifications];
  }
  return self;
}

- (void)observeNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleLowMemory:)
                                               name:UIApplicationDidReceiveMemoryWarningNotification
                                             object:[UIApplication sharedApplication]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(imageUploaded:)
                                               name:DFImageUploadedNotification
                                             object:nil];
}

- (void)handleLowMemory:(NSNotification *)note
{
  DDLogInfo(@"%@ got low memory warning. Clearing cache", self.class);
  [self clearCache];
}

- (void)imageForKey:(NSString *)key
          pointSize:(CGSize)size
        contentMode:(DFImageRequestContentMode)contentMode
       deliveryMode:(DFImageRequestDeliveryMode)deliveryMode
         completion:(ImageLoadCompletionBlock)completionBlock
{
  CGSize imageSize = CGSizeMake(size.width * [[UIScreen mainScreen] scale],
                                size.height * [[UIScreen mainScreen] scale]);
  [self imageForKey:key
               size:imageSize
        contentMode:contentMode
       deliveryMode:deliveryMode
         completion:completionBlock];
}

- (void)imageForKey:(NSString *)key
               size:(CGSize)size
        contentMode:(DFImageRequestContentMode)contentMode
       deliveryMode:(DFImageRequestDeliveryMode)deliveryMode
         completion:(ImageLoadCompletionBlock)completionBlock
{
  if (CGSizeEqualToSize(size, CGSizeZero)) {
    if (completionBlock) completionBlock(nil);
    return;
  }
  DFImageManagerRequest *request = [[DFImageManagerRequest alloc] initWithKey:key
                                                                         size:size
                                                                  contentMode:contentMode
                                                                 deliveryMode:deliveryMode];
  // first check our cache
  UIImage *cachedImage = [self cachedImageForRequest:request];
  NSString *source;
  if (cachedImage) {
    source = @"memcache";
    if (completionBlock) completionBlock(cachedImage);
  } else if ([[DFImageDiskCache sharedStore] canServeRequest:request]) {
    // opt for the cache first
    source = @"diskcache";
    [self serveRequestWithDiskCache:request completion:completionBlock];
  } else {
    // get the photo remotely
    source = @"remote";
    [self serveRequestFromNetwork:request completion:completionBlock];
  }
  if (logRouting) {
    DDLogVerbose(@"%@ routing %@ to %@: %@", self.class,
                 completionBlock ? @"imageReq" : @"cacheReq",
                 source,
                 request);
  }
}

- (void)originalImageForID:(NSString *)key
                completion:(ImageLoadCompletionBlock)completion
{
  completion([[DFImageDiskCache sharedStore] fullImageForKey:key]);
}

- (void)startCachingImagesForKeys:(NSArray *)keys
                           targetSize:(CGSize)size
                          contentMode:(DFImageRequestContentMode)contentMode
{
  NSMutableArray *keysNotInCache = [NSMutableArray new];
  DFImageManagerRequest *templateRequest = [[DFImageManagerRequest alloc] initWithKey:nil
                                                                                 size:size
                                                                          contentMode:contentMode
                                                                         deliveryMode:DFImageRequestOptionsDeliveryModeHighQualityFormat];
  for (NSString *key in keys) {
    // first see what we can get in mem or disk cache
    DFImageManagerRequest *request = [templateRequest copyWithKey:key];
    
    if ([self checkAndSetCacheRequestInFlight:request]) {
      //DDLogVerbose(@"dupe cache request, ignoring");
      continue; //we're already caching this, continue
    }
    if ([self cachedImageForRequest:request]) {
      // we already have this in the cache or it's in progress, do nothing
      [self removeCacheRequestInFlight:request];
      continue;
    } else if ([[DFImageDiskCache sharedStore] canServeRequest:request]) {
      // if we can cache from the disk store, load the images from there
      dispatch_async(self.cacheRequestQueue, ^{
        UIImage *image = [[DFImageDiskCache sharedStore] serveImageForRequest:request];
        [self cacheImage:image forRequest:request];
      });
    } else {
      [keysNotInCache addObject:key];
    }
  }
  
  [self cacheKeys:keysNotInCache templateRequest:templateRequest];
}

- (BOOL)checkAndSetCacheRequestInFlight:(DFImageManagerRequest *)request
{
  BOOL result = NO;
  dispatch_semaphore_wait(self.cacheRequestsInFlightSemaphore, DISPATCH_TIME_FOREVER);
  if ([self.cacheRequestsInFlight containsObject:request]) result = YES;
  else ([self.cacheRequestsInFlight addObject:request]);
  dispatch_semaphore_signal(self.cacheRequestsInFlightSemaphore);
  return result;
}

- (void)removeCacheRequestInFlight:(DFImageManagerRequest *)request
{
  dispatch_semaphore_wait(self.cacheRequestsInFlightSemaphore, DISPATCH_TIME_FOREVER);
  [self.cacheRequestsInFlight removeObject:request];
  dispatch_semaphore_signal(self.cacheRequestsInFlightSemaphore);
}

- (void)cacheKeys:(NSArray *)keys
  templateRequest:(DFImageManagerRequest *)templateRequest
{
  if (keys.count > 0) {
    dispatch_async(self.cacheRequestQueue, ^{
      for (NSString *key in keys) {
        DFImageManagerRequest *request = [templateRequest copyWithKey:key];
        [self serveRequestFromNetwork:request completion:nil];
      }
      
      if (logRouting) {
        DDLogVerbose(@"%@ cached %@ photos",
                     self.class,
                     @(keys.count));
      }
      
    });
  }
}



#pragma mark - Logic for serving requests

- (void)serveRequestWithDiskCache:(DFImageManagerRequest *)request
                       completion:(ImageLoadCompletionBlock)completionBlock
{
  [self scheduleDeferredCompletion:completionBlock
                        forRequest:request
                     withLoadBlock:^{
                       return [[DFImageDiskCache sharedStore] serveImageForRequest:request];
                     }];
}

- (void)serveRequestFromNetwork:(DFImageManagerRequest *)request
                completion:(ImageLoadCompletionBlock)completionBlock
{
  if (!request.key) {
    DDLogWarn(@"nil image key in request");
    completionBlock(nil);
    return;
  }
  if (request.deliveryMode == DFImageRequestOptionsDeliveryModeOpportunistic
      && request.imageType == DFImageFull) {
    // if this is an opportunistic request for a full image, try to serve a thumb first
    DFImageManagerRequest *thumbRequest = [request
                                           copyWithSize:CGSizeMake(DFKeeperPhotoDefaultThumbnailSize,
                                                                   DFKeeperPhotoDefaultThumbnailSize)];
    if ([[DFImageDiskCache sharedStore] canServeRequest:thumbRequest]) {
      [self serveRequestWithDiskCache:thumbRequest completion:completionBlock];
    } else {
      [self serveRequestFromNetwork:thumbRequest completion:completionBlock];
    }
  }
  
  [self scheduleDeferredCompletion:completionBlock forRequest:request withLoadBlock:^UIImage *{
    UIImage __block *result = nil;
    dispatch_semaphore_t downloadSema = dispatch_semaphore_create(0);
    [[DFImageDownloadManager sharedManager]
     fetchImageForKey:request.key
     completion:^(UIImage *image, NSError *error) {
       result = image;
       if (image)
         [[DFImageDiskCache sharedStore] setImage:image
                                             type:request.imageType
                                           forKey:request.key
                                       completion:nil];
       dispatch_semaphore_signal(downloadSema);
     }];
    
    dispatch_semaphore_wait(downloadSema, DISPATCH_TIME_FOREVER);
    return result;
  }];
}

#pragma mark - Cache Management

- (void)cacheImage:(UIImage *)image forRequest:(DFImageManagerRequest *)request
{
  dispatch_semaphore_wait(self.imageRequestCacheSemaphore, DISPATCH_TIME_FOREVER);
  if (image) {
    // normalize the deliveryType since it doesn't matter for cache
    DFImageManagerRequest *cacheRequest = [request
                                           copyWithDeliveryMode:DFImageRequestOptionsDeliveryModeFastFormat];
    self.imageRequestCache[cacheRequest] = image;
  }
  dispatch_semaphore_signal(self.imageRequestCacheSemaphore);
  [self removeCacheRequestInFlight:request];
}

- (UIImage *)cachedImageForRequest:(DFImageManagerRequest *)request
{
  UIImage *image;
  // normalize the deliveryType since it doesn't matter for cache
  DFImageManagerRequest *cacheRequest = [request
                                         copyWithDeliveryMode:DFImageRequestOptionsDeliveryModeFastFormat];
  dispatch_semaphore_wait(self.imageRequestCacheSemaphore, DISPATCH_TIME_FOREVER);
  image = self.imageRequestCache[cacheRequest];
  dispatch_semaphore_signal(self.imageRequestCacheSemaphore);
  return image;
}

- (void)clearCache
{
  dispatch_semaphore_wait(self.imageRequestCacheSemaphore, DISPATCH_TIME_FOREVER);
  DDLogInfo(@"%@ clearing cache", self.class);
  _imageRequestCache = [NSMutableDictionary new];
  dispatch_semaphore_signal(self.imageRequestCacheSemaphore);
}


#pragma mark - Deferred completion logic

- (void)scheduleDeferredCompletion:(ImageLoadCompletionBlock)completion
                        forRequest:(DFImageManagerRequest *)request
                     withLoadBlock:(UIImage *(^)(void))loadBlock
{
  BOOL callLoadBlock = NO;
  dispatch_semaphore_wait(self.deferredCompletionSchedulerSemaphore, DISPATCH_TIME_FOREVER);
  
  // figure out if there are similar requests ahead in the queue,
  // if there are none, we'll need to call the loadBlock at the end
  NSArray *similarRequests = [self requestsLike:request];
  if (similarRequests.count == 0) callLoadBlock = YES;
  //DDLogVerbose(@"%@ request: %@ has %d similarRequests ahead in queue.", self.class, request, (int)similarRequests.count);
  
  // keep track of this request in photoIDstoDeferredRequests
  NSMutableSet *requestsForID = self.photoIDsToDeferredRequests[request.key];
  if (!requestsForID) requestsForID = [NSMutableSet new];
  [requestsForID addObject:request];
  self.photoIDsToDeferredRequests[request.key] = requestsForID;
  
  // then add the deferred completion handler to our list deferredCompletionBlocks
  NSMutableArray *deferredForRequest = self.deferredCompletionBlocks[request];
  if (!deferredForRequest) {
    deferredForRequest = [[NSMutableArray alloc] init];
    self.deferredCompletionBlocks[request] = deferredForRequest;
  }
  
  if (completion) [deferredForRequest addObject:completion];
  dispatch_semaphore_signal(self.deferredCompletionSchedulerSemaphore);

  if (callLoadBlock) {
    // call the load block, cache the image and execute the deferred completion handlers
    dispatch_queue_t queue = self.imageRequestQueue;
    if (!completion) {
      queue = self.cacheRequestQueue;
    }
    dispatch_async(queue, ^{
      UIImage *image = loadBlock();
    
      if (!image
          && request.imageType == DFImageFull
          && request.deliveryMode == DFImageRequestOptionsDeliveryModeOpportunistic) {
        [self cancelDeferredCompletionsForRequestsLike:request
                                          deliveryMode:DFImageRequestOptionsDeliveryModeOpportunistic];
      }
      
      //DDLogVerbose(@"loadBlock for request:%@ image:%@", request, image);
      [self cacheImage:image forRequest:request];
      [self executeDeferredCompletionsWithImage:image forRequestsLike:request];
    });
  }
}

- (void)executeDeferredCompletionsWithImage:(UIImage *)image forRequestsLike:(DFImageManagerRequest *)request
{
  dispatch_semaphore_wait(self.deferredCompletionSchedulerSemaphore, DISPATCH_TIME_FOREVER);

  NSMutableSet *requestsForID = self.photoIDsToDeferredRequests[request.key];
  NSMutableSet *executedRequests = [NSMutableSet new];
  //DDLogVerbose(@"executeDeferred begin requestsFor:%d photoIDsToDeferredRequests:%@ requestsForID:%@", (int)request.photoID, self.photoIDsToDeferredRequests, requestsForID);
  NSArray *similarRequests = [self requestsLike:request];
  for (DFImageManagerRequest *similarRequest in similarRequests) {
    NSMutableArray *deferredHandlers = self.deferredCompletionBlocks[similarRequest];
    NSMutableArray *executedHandlers = [NSMutableArray new];
    for (ImageLoadCompletionBlock completion in deferredHandlers) {
      //DDLogVerbose(@"executing deferred completion for %@", similarRequest);
      completion(image);
      [executedHandlers addObject:completion];
    }
    [deferredHandlers removeObjectsInArray:executedHandlers];
    [executedRequests addObject:similarRequest];
  }
  [requestsForID minusSet:executedRequests];
  
  //DDLogVerbose(@"executeDeferred end requestsFor:%d photoIDsToDeferredRequests:%@ requestsForID:%@", (int)request.photoID, self.photoIDsToDeferredRequests, requestsForID);
  dispatch_semaphore_signal(self.deferredCompletionSchedulerSemaphore);
}

- (NSArray *)requestsLike:(DFImageManagerRequest *)request
{
  NSMutableSet *requestsForID = self.photoIDsToDeferredRequests[request.key];
  NSMutableArray *result = [NSMutableArray new];
  for (DFImageManagerRequest *otherRequest in requestsForID) {
    if (CGSizeEqualToSize(otherRequest.size, request.size)) {
      [result addObject:otherRequest];
    }
  }
  return result;
}

- (void)cancelDeferredCompletionsForRequestsLike:(DFImageManagerRequest *)request
                                    deliveryMode:(DFImageRequestDeliveryMode)deliveryMode
{
  dispatch_semaphore_wait(self.deferredCompletionSchedulerSemaphore, DISPATCH_TIME_FOREVER);
  
  NSArray *similarRequests = [self requestsLike:request];
  NSMutableSet *requestsForID = self.photoIDsToDeferredRequests[request.key];
  for (DFImageManagerRequest *similarRequest in similarRequests) {
    // make sure the delivery mode of the request matches
    if (similarRequest.deliveryMode != deliveryMode) continue;
    
    NSMutableArray *deferredHandlers = self.deferredCompletionBlocks[similarRequest];
    [deferredHandlers removeAllObjects];
    [requestsForID removeObject:similarRequest];
  }
  
  dispatch_semaphore_signal(self.deferredCompletionSchedulerSemaphore);
}

- (void)setImageChanged:(NSString *)imageKey
{
  [self clearCache];
  [[DFImageDiskCache sharedStore] setImage:nil type:DFImageFull forKey:imageKey completion:nil];
}

- (void)saveImage:(UIImage *)image
         category:(NSString *)category
     withMetadata:(NSDictionary *)metadata
{
  DFKeeperImage *keeperImage = [[DFKeeperImage alloc] init];
  keeperImage.metadata = metadata;
  keeperImage.user = [DFUser loggedInUser];
  [[DFKeeperStore sharedStore] saveImage:keeperImage];
  
  DFKeeperPhoto *photo = [[DFKeeperPhoto alloc] init];
  photo.imageKey = keeperImage.key;
  photo.category = category;
  photo.saveDate = [NSDate date];
  photo.user = [DFUser loggedInUser];
  [[DFKeeperStore sharedStore] savePhoto:photo];
  
  UIImage *imageToUpload = [image
                            resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                            bounds:CGSizeMake(DFKeeperPhotoHighQualityMaxLength, DFKeeperPhotoHighQualityMaxLength)
                            interpolationQuality:kCGInterpolationDefault];
  [self setImage:imageToUpload forKey:photo.imageKey];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key
{
  [[DFImageDiskCache sharedStore] setImage:image type:DFImageFull forKey:key completion:^(NSError *error) {
    [[DFImageUploadManager sharedManager]
     uploadImageFile:[[DFImageDiskCache sharedStore] urlForFullImageWithKey:key] forKey:key];
  }];
}

- (void)performForegroundOperations
{
  DDLogInfo(@"%@ performing foreground ops.", self.class);
  [[DFKeeperStore sharedStore] fetchImagesWithCompletion:^(NSArray *images) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      for (DFKeeperImage *image in images) {
        if (!image.uploaded.boolValue) {
          NSURL *url = [[DFImageDiskCache sharedStore] urlForFullImageWithKey:image.key];
          [[DFImageUploadManager sharedManager] uploadImageFile:url forKey:image.key];
        }
      }
    });
    
    [[DFImageDownloadManager sharedManager] fetchNewImages];
  }];
}

- (void)imageUploaded:(NSNotification *)note
{
  NSString *imageKey = note.userInfo[DFImageUploadedNotificationImageKey];
  [[DFKeeperStore sharedStore] fetchImageWithKey:imageKey completion:^(DFKeeperImage *image) {
    image.uploaded = @(YES);
    [[DFKeeperStore sharedStore] saveImage:image];
  }];
}


@end
