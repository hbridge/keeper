//
//  DFRootViewController.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFCameraViewController.h"
#import "DFLibraryViewController.h"

@interface DFRootViewController : UIViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (nonatomic) BOOL hideStatusBar;

@property (nonatomic, retain) DFCameraViewController *cameraViewController;
@property (nonatomic, retain) DFLibraryViewController *libraryViewController;
@property (nonatomic, retain) UINavigationController *libraryNavController;

+ (DFRootViewController *)rootViewController;
- (void)showLibrary;
- (void)showCamera;

- (void)setSwipingEnabled:(BOOL)isSwipingEnabled;

@end
