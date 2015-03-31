//
//  DFImageZoomScrollView.m
//  Keeper
//
//  Created by Henry Bridge on 3/31/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFImageZoomScrollView.h"

@implementation DFImageZoomScrollView

- (instancetype)init
{
  self = [super init];
  if (self) {
    [self configure];
    
  }
  return self;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  [self configure];
}

- (void)configure
{
  self.delegate = self;
  self.maximumZoomScale = 2.5;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return self.imageView;
}

- (void)setImageView:(UIImageView *)imageView
{
  _imageView = imageView;
  imageView.frame = self.bounds;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  if (self.zoomScale == 1.0) {
    self.imageView.frame = self.bounds;
    DDLogVerbose(@"imageview frame: %@", NSStringFromCGRect(self.bounds));
    return;
  }
  
  /* 
   code from
   http://www.mokten.com/2012/11/center-uiimageview-in-uiscrollview-when-orientation-changes/ 
   */
  
  CGSize boundsSize = self.bounds.size;
  
  UIImage * img = self.imageView.image;
  CGRect  frameToCenter =  CGRectZero;
  
  if (img) {
    // Change orientation: Portrait -> Lanscape : this lets you see the whole image
    if (UIDeviceOrientationIsLandscape( [UIDevice currentDevice].orientation)) {
      frameToCenter = CGRectMake(0, 0, (self.frame.size.height*img.size.width)/img.size.height  * self.zoomScale, self.frame.size.height * self.zoomScale);
    } else {
      frameToCenter = CGRectMake(0, 0, self.frame.size.width * self.zoomScale, (self.frame.size.width*img.size.height)/img.size.width  * self.zoomScale);
    }
  } else {
    frameToCenter =  self.imageView.frame;
  }
  
  // center horizontally
  if (frameToCenter.size.width < boundsSize.width)
    frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
  else
    frameToCenter.origin.x = 0;
  
  // center vertically
  if (frameToCenter.size.height < boundsSize.height)
    frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
  else
    frameToCenter.origin.y = 0;
  
  self.imageView.frame = frameToCenter;
  self.contentSize = self.imageView.frame.size;
}

@end
