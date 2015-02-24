//
//  DFKeeperPhotoViewController.h
//  Keeper
//
//  Created by Henry Bridge on 2/23/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFKeeperPhoto.h"

@interface DFKeeperPhotoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *tagButton;

@property (nonatomic, retain) DFKeeperPhoto *photo;

@property (weak, nonatomic) IBOutlet UIButton *categoryButtonPressed;

@end
