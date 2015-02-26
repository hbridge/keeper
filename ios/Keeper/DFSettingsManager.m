//
//  DFSettingsManager.m
//  Keeper
//
//  Created by Henry Bridge on 2/26/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFSettingsManager.h"

@implementation DFSettingsManager

NSString *const DFSettingValueYes = @"Yes";
NSString *const DFSettingValueNo = @"No";

DFSettingType DFSettingAutoSaveToCameraRoll = @"autoSaveToCameraRoll";

+ (void)setObject:(id)object forSetting:(DFSettingType)setting
{
  [[NSUserDefaults standardUserDefaults] setObject:object forKey:setting];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id)objectForSetting:(DFSettingType)setting
{
  return [[NSUserDefaults standardUserDefaults] valueForKey:setting];
}

+ (BOOL)boolForSetting:(DFSettingType)setting
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:setting];
}

+ (void)setBool:(BOOL)boolVal forSetting:(DFSettingType)setting
{
  [[NSUserDefaults standardUserDefaults] setBool:boolVal forKey:setting];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
