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
- (void)scan;

@end
