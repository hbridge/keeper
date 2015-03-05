//
//  DFKeeperConstants.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperConstants.h"
#import <UIColor+BFPaperColors/UIColor+BFPaperColors.h>

#pragma mark - Networking

#ifdef DEBUG
NSString *const DFFirebaseRootURLString = @"https://keeper-dev.firebaseio.com";
#else
NSString *const DFFirebaseRootURLString = @"https://blazing-heat-8620.firebaseio.com";
#endif

AWSRegionType const CognitoRegionType = AWSRegionUSEast1;
AWSRegionType const DefaultServiceRegionType = AWSRegionUSEast1;
NSString *const CognitoIdentityPoolId = @"us-east-1:d398535c-7f96-4480-ba71-7d8d4ec07c8a";

#ifdef DEBUG
NSString *const S3BucketName = @"duffy-keeper-dev";
#else
NSString *const S3BucketName = @"duffy-keeper";
#endif

NSString *const BackgroundSessionUploadIdentifier = @"com.duffyapp.keeper.s3BackgroundTransferObjC.uploadSession";
NSString *const BackgroundSessionDownloadIdentifier = @"com.duffyapp.keeper.s3BackgroundTransferObjC.downloadSession";

#pragma mark - Notifications

NSString *const DFPhotosChangedNotification = @"com.duffyapp.DFPhotosChangedNotification";
NSString *const DFImageUploadedNotification = @"com.duffyapp.DFImageUploadedNotification";
NSString *const DFImageUploadedNotificationImageKey = @"imageKey";
NSString *const DFNewScreenshotNotification = @"com.duffyapp.DFNewScreenshotNotification";
NSString *const DFNewScreenshotNotificationIdentifiersSetKey = @"assetIdentifiers";


const CGFloat DFKeeperPhotoDefaultThumbnailSize = 157.0;
const CGFloat DFKeeperPhotoHighQualityMaxLength = 1920.0;

@implementation DFKeeperConstants

+ (UIColor *)BarBackgroundColor
{
  return [UIColor paperColorBlue700];
}

+ (UIColor *)BarForegroundColor
{
  return [UIColor whiteColor];
}

+ (UIStatusBarStyle)DefaultStatusBarStyle
{
  return UIStatusBarStyleLightContent;
}

@end
