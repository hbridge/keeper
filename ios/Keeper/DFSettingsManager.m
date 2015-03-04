//
//  DFSettingsManager.m
//  Keeper
//
//  Created by Henry Bridge on 2/26/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFSettingsManager.h"
#import "DFAnalytics.h"

@implementation DFSettingsManager

NSString *const DFSettingValueYes = @"Yes";
NSString *const DFSettingValueNo = @"No";

DFSettingType DFSettingAutoSaveToCameraRoll = @"autoSaveToCameraRoll";
DFSettingType DFSettingAutoImportScreenshots = @"autoImportScreenshots";
DFSettingType DFSettingSpeedDialCategories = @"userCategories";

+ (void)setObject:(id)object forSetting:(DFSettingType)setting
{
  NSObject *oldValue = [[NSUserDefaults standardUserDefaults] objectForKey:setting];
  [[NSUserDefaults standardUserDefaults] setObject:object forKey:setting];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // log the change
  NSString *changeToLog = [NSString stringWithFormat:@"%@ -> %@", oldValue, object];
  [DFAnalytics logEvent:DFAnalyticsEventSettingChanged
         withParameters:@{
                          @"setting" : setting,
                          @"valueChange" : changeToLog
                          }];
}

+ (id)objectForSetting:(DFSettingType)setting
{
  return [[NSUserDefaults standardUserDefaults] valueForKey:setting];
}

+ (BOOL)isSettingEnabled:(DFSettingType)setting
{
  return [[self objectForSetting:setting] isEqual:DFSettingValueYes];
}

@end
