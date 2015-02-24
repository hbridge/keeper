//
//  DFCategorizeController.m
//  Keeper
//
//  Created by Henry Bridge on 2/24/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFCategorizeController.h"
#import "DFCategoryConstants.h"

@interface DFCategorizeController()

@property (nonatomic, weak) UIViewController *presentingViewController;

@end

@implementation DFCategorizeController

- (void)presentInViewController:(UIViewController *)viewController
{
  _presentingViewController = viewController;
  NSArray *items =
  [[DFCategoryConstants defaultCategoryNames] arrayByMappingObjectsWithBlock:^id(NSString *title) {
    CNPGridMenuItem *item = [CNPGridMenuItem new];
    item.title = title;
    item.icon = [DFCategoryConstants gridIconForCategory:title];
    return item;
  }];
  CNPGridMenu *gridMenu = [[CNPGridMenu alloc] initWithMenuItems:items];
  
  gridMenu.delegate = self;
  [viewController presentGridMenu:gridMenu animated:YES completion:nil];
}

- (void)gridMenuDidTapOnBackground:(CNPGridMenu *)menu
{
  [self.presentingViewController dismissGridMenuAnimated:YES completion:nil];
  [self.delegate categorizeController:self didFinishWithCategory:nil];
}

- (void)gridMenu:(CNPGridMenu *)menu didTapOnItem:(CNPGridMenuItem *)item
{
  NSString *category = item.title;
  [self.delegate categorizeController:self didFinishWithCategory:category];
}


@end
