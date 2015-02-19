//
//  DFCameraOverlayView.m
//  Strand
//
//  Created by Henry Bridge on 6/9/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "DFCameraOverlayView.h"

@interface DFCameraOverlayView()

@end

@implementation DFCameraOverlayView

NSString *const FlashOnTitle = @"On";
NSString *const FlashOffTitle = @"Off";
NSString *const FlashAutoTitle = @"Auto";

- (void)awakeFromNib
{
  self.galleryButton.titleLabel.textAlignment = NSTextAlignmentCenter;
  self.takePhotoButton.backgroundColor = [UIColor clearColor];
}

- (void)updateUIForFlashMode:(UIImagePickerControllerCameraFlashMode)flashMode
{
  [self.flashButton setTitle:@"" forState:UIControlStateNormal];
  if (flashMode == UIImagePickerControllerCameraFlashModeOn) {
    //[self.flashButton setTitle:@"On" forState:UIControlStateNormal];
    [self.flashButton setImage:[UIImage imageNamed:@"Assets/Icons/FlashOnButton"]
                      forState:UIControlStateNormal];
  } else if (flashMode == UIImagePickerControllerCameraFlashModeOff) {
    //[self.flashButton setTitle:@"Off" forState:UIControlStateNormal];
    [self.flashButton setImage:[UIImage imageNamed:@"Assets/Icons/FlashOffButton"]
                      forState:UIControlStateNormal];
  } else if (flashMode == UIImagePickerControllerCameraFlashModeAuto) {
    //[self.flashButton setTitle:@"Auto" forState:UIControlStateNormal];
    [self.flashButton setImage:[UIImage imageNamed:@"Assets/Icons/FlashAutoButton"]
                      forState:UIControlStateNormal];
    
  }
}

- (IBAction)viewTapped:(id)sender {

}


@end
