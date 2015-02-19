//
//  DFKeeperConstants.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperConstants.h"
#import <UIColor+BFPaperColors/UIColor+BFPaperColors.h>

NSString *const DFPhotosChangedNotification = @"com.duffyapp.DFPhotosChangedNotification";
NSString *const DFFirebaseRootURLString = @"https://blazing-heat-8620.firebaseio.com";

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
