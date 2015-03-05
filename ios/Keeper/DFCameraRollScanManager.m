//
//  DFCameraRollScanManager.m
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFCameraRollScanManager.h"
#import "DFCameraRollScanDB.h"

@interface DFCameraRollScanManager()

@property (nonatomic, retain) PHPhotoLibrary *photoLibrary;
@property (nonatomic) BOOL scanInProgress;

@end

// This should be incremented when the entire camera roll should be rescanned
const int DFCameraRollScanManagerScanVersion = 1;

@implementation DFCameraRollScanManager

+ (DFCameraRollScanManager *)sharedManager {
  static DFCameraRollScanManager *defaultManager = nil;
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
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized)
      self.photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
  }
  return self;
}

- (void)scan
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    @autoreleasepool {
      if (self.scanInProgress) return;
      self.scanInProgress = YES;
      PHFetchResult *allImagesFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
      DDLogInfo(@"%@ all images: %@", self.class, @(allImagesFetchResult.count));
      
      // figure out which ones we've already scanned
      NSSet *scannedAssets = [[DFCameraRollScanDB sharedDB]
                              scannedIdentifiersForVersion:@(DFCameraRollScanManagerScanVersion)];
      NSMutableArray *unscannedAssets = [NSMutableArray new];
      for (PHAsset *asset in allImagesFetchResult) {
        if (![scannedAssets containsObject:asset.localIdentifier]) {
          [unscannedAssets addObject:asset];
        }
      }
      
      // scan for relevant changes
      if (unscannedAssets.count > 0) {
        [self.class findNewScreenshots:unscannedAssets];
      }
      
      // mark assets as scanned
      for (PHAsset *asset in unscannedAssets) {
        [[DFCameraRollScanDB sharedDB] addScannedIdentifier:asset.localIdentifier
                                                scanVersion:@(DFCameraRollScanManagerScanVersion)];
      }
      self.scanInProgress = NO;
    }
  });
}

+ (void)findNewScreenshots:(NSArray *)assetsToScan
{
  DDLogInfo(@"%@ scanning %@ assets for new screenshots", self, @(assetsToScan.count));
  NSSet *knownScreenshotIDs = [[DFCameraRollScanDB sharedDB] localIdentifiersOfScreenshots];
  NSMutableSet *newScreenshots = [NSMutableSet new];
  
  PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
  requestOptions.synchronous = YES;
  for (PHAsset *asset in assetsToScan) {
    @autoreleasepool {
      [[PHImageManager defaultManager]
       requestImageDataForAsset:asset
       options:requestOptions
       resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
         if ([dataUTI isEqual:@"public.png"]) {
           [newScreenshots addObject:asset.localIdentifier];
         }
       }];
    }
  }
  
  [newScreenshots minusSet:knownScreenshotIDs];
  DDLogInfo(@"%@ %@ new screenshots detected", self.class, @(newScreenshots.count));
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DFNewScreenshotNotification
     object:self
     userInfo:@{DFNewScreenshotNotificationIdentifiersSetKey : newScreenshots}];
  });
}



@end
