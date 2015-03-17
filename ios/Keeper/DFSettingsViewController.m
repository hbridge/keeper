//
//  DFSettingsViewController.m
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFSettingsViewController.h"
#import "DFUIKit.h"
#import "DFUserLoginManager.h"
#import "DFSettingsManager.h"
#import "DFDiagnosticInfoMailComposeController.h"
#import "DFLogs.h"
#import "DFCategorizeController.h"
#import "DFSettings.h"

@interface DFSettingsViewController ()

@property (nonatomic, retain) DFCategorizeController *categorizeController;

@end

static DFCategorizeController *categorizeController;

@implementation DFSettingsViewController

+ (void)presentInViewController:(UIViewController *)presentingViewController
{
  DFSettingsViewController *settingsViewController = [[DFSettingsViewController alloc] init];
  settingsViewController.formController.form = [DFSettings new];
  [DFNavigationController presentWithRootController:settingsViewController
                                           inParent:presentingViewController
                                withBackButtonTitle:@"Done"];
}

- (void)sendLogs:(id)sender
{
  #if TARGET_IPHONE_SIMULATOR
  NSData *logData = [DFLogs aggregatedLogData];
  NSString *filePath;
  NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
  if (paths.firstObject) {
    NSArray *pathComponents = [(NSString *)paths.firstObject pathComponents];
    if ([pathComponents[1] isEqualToString:@"Users"]) {
      filePath = [NSString stringWithFormat:@"/Users/%@/Desktop/%@.log",
                  pathComponents[2], [NSDate date]];
      
    }
  }
  [logData writeToFile:filePath atomically:NO];
  [UIAlertView showSimpleAlertWithTitle:@"Copied To Desktop"
                          formatMessage:@"Log data has been copied to your desktop."];
  
  #else
  DFDiagnosticInfoMailComposeController *mailComposer =
  [[DFDiagnosticInfoMailComposeController alloc] initWithMailType:DFMailTypeIssue];
  if (mailComposer) { // if the user hasn't setup email, this will come back nil
    [self presentViewController:mailComposer animated:YES completion:nil];
  }
  #endif
}

- (void)signOut:(id)sender
{
  DDLogInfo(@"Sign Out");
  [[DFUserLoginManager sharedManager] logout];
  abort();

}

- (void)configureCategories:(id)sender
{
  self.categorizeController = [[DFCategorizeController alloc] init];
  self.categorizeController.isEditModeEnabled = YES;
  [self.categorizeController presentInViewController:self];
}

@end
