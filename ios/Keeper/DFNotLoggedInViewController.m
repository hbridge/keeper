//
//  DFNotLoggedInViewController.m
//  Keeper
//
//  Created by Henry Bridge on 3/5/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFNotLoggedInViewController.h"
#import "DFLoginViewController.h"
#import "DFNavigationController.h"
#import "DFCreateAccountViewController.h"

@interface DFNotLoggedInViewController ()

@end

@implementation DFNotLoggedInViewController



- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [DFKeeperConstants BarBackgroundColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.navigationController
   setNavigationBarHidden:YES animated:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return UIStatusBarStyleLightContent;
}
- (IBAction)createAccountPressed:(id)sender {
  DFCreateAccountViewController *createAccountController = [[DFCreateAccountViewController alloc] init];
  [DFNavigationController presentWithRootController:createAccountController
                                           inParent:self
                                withBackButtonTitle:@"Cancel"];
}

- (IBAction)loginPressed:(id)sender {
  DFLoginViewController *loginViewController = [[DFLoginViewController alloc] init];
  [DFNavigationController presentWithRootController:loginViewController
                                           inParent:self
                                withBackButtonTitle:@"Cancel"];
}

@end
