//
//  DFKeeperImage.m
//  Keeper
//
//  Created by Henry Bridge on 3/2/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperImage.h"

@implementation DFKeeperImage


+ (NSArray *)directMappingKeys
{
  return @[
           @"user",
           @"metadata",
           @"uploaded",
           ];
}

- (NSNumber *)orientation
{
  return self.metadata[@"Orientation"];
}

- (void)setOrientation:(NSNumber *)orientation
{
  NSMutableDictionary *mutableMetadata = [self.metadata mutableCopy];
  mutableMetadata[@"Orientation"] = orientation;
  self.metadata = mutableMetadata;
}


@end
