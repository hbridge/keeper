//
//  DFImageManagerRequest.m
//  Strand
//
//  Created by Henry Bridge on 10/28/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "DFImageManagerRequest.h"

@implementation DFImageManagerRequest

- (instancetype)initWithKey:(NSString *)key
                       size:(CGSize)size
                contentMode:(DFImageRequestContentMode)contentMode
               deliveryMode:(DFImageRequestDeliveryMode)deliveryMode
{
  self = [super init];
  if (self) {
    _key = key;
    _size = size;
    _contentMode = contentMode;
    _deliveryMode = deliveryMode;
  }
  return self;
}

- (instancetype)initWithKey:(NSString *)key
                  imageType:(DFImageType)imageType
{
  CGSize size;
  
  if (imageType == DFImageFull) {
    size = CGSizeMake(DFKeeperPhotoHighQualityMaxLength, DFKeeperPhotoHighQualityMaxLength);
  } else if (imageType == DFImageThumbnail) {
    size = CGSizeMake([DFKeeperConstants DefaultThumbnailSize],
                      [DFKeeperConstants DefaultThumbnailSize]);
  }
  return [self
          initWithKey:key
          size:size
          contentMode:DFImageRequestContentModeAspectFill
          deliveryMode:DFImageRequestOptionsDeliveryModeOpportunistic];
}

- (NSUInteger)hash
{
  return (NSUInteger)self.key + self.size.width + self.size.height + self.contentMode + self.deliveryMode;
}

- (BOOL)isEqual:(id)object
{
  DFImageManagerRequest *otherObject = object;
  if (otherObject.key == self.key
      && CGSizeEqualToSize(self.size, otherObject.size)
      && otherObject.contentMode == self.contentMode
      && otherObject.deliveryMode == self.deliveryMode) {
    return YES;
  }
  
  return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
  DFImageManagerRequest *newObject = [[DFImageManagerRequest allocWithZone:zone]
                                      initWithKey:self.key
                                      size:self.size
                                      contentMode:self.contentMode
                                      deliveryMode:self.deliveryMode];
  
  return newObject; 
}

- (DFImageType)imageType
{
  DFImageType imageRequestType;
  if (self.size.width <= [DFKeeperConstants DefaultThumbnailSize]
      && self.size.height <= [DFKeeperConstants DefaultThumbnailSize]) {
    imageRequestType = DFImageThumbnail;
  } else {
    imageRequestType = DFImageFull;
  }
  return imageRequestType;
}

- (BOOL)isDefaultThumbnail
{
  return CGSizeEqualToSize(self.size, CGSizeMake([DFKeeperConstants DefaultThumbnailSize],
                                                 [DFKeeperConstants DefaultThumbnailSize]));
}

- (DFImageManagerRequest *)copyWithKey:(NSString *)key
{
  return [[DFImageManagerRequest alloc] initWithKey:key
                                                   size:self.size
                                            contentMode:self.contentMode
                                           deliveryMode:self.deliveryMode];
}

- (DFImageManagerRequest *)copyWithDeliveryMode:(DFImageRequestDeliveryMode)deliveryMode
{
  return [[DFImageManagerRequest alloc] initWithKey:self.key
                                                   size:self.size
                                            contentMode:self.contentMode 
                                           deliveryMode:deliveryMode];
}

- (DFImageManagerRequest *)copyWithSize:(CGSize)size
{
  return [[DFImageManagerRequest alloc] initWithKey:self.key
                                                   size:size
                                            contentMode:self.contentMode
                                           deliveryMode:self.deliveryMode];
}

- (NSString *)description
{
  return [[self dictionaryWithValuesForKeys:@[@"key", @"size", @"contentMode", @"deliveryMode"]]
          description];
}

@end
