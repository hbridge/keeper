//
//  DFSettingsManager.h
//  Keeper
//
//  Created by Henry Bridge on 2/26/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFSettingsManager : NSObject

typedef NSString *const DFSettingType;
extern DFSettingType DFSettingAutoSaveToCameraRoll;
extern DFSettingType DFSettingAutoImportScreenshots;
extern DFSettingType DFSettingAutoImportScreenshotsMinDate;
extern DFSettingType DFSettingSpeedDialCategories;

extern NSString *const DFSettingValueYes;
extern NSString *const DFSettingValueNo;

+ (void)validateSettings;
+ (void)setObject:(id)object forSetting:(DFSettingType)setting;
+ (id)objectForSetting:(DFSettingType)setting;

+ (void)setAutoImportScreenshotsEnabled:(BOOL)enabled;

+ (BOOL)isSettingEnabled:(DFSettingType)setting;

@end
