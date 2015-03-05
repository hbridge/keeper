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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(id)sender {
  [self login];
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
