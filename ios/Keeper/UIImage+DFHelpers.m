//
//  UIImage+DFHelpers.m
//  Duffy
//
//  Created by Henry Bridge on 3/27/14.
//  Copyright (c) 2014 Duffy Productions. All rights reserved.
//

#import "UIImage+DFHelpers.h"
#import <ImageIO/ImageIO.h>

@implementation UIImage (DFHelpers)

- (int)CGImageOrientation
{
    int exifOrientation;
    switch (self.imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = 1;
            break;
        case UIImageOrientationDown:
            exifOrientation = 3;
            break;
        case UIImageOrientationLeft:
            exifOrientation = 8;
            break;
        case UIImageOrientationRight:
            exifOrientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = 7;
            break;
        default:
            break;
    }
    
    return exifOrientation;
}

- (UIImageOrientation)orientationRotatedLeft
{
  if (self.imageOrientation == UIImageOrientationDown) return UIImageOrientationRight;
  if (self.imageOrientation == UIImageOrientationRight) return UIImageOrientationUp;
  if (self.imageOrientation == UIImageOrientationUp) return UIImageOrientationLeft;
  if (self.imageOrientation == UIImageOrientationLeft) return UIImageOrientationDown;
  
  DDLogWarn(@"couldn't rotate: %d", (int)self.imageOrientation);
  return UIImageOrientationUp;
}


+ (int)exifImageOrientationLeftFromOrientation:(int)currentOrientation
{
  if (currentOrientation == 1) return 8;
  if (currentOrientation == 8) return 3;
  if (currentOrientation == 3) return 6;
  if (currentOrientation == 6) return 1;
  return 1;
}


@end
