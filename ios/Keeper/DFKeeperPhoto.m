//
//  DFKeeperPhoto.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperPhoto.h"
#import "NSDateFormatter+DFPhotoDateFormatters.h"
#import "DFImageManager.h"

@implementation DFKeeperPhoto

- (NSDictionary *)dictionary
{
  NSMutableDictionary *dict = [[self dictionaryWithValuesForKeys:[DFKeeperPhoto directMappingKeys]
                                ] mutableCopy];
  // date
  NSDateFormatter *dateFormatter = [NSDateFormatter DjangoDateFormatter];
  dict[@"saveDate"] = [dateFormatter stringFromDate:self.saveDate];
  
  return dict;
}

+ (NSArray *)directMappingKeys
{
  return @[
           @"user",
           @"category",
           @"text",
           @"imageKey",
           ];
}

- (NSString *)imageKey
{
  if (_imageKey) return _imageKey;
  return self.key;
}

- (instancetype)initWithSnapshot:(FDataSnapshot *)snapshot
{
  self = [super init];
  if (!self) return nil;
  
  //key
  self.key = snapshot.key;
  
  // simple mappings
  for (NSString *key in [DFKeeperPhoto directMappingKeys]) {
    [self setValue:snapshot.value[key] forKey:key];
  }
  
  //Calculated conversions
  
  //Date
  self.saveDate = [[NSDateFormatter DjangoDateFormatter] dateFromString:snapshot.value[@"saveDate"]];
  
  return self;
}

- (BOOL)isEqual:(id)object
{
  return [self.key isEqual:((DFKeeperPhoto *)object).key];
}

- (NSUInteger)hash
{
  return self.key.hash;
}

@end
