//
//  DFNavigationController.m
//  Strand
//
//  Created by Henry Bridge on 7/16/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "DFNavigationController.h"
#import "DFKeeperConstants.h"
#import "DFOverlayViewController.h"

@interface DFNavigationController ()

@property (nonatomic, retain) UIWindow *overlayWindow;
@property (nonatomic, retain) DFOverlayViewController *overlayVC;

@end

@implementation DFNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
  self = [super initWithNavigationBarClass:[UINavigationBar class] toolbarClass:[UIToolbar class]];
  if (self) {
    self.viewControllers = @[rootViewController];
    self.navigationBar.translucent = NO;
    self.navigationBar.barTintColor = [DFKeeperConstants BarBackgroundColor];
    self.navigationBar.tintColor = [DFKeeperConstants BarForegroundColor];
    self.navigationBar.titleTextAttributes = @{
                                 NSForegroundColorAttributeName:
                                   [DFKeeperConstants BarForegroundColor]
                                 };
  }
  
  return self;
}

- (instancetype)init
{
  return [self initWithRootViewController:nil];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
  return [DFKeeperConstants DefaultStatusBarStyle];
}

+ (void)presentWithRootController:(UIViewController *)rootController
                         inParent:(UIViewController *)parent
{
  [self presentWithRootController:rootController inParent:parent withBackButtonTitle:@"Cancel"];
}

+ (void)presentWithRootController:(UIViewController *)rootController
                         inParent:(UIViewController *)parent
              withBackButtonTitle:(NSString *)backButtonTitle
{
  DFNavigationController *navController = [[DFNavigationController alloc] initWithRootViewController:rootController];
  NSMutableArray *leftItems = [[NSMutableArray alloc]
                               initWithArray:rootController.navigationItem.leftBarButtonItems];
  [leftItems insertObject:[[UIBarButtonItem alloc]
                           initWithTitle:backButtonTitle
                           style:UIBarButtonItemStylePlain
                           target:navController
                           action:@selector(dismissWhenPresented)]
                  atIndex:0];
  rootController.navigationItem.leftBarButtonItems = leftItems;
  [parent presentViewController:navController animated:YES completion:nil];
}


- (void)dismissWhenPresented
{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  self.navigationBar.frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, 64.0);
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  self.navigationBar.frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, 64.0);
}


@end
