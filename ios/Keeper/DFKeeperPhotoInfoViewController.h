//
//  DFKeeperPhotoInfoViewController.h
//  Keeper
//
//  Created by Henry Bridge on 3/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFKeeperPhoto.h"

@interface DFKeeperPhotoInfoViewController : UIViewController


@property (nonatomic, retain) DFKeeperPhoto *keeperPhoto;
@property (weak, nonatomic) IBOutlet UILabel *saveDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UITextView *indexedTextField;

- (instancetype)initWithPhoto:(DFKeeperPhoto *)photo;


@end
