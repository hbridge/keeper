//
//  UILoginViewController.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFLoginViewController.h"
#import <Firebase/Firebase.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "DFUserLoginManager.h"

@interface DFLoginViewController ()

@end

@implementation DFLoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setButtonEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.emailTextField becomeFirstResponder];
}

- (IBAction)loginButtonPressed:(id)sender {
  [self login];
}

- (IBAction)editingChanged:(id)sender {
  [self setButtonEnabled:[self isCurrentEntryValid]];
}

- (BOOL)isCurrentEntryValid
{
  return ([self.emailTextField.text isNotEmpty]
          && [self.passwordTextField.text isNotEmpty]);
}

- (void)setButtonEnabled:(BOOL)enabled
{
  self.loginButton.enabled = enabled;
  self.loginButton.alpha = enabled ? 1.0 : 0.5;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if (textField == self.emailTextField
      && textField.text.length > 0) {
    [self.passwordTextField becomeFirstResponder];
    return YES;
  } else if (textField == self.passwordTextField
             && [self isCurrentEntryValid]) {
    [self login];
    return YES;
  }
  
  return NO;
}

- (void)login
{
  [[DFUserLoginManager sharedManager]
   loginWithEmail:self.emailTextField.text
   password:self.passwordTextField.text
   success:^{
     dispatch_async(dispatch_get_main_queue(), ^{
       [[DFUserLoginManager sharedManager] dismissNotLoggedInControllerWithCompletion:^{
         [SVProgressHUD showSuccessWithStatus:@"Logged in"];
       }];
     });
   } failure:^(NSError *error) {
     [SVProgressHUD showErrorWithStatus:error.localizedDescription];
   }];
}

@end
