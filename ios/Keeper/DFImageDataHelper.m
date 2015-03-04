//
//  DFImageDataHelper.m
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFImageDataHelper.h"
#import <ImageIO/ImageIO.h>

@implementation DFImageDataHelper

+ (NSDictionary *)metadataForImageData:(NSData *)data
{
  CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data,
                                                          NULL);
  NSDictionary *properties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(sourceRef,0, NULL));
  return properties;
}

@end
