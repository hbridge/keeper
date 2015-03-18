//
//  DFCreateAccountViewController.h
//  Keeper
//
//  Created by Henry Bridge on 3/5/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFInsetTextField.h"

@interface DFCreateAccountViewController : UIViewController

@property (weak, nonatomic) IBOutlet DFInsetTextField *nameTextField;
@property (weak, nonatomic) IBOutlet DFInsetTextField *emailTextField;
@property (weak, nonatomic) IBOutlet DFInsetTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *improveButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewWidth;

- (IBAction)termsButtonPressed:(id)sender;

@end
