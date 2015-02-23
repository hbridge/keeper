//
//  DFKeeperImage.m
//  Keeper
//
//  Created by Henry Bridge on 2/23/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperImage.h"

@implementation DFKeeperImage

- (NSDictionary *)dictionary
{
  NSMutableDictionary *dict = [[self dictionaryWithValuesForKeys:[DFKeeperImage directMappingKeys]
                                ] mutableCopy];
  
  // store image data
  NSString *stringEncodedImageData =
  [self.data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  if (stringEncodedImageData)
    dict[@"data"] = stringEncodedImageData;
  return dict;
}

+ (NSArray *)directMappingKeys
{
  return @[
           @"user",
           ];
}

- (instancetype)initWithSnapshot:(FDataSnapshot *)snapshot
{
  self = [super init];
  if (!self) return nil;
  
  //key
  self.key = snapshot.key;
  
  // simple mappings
  for (NSString *key in [DFKeeperImage directMappingKeys]) {
    [self setValue:snapshot.value[key] forKey:key];
  }
  
  //Calculated conversions
  //image
  NSString *imageDataString = snapshot.value[@"data"];
  if (imageDataString) {
    self.data = [[NSData alloc] initWithBase64EncodedString:imageDataString
                                                    options:NSDataBase64DecodingIgnoreUnknownCharacters];
  }
  
  return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
  self = [super init];
  if (self)
  {
    _data = UIImageJPEGRepresentation(image, 0.7);
  }
  return self;
}

- (UIImage *)UIImage
{
  return [UIImage imageWithData:self.data];
}

@end
