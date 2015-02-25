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
  Firebase *rootBase = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  [rootBase authUser:self.emailTextField.text password:self.passwordTextField.text
 withCompletionBlock:^(NSError *error, FAuthData *authData) {
   if (error) {
     [SVProgressHUD showErrorWithStatus:error.localizedDescription];
     DDLogVerbose(@"%@ auth error: %@", self.class, error);
   } else {
     [SVProgressHUD showSuccessWithStatus:@"Logged in"];
     [self dismissViewControllerAnimated:YES completion:nil];
     DDLogVerbose(@"%@ user authed authData:%@", self.class, authData);
   }
 }];
}

+ (BOOL)isUserLoggedIn
{
  Firebase *ref = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  if (ref.authData) {
    return YES;
  } else {
    return NO;
  }
}

+ (void)logoutWithParentViewController:(UIViewController *)parentViewController
{
  Firebase *ref = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  [ref unauth];
  dispatch_async(dispatch_get_main_queue(), ^{
    DFLoginViewController *login = [[DFLoginViewController alloc] init];
    [parentViewController presentViewController:login animated:YES completion:nil];
  });
  NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
  [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

@end
