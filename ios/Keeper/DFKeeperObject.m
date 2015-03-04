//
//  DFKeeperObject.m
//  Keeper
//
//  Created by Henry Bridge on 3/2/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperObject.h"
#import "DFKeeperStore.h"

@implementation DFKeeperObject

+ (NSString *)objectsPath
{
  return @"";
}

- (NSDictionary *)dictionary
{
  return [self dictionaryWithValuesForKeys:[self.class directMappingKeys]];
}

+ (NSArray *)directMappingKeys
{
  return @[];
}

- (instancetype)initWithSnapshot:(FDataSnapshot *)snapshot
{
  self = [super init];
  if (!self) return nil;
  
  if (![snapshot isKindOfClass:[FDataSnapshot class]]) return self;
  
  //key
  self.key = snapshot.key;
  
  // simple mappings
  for (NSString *key in [self.class directMappingKeys]) {
    [self setValue:snapshot.value[key] forKey:key];
  }
  
  return self;
}

- (Firebase *)firebaseRef
{
  Firebase *objectsRef = [[[DFKeeperStore sharedStore] baseRef] childByAppendingPath:[self.class objectsPath]];
  return [objectsRef childByAppendingPath:self.key];
}




@end
