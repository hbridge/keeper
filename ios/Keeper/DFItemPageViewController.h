//
//  DFItemPageViewController.h
//  Keeper
//
//  Created by Henry Bridge on 4/1/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DFItemPageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

/* 
 the block that the page view controller will use to get a view controller
 for an item
 */
typedef UIViewController* (^DFItemToViewControllerBlock)(id item);
typedef id (^DFViewControllerToItemBlock)(UIViewController *vc);

@property (nonatomic, retain) NSArray *items;
@property (nonatomic, copy) DFItemToViewControllerBlock itemToViewController;
@property (nonatomic, copy) DFViewControllerToItemBlock viewControllerToItem;


- (instancetype)initWithStartingItem:(id)item
                             inItems:(NSArray *)items
                itemToViewController:(DFItemToViewControllerBlock)itemToViewControllerBlock
                viewControllerToItem:(DFViewControllerToItemBlock)viewControllerToItem;

@end
