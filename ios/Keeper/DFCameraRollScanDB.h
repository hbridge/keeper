//
//  DFCameraRollScanDB.h
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFCameraRollScanDB : NSObject

+ (DFCameraRollScanDB *)sharedDB;
- (NSMutableSet *)localIdentifiersOfScreenshots;
- (void)addScreenshot:(NSString *)screnshotID withState:(NSNumber *)state;
- (NSMutableSet *)scannedIdentifiersForVersion:(NSNumber *)version;
- (void)addScannedIdentifier:(NSString *)identifier scanVersion:(NSNumber *)version;

@end
