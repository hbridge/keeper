//
//  DFExifHelper.m
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFExifHelper.h"
#import <ImageIO/ImageIO.h>

@implementation DFExifHelper

+ (NSDictionary *)metadataForImageAtURL:(NSURL *)fileUrl
{
  CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)fileUrl,
                                                          NULL);
  CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef,0, NULL);
  NSDictionary *propertiesDict = CFBridgingRelease(properties);
  return propertiesDict;
}

@end
