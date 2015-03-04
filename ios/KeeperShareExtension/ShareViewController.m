//
//  ShareViewController.m
//  KeeperShareExtension
//
//  Created by Henry Bridge on 3/3/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "ShareViewController.h"
#import "DFCategoryConstants.h"
#import "DFShareCategorizeViewController.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
  // Do validation of contentText and/or NSExtensionContext attachments here
  return YES;
}

- (void)didSelectPost {
  // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
  
  // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
  [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
  // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
  
  SLComposeSheetConfigurationItem *item = [SLComposeSheetConfigurationItem new];
  item.title = @"Category";
  item.value = @"";
  item.tapHandler = ^{
    DFShareCategorizeViewController *categorizeController = [DFShareCategorizeViewController new];
    [self pushConfigurationViewController:categorizeController];
  };
  
  return @[item];
}

@end
