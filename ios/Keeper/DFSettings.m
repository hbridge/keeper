//
//  DFSettings.m
//  Keeper
//
//  Created by Henry Bridge on 3/11/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFSettings.h"
#import "DFSettingsManager.h"
#import "DFAppInfo.h"
#import "DFUserLoginManager.h"

@implementation DFSettings

- (NSArray *)fields
{
  return @[
           @{
             FXFormFieldHeader : @"Preferences",
             FXFormFieldTitle : @"Autosave to Camera Roll",
             FXFormFieldKey : @"autosaveToCameraRoll",
             },
           @{
             FXFormFieldTitle : @"Auto Import Screenshots",
             FXFormFieldKey : @"autoimportScreenshots",
             },
           @{
             FXFormFieldTitle : @"Set Category Speed Dial",
             FXFormFieldAction : @"configureCategories:",
             @"textLabel.color" : [DFKeeperConstants ButtonTintColor],
             },
           @{
             FXFormFieldHeader : @"Support",
             FXFormFieldTitle : @"Version",
             FXFormFieldKey : @"version",
             FXFormFieldType : FXFormFieldTypeLabel
             },
           @{
             FXFormFieldTitle : @"Send Diagnostic Info",
             FXFormFieldAction : @"sendLogs:",
             @"textLabel.color" : [DFKeeperConstants ButtonTintColor],
             },

           @{
             FXFormFieldHeader : @"Account",
             FXFormFieldTitle : @"Email",
             FXFormFieldKey : @"email",
             FXFormFieldType : FXFormFieldTypeLabel
             },
           @{
             FXFormFieldTitle : @"Sign Out",
             FXFormFieldAction : @"signOut:",
             @"textLabel.color" : [UIColor redColor],
             },
           ];
}

- (NSString *)version
{
  return [DFAppInfo appInfoString];
}

- (void)setAutosaveToCameraRoll:(BOOL)autosaveToCameraRoll
{
  [DFSettingsManager setObject:autosaveToCameraRoll ? DFSettingValueYes : DFSettingValueNo
                    forSetting:DFSettingAutoSaveToCameraRoll];
}

- (BOOL)autosaveToCameraRoll
{
  return [[DFSettingsManager objectForSetting:DFSettingAutoSaveToCameraRoll] isEqual:DFSettingValueYes];
}

- (void)setAutoimportScreenshots:(BOOL)autoimportScreenshots
{
  [DFSettingsManager setObject:autoimportScreenshots ? DFSettingValueYes : DFSettingValueNo
                    forSetting:DFSettingAutoImportScreenshots];
}

- (BOOL)autoimportScreenshots
{
  return [[DFSettingsManager objectForSetting:DFSettingAutoImportScreenshots] isEqual:DFSettingValueYes];
}

- (NSString *)email
{
  return [[DFUserLoginManager sharedManager] loggedInEmailAddress];
}



@end
