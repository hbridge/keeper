//
//  DFCameraRollScanManager.m
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFCameraRollScanManager.h"
#import "DFCameraRollScanDB.h"
#import "DFImageImportManager.h"
#import "DFSettingsManager.h"

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
  [self scanWithMode:DFCameraRollScanModeNormal promptForAccess:NO];
}


- (void)scanWithMode:(DFCameraRollScanMode)mode promptForAccess:(BOOL)shouldPrompt
{
  if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
    if (shouldPrompt)
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
          [self scanWithMode:mode promptForAccess:NO];
        }
      }];
    return;
  }
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
      
      // scan for screenshots
      if (unscannedAssets.count > 0
          && mode != DFCameraRollScanModeIgnoreNewScreenshots
          && [[DFSettingsManager objectForSetting:DFSettingAutoImportScreenshots]
              isEqual:DFSettingValueYes]) {
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
  NSDate *minDate = [DFSettingsManager objectForSetting:DFSettingAutoImportScreenshotsMinDate];
  DDLogInfo(@"%@ scanning %@ assets for new screenshots after %@", self, @(assetsToScan.count), minDate);
  NSSet *knownScreenshotIDs = [[DFCameraRollScanDB sharedDB] localIdentifiersOfScreenshots];
  NSMutableSet *newScreenshots = [NSMutableSet new];
  
  PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
  requestOptions.synchronous = YES;
  for (PHAsset *asset in assetsToScan) {
    if (![self.class sizeIsScreenshotSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight)]) continue;
    if ([asset.creationDate compare:minDate] != NSOrderedDescending) continue;
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
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableDictionary *assetsToCategories = [NSMutableDictionary new];
    for (NSString *assetIdentifier in newScreenshots) {
      assetsToCategories[assetIdentifier] = @"Screenshot";
    }
    [[DFImageImportManager sharedManager] importAssetsWithIdentifiersToCategories:assetsToCategories];
  });
}

+ (BOOL)sizeIsScreenshotSize:(CGSize)size
{
  CGSize sizes[2] = {size, CGSizeMake(size.height, size.width)};
  for (int i = 0; i < 2; i++) {
    CGSize s = sizes[i];
    if (
        (s.width == 640 && s.height == 960) // iPhone 4
        || (s.width == 640 && s.height == 1136) // iPhone 5
        || (s.width == 750 && s.height == 1334) // iPhone 6
        || (s.width == 2208 && s.height == 1242) // iPhone 6+
        ) return YES;
  }
  
  return NO;
}

- (void)reset
{
  [[DFCameraRollScanDB sharedDB] reset];
}

@end
