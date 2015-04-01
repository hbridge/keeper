//
//  DFItemPageViewController.m
//  Keeper
//
//  Created by Henry Bridge on 4/1/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFItemPageViewController.h"

@implementation DFItemPageViewController

- (instancetype)initWithStartingItem:(id)item
                             inItems:(NSArray *)items
             itemToViewController:(DFItemToViewControllerBlock)itemToViewControllerBlock
                viewControllerToItem:(DFViewControllerToItemBlock)viewControllerToItemBlock
{
  self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                  navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                options:@{UIPageViewControllerOptionInterPageSpacingKey :@(20)}];
  if (self) {
    _items = items;
    _itemToViewController = itemToViewControllerBlock;
    _viewControllerToItem = viewControllerToItemBlock;
    
    UIViewController *vc = itemToViewControllerBlock(item);
    if (vc)
      [self setViewControllers:@[vc]
                     direction:UIPageViewControllerNavigationDirectionForward
                      animated:NO
                    completion:nil];
  }
  
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.dataSource = self;
  self.delegate = self;
  self.view.backgroundColor = [UIColor whiteColor];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
  return [self viewControllerAscending:YES
                    fromViewController:viewController];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
  return [self viewControllerAscending:NO
                    fromViewController:viewController];
}

- (UIViewController *)viewControllerAscending:(BOOL)ascending
                           fromViewController:(UIViewController *)viewController
{
  id item = self.viewControllerToItem(viewController);
  NSUInteger index = [self.items indexOfObject:item];
  index = index + (ascending ? 1 : - 1);
  if (index >= self.items.count) return nil;
  id afterItem = self.items[index];
  return self.itemToViewController(afterItem);
}

- (void)setViewControllers:(NSArray *)viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
  [super setViewControllers:viewControllers direction:direction animated:animated completion:completion];
  [self inheritNavItemsFromChild:viewControllers.firstObject];
}

- (void)inheritNavItemsFromChild:(UIViewController *)childViewController
{
  self.navigationItem.title = childViewController.title;
  self.navigationItem.leftBarButtonItems = childViewController.navigationItem.leftBarButtonItems;
  self.navigationItem.rightBarButtonItems = childViewController.navigationItem.rightBarButtonItems;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
  if (completed) {
    [self inheritNavItemsFromChild:self.viewControllers.firstObject];
  }
}

@end
