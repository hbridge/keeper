//
//  DFSettings.h
//  Keeper
//
//  Created by Henry Bridge on 3/11/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FXForms/FXForms.h>

@interface DFSettings : NSObject<FXForm>

@property (readonly, nonatomic, retain) NSString *version;
@property (readonly, nonatomic, retain) NSString *email;
@property (nonatomic) BOOL autosaveToCameraRoll;
@property (nonatomic) BOOL autoimportScreenshots;

@end
