//
//  DFCameraRollScanManager.h
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>


@interface DFCameraRollScanManager : NSObject

+ (DFCameraRollScanManager *)sharedManager;


typedef enum {
  DFCameraRollScanModeNormal = 0,
  DFCameraRollScanModeIgnoreNewScreenshots = 1, // don't look for new screenshots
} DFCameraRollScanMode;

- (void)scan;
- (void)scanWithMode:(DFCameraRollScanMode)mode promptForAccess:(BOOL)shouldPrompt;
- (void)reset;

@end
