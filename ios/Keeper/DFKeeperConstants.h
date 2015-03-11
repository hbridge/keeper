//
//  DFKeeperConstants.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWSCore.h"

@interface DFKeeperConstants : NSObject

#pragma mark - Networking

extern NSString *const DFFirebaseRootURLString;
extern AWSRegionType const CognitoRegionType;
extern AWSRegionType const DefaultServiceRegionType;
extern NSString *const CognitoIdentityPoolId;
extern NSString *const S3BucketName;
extern NSString *const BackgroundSessionUploadIdentifier;
extern NSString *const BackgroundSessionDownloadIdentifier;

#pragma mark - Notifications

extern NSString *const DFPhotosChangedNotification;
extern NSString *const DFImageUploadedNotification;
extern NSString *const DFImageUploadedNotificationImageKey;
extern NSString *const DFNewScreenshotNotification;
extern NSString *const DFNewScreenshotNotificationIdentifiersSetKey;


extern const CGFloat DFKeeperPhotoDefaultThumbnailSize;
extern const CGFloat DFKeeperPhotoHighQualityMaxLength;

+ (UIColor *)ButtonTintColor;
+ (UIColor *)BarBackgroundColor;
+ (UIColor *)BarForegroundColor;
+ (UIStatusBarStyle)DefaultStatusBarStyle;

@end
