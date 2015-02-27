//
//  DFCategorizeController.m
//  Keeper
//
//  Created by Henry Bridge on 2/24/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFCategorizeController.h"
#import "DFCategoryConstants.h"
#import "DFSettingsManager.h"
#import "DFAlertController.h"


@interface DFCategorizeController()

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic) NSInteger buttonToSet;
@property (nonatomic, retain) CNPGridMenu *gridMenu;

@end

@implementation DFCategorizeController

const int NumCategories = 8;

- (void)presentInViewController:(UIViewController *)viewController
{
  self.presentingViewController = viewController;
  self.gridMenu = [[CNPGridMenu alloc] init];
  [self reloadItems];
  self.gridMenu.delegate = self;
  [self.presentingViewController presentGridMenu:self.gridMenu animated:YES completion:nil];
}

- (void)reloadItems
{
  NSMutableArray *items = [NSMutableArray new];
  NSDictionary *userCategories = [DFSettingsManager objectForSetting:DFSettingSpeedDialCategories];
  if (userCategories.count == 0) {
    userCategories = [self defaultCategoriesDictonary];
    [DFSettingsManager setObject:[[NSDictionary alloc] initWithDictionary:userCategories]
                      forSetting:DFSettingSpeedDialCategories];
  }
  
  for (int i = 0; i < NumCategories; i++) {
    CNPGridMenuItem *item = [CNPGridMenuItem new];
    NSString *userCategory = userCategories[[@(i) stringValue]];
    if ([userCategory isNotEmpty]) {
      item.title = userCategory;
      item.icon = [DFCategoryConstants gridIconForCategory:userCategory];
    }
    
    [items addObject:item];
  }
  [items addObject:[self.class otherItem]];
  self.gridMenu.menuItems = items;
}

- (NSDictionary *)defaultCategoriesDictonary
{
  NSArray *defaultCategories = [DFCategoryConstants defaultCategoryNames];
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  for (int i = 0; i < defaultCategories.count; i++) {
    dict[[@(i) stringValue]] = defaultCategories[i];
  }
  return dict;
}

+ (CNPGridMenuItem *)otherItem
{
  CNPGridMenuItem *otherItem = [CNPGridMenuItem new];
  otherItem.title = @"Other";
  otherItem.icon = [DFCategoryConstants defaultGridIcon];
  return otherItem;
}

- (void)gridMenuDidTapOnBackground:(CNPGridMenu *)menu
{
  [self categorySelected:nil];
}

- (void)gridMenu:(CNPGridMenu *)menu didTapOnItem:(CNPGridMenuItem *)item
{
  NSString *category = item.title;
  
  if ([category isNotEmpty]) {
    if ([category isEqualToString:@"Other"]) {
      [self showEnterTextAlertWithTitle:@"Other Category"
                          okButtonTitle:@"OK"
                            buttonToSet:-1];
    } else {
      [self categorySelected:category];
    }
  } else {
    [self showEnterTextAlertWithTitle:@"Set Category"
                        okButtonTitle:@"Save"
                          buttonToSet:[menu.menuItems indexOfObject:item]];
  }
}

- (void)showEnterTextAlertWithTitle:(NSString *)title
                              okButtonTitle:(NSString *)okTitle
                                buttonToSet:(NSInteger)buttonToSet
{
  self.buttonToSet = buttonToSet;
  UIAlertView *otherAlert = [[UIAlertView alloc] initWithTitle:title
                                                       message:nil
                                                      delegate:self
                                             cancelButtonTitle:@"Cancel"
                                             otherButtonTitles:okTitle, nil];
  otherAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [[otherAlert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
  [[otherAlert textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeYes];
  [otherAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSString *category = [[alertView textFieldAtIndex:0] text];
  if([category isNotEmpty] && buttonIndex != alertView.cancelButtonIndex) {
    if (self.buttonToSet < 0) {
      [self categorySelected:category];
    } else {
      NSMutableDictionary *userCategories = [[DFSettingsManager objectForSetting:DFSettingSpeedDialCategories]
                                             mutableCopy];
      userCategories[[@(self.buttonToSet) stringValue]] = category;
      [DFSettingsManager setObject:userCategories forSetting:DFSettingSpeedDialCategories];
      [self reloadItems];
    }
  }
}

- (void)categorySelected:(NSString *)category
{
  [self.presentingViewController dismissGridMenuAnimated:YES completion:nil];
  [self.delegate categorizeController:self didFinishWithCategory:category];
}


@end
