//
//  DFKeeperStore.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import "DFKeeperPhoto.h"

@interface DFKeeperStore : NSObject

+ (DFKeeperStore *)sharedStore;

- (void)storePhoto:(DFKeeperPhoto *)photo;
- (NSArray *)photos;

@end
