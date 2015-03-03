//
//  DFKeeperImage.h
//  Keeper
//
//  Created by Henry Bridge on 3/2/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperObject.h"

@interface DFKeeperImage : DFKeeperObject

@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSDictionary *metadata;
@property (nonatomic, retain) NSNumber *uploaded;

// calculated properties
@property (nonatomic, retain) NSNumber *orientation;

@end
