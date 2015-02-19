//
//  DFKeeperPhoto.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperPhoto.h"
#import "NSDateFormatter+DFPhotoDateFormatters.h"

@implementation DFKeeperPhoto

- (NSDictionary *)dictionary
{
  NSMutableDictionary *dict = [[self dictionaryWithValuesForKeys:[DFKeeperPhoto directMappingKeys]
                                ] mutableCopy];
  // date
  NSDateFormatter *dateFormatter = [NSDateFormatter DjangoDateFormatter];
  dict[@"saveDate"] = [dateFormatter stringFromDate:self.saveDate];
  
  // store image data
  NSData *imageData = UIImageJPEGRepresentation(self.image, 0.7);
  NSString *stringEncodedImageData =
  [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  if (stringEncodedImageData)
    dict[@"image"] = stringEncodedImageData;
  return dict;
}

+ (NSArray *)directMappingKeys
{
  return @[
           @"user",
           @"text",
           @"metadata"
           ];
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
  
  //image
  NSString *imageDataString = snapshot.value[@"image"];
  if (imageDataString) {
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:imageDataString
                                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
    self.image = [UIImage imageWithData:imageData];
  }
  
  return self;
}

@end
