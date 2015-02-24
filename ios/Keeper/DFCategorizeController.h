//
//  DFCategorizeController.h
//  Keeper
//
//  Created by Henry Bridge on 2/24/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFKeeperPhoto.h"
#import <CNPGridMenu/CNPGridMenu.h>


@class DFCategorizeController;

@protocol DFCategorizeControllerDelegate <NSObject>

@required
- (void)categorizeController:(DFCategorizeController *)cateogrizeController
       didFinishWithCategory:(NSString *)category;

@end


@interface DFCategorizeController : NSObject <CNPGridMenuDelegate>

@property (nonatomic, weak) NSObject<DFCategorizeControllerDelegate> *delegate;

- (void)presentInViewController:(UIViewController *)viewController;

@end
