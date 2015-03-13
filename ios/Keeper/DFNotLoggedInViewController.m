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

@property (nonatomic, retain) NSArray *nuxImageViews;

@end

@implementation DFNotLoggedInViewController


- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [DFKeeperConstants BarBackgroundColor];
  
  self.nuxImageViews = @[self.takePictureImageView,
                         self.categorizeImageView,
                         self.findImageView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.navigationController
   setNavigationBarHidden:YES animated:animated];

  for (UIImageView *imageView in self.nuxImageViews) {
    imageView.alpha = 0.0;
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  for (NSUInteger i = 0; i < self.nuxImageViews.count; i++) {
    UIImageView *imageView = self.nuxImageViews[i];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     [UIView animateWithDuration:1.0 animations:^{
                       imageView.alpha = 1.0;
                     } completion:^(BOOL finished) {
                       imageView.alpha = 1.0;
                     }];
                   });
  }
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
