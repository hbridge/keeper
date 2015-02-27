//
//  DFKeeperConstants.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFKeeperConstants : NSObject

extern NSString *const DFPhotosChangedNotification;
extern NSString *const DFImageUploadedNotification;
extern NSString *const DFImageUploadedNotificationImageKey;
extern NSString *const DFFirebaseRootURLString;

extern const CGFloat DFKeeperPhotoDefaultThumbnailSize;
extern const CGFloat DFKeeperPhotoHighQualityMaxLength;

+ (UIColor *)BarBackgroundColor;
+ (UIColor *)BarForegroundColor;
+ (UIStatusBarStyle)DefaultStatusBarStyle;

@end
