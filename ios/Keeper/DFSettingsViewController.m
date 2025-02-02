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

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.navigationItem.title = @"Settings";
  }
  return self;
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

- (void)sendFeedback:(id)sender
{
  DFDiagnosticInfoMailComposeController *mailComposer =
  [[DFDiagnosticInfoMailComposeController alloc] initWithMailType:DFMailTypeFeedback];
  if (mailComposer) { // if the user hasn't setup email, this will come back nil
    [self presentViewController:mailComposer animated:YES completion:nil];
  } else {
    [UIAlertView showSimpleAlertWithTitle:@"No mail accounts"
                            formatMessage:@"You have no mail accounts set up to send email."];
  }
}

- (void)signOut:(id)sender
{
  DDLogInfo(@"Sign Out");
  [[DFUserLoginManager sharedManager] logout];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      abort();
  });
}

- (void)configureCategories:(id)sender
{
  self.categorizeController = [[DFCategorizeController alloc] init];
  self.categorizeController.isEditModeEnabled = YES;
  [self.categorizeController presentInViewController:self];
}

@end
