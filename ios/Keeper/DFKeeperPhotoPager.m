//
//  DFKeeperPhotoPager.m
//  Keeper
//
//  Created by Henry Bridge on 4/1/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperPhotoPager.h"
#import "DFRootViewController.h"

@implementation DFKeeperPhotoPager

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.translucent = YES;
  self.navigationController.navigationBar.backgroundColor = [DFKeeperConstants BarBackgroundColor];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [[DFRootViewController rootViewController] setSwipingEnabled:NO];
  self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  self.navigationController.navigationBar.translucent = NO;
  [self.navigationController setNavigationBarHidden:NO];
  if (self.isMovingFromParentViewController)
    [[DFRootViewController rootViewController] setSwipingEnabled:YES];
  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
  BOOL chromeHidden = ((DFKeeperPhotoViewController*)self.viewControllers.firstObject).chromeHidden;
  for (DFKeeperPhotoViewController *detailPVC in pendingViewControllers) {
    //sometimes the PVC caches view controllers, so make sure we set the value before it transitions
    detailPVC.chromeHidden = chromeHidden;
  }
  self.view.backgroundColor = chromeHidden ? [UIColor blackColor] : [UIColor whiteColor];
}

@end
