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


@interface DFKeeperPhotoViewController : UIViewController <DFCategorizeControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *tagButton;

@property (nonatomic, retain) DFKeeperPhoto *photo;

- (IBAction)categoryButtonPressed:(id)sender;
- (IBAction)deleteButtonPressed:(id)sender;
- (IBAction)rotateButtonPressed:(id)sender;

@end
