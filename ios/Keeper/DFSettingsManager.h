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

extern NSString *const DFSettingValueYes;
extern NSString *const DFSettingValueNo;


+ (void)setObject:(id)object forSetting:(DFSettingType)setting;
+ (id)objectForSetting:(DFSettingType)setting;

+ (BOOL)boolForSetting:(DFSettingType)setting;
+ (void)setBool:(BOOL)boolVal forSetting:(DFSettingType)setting;

@end
