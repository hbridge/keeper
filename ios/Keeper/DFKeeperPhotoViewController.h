//
//  DFKeeperPhotoViewController.h
//  Keeper
//
//  Created by Henry Bridge on 2/23/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFKeeperPhoto.h"
#import "DFCategorizeController.h"
#import "DFImageZoomScrollView.h"


@interface DFKeeperPhotoViewController : UIViewController <DFCategorizeControllerDelegate>
@property (weak, nonatomic) IBOutlet DFImageZoomScrollView *imageZoomScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *tagButton;
@property (weak, nonatomic) IBOutlet UIView *bottomBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBarBottomConstraint;
@property (nonatomic) BOOL chromeHidden;

@property (nonatomic, retain) DFKeeperPhoto *photo;

- (IBAction)categoryButtonPressed:(id)sender;
- (IBAction)deleteButtonPressed:(id)sender;
- (IBAction)rotateButtonPressed:(id)sender;
- (IBAction)imageViewTapped:(id)sender;

@end
