//
//  DFCreateAccountViewController.m
//  Keeper
//
//  Created by Henry Bridge on 3/5/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFCreateAccountViewController.h"
#import "DFUserLoginManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "DFUIKit.h"

@interface DFCreateAccountViewController ()

@end

@implementation DFCreateAccountViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  for (DFInsetTextField *tf in @[self.nameTextField, self.emailTextField, self.passwordTextField]) {
    tf.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    tf.layer.borderWidth = 1.0;
    tf.textInsets = UIEdgeInsetsMake(0, 4, 0, 4);
  }
  
  [self setButtonEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.nameTextField becomeFirstResponder];
}


- (IBAction)editingChanged:(id)sender {
  [self setButtonEnabled:[self isCurrentEntryValid]];
}

- (BOOL)isCurrentEntryValid
{
  return ([self.nameTextField.text isNotEmpty]
          && [self.emailTextField.text isNotEmpty]
          && [self.passwordTextField.text isNotEmpty]);
}

- (void)setButtonEnabled:(BOOL)enabled
{
  self.createAccountButton.enabled = enabled;
  self.createAccountButton.alpha = enabled ? 1.0 : 0.5;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if (textField == self.nameTextField
      && self.nameTextField.text.length > 0) {
    [self.emailTextField becomeFirstResponder];
    return YES;
  } else if (textField == self.emailTextField
      && textField.text.length > 0) {
    [self.passwordTextField becomeFirstResponder];
    return YES;
  } else if (textField == self.passwordTextField
             && [self isCurrentEntryValid]) {
    [self createAccountPressed:self.passwordTextField];
    return YES;
  }
  
  return NO;
}


- (IBAction)createAccountPressed:(id)sender {
  [[DFUserLoginManager sharedManager]
   createUserWithName:self.nameTextField.text
   email:self.emailTextField.text
   password:self.passwordTextField.text
   success:^{
     dispatch_async(dispatch_get_main_queue(), ^{
       [[DFUserLoginManager sharedManager] dismissNotLoggedInControllerWithCompletion:^{
         [SVProgressHUD showSuccessWithStatus:@"Account Created!"];
       }];
     });
   } failure:^(NSError *error) {
     [SVProgressHUD showErrorWithStatus:error.localizedDescription];
   }];
}

- (IBAction)termsButtonPressed:(id)sender {
  DFAlertController *alertController = [DFAlertController
                                        alertControllerWithTitle:nil
                                        message:nil
                                        preferredStyle:DFAlertControllerStyleActionSheet];
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Terms and Conditions"
                              style:DFAlertActionStyleDefault
                              handler:^(DFAlertAction *action) {
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:DFTermsPageURLString]];
                              }]];
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Privacy Policy"
                              style:DFAlertActionStyleDefault
                              handler:^(DFAlertAction *action) {
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:DFPrivacyPageURLString]];
                              }]];
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Cancel"
                              style:DFAlertActionStyleCancel handler:^(DFAlertAction *action) {
                                
                              }]];
  
  [alertController showWithParentViewController:self animated:YES completion:nil];
}
@end
