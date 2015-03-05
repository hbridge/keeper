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

@interface DFSettingsViewController ()

@end

static DFCategorizeController *categorizeController;

@implementation DFSettingsViewController

+ (void)presentInViewController:(UIViewController *)presentingViewController
{
  DFAlertController *alertController = [DFAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:DFAlertControllerStyleActionSheet];
  
  //logout
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Logout"
                              style:DFAlertActionStyleDestructive
                              handler:^(DFAlertAction *action) {
                                [[DFUserLoginManager sharedManager] logout];
                                abort();
                              }]];
  
  // send logs
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Send Logs"
                              style:DFAlertActionStyleDefault
                              handler:^(DFAlertAction *action) {
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
                                  [presentingViewController presentViewController:mailComposer animated:YES completion:nil];
                                }
                                #endif
                              }]];
  
  // Auto Save
  NSString *autoSaveString;
  NSString *autoSavePref = [DFSettingsManager objectForSetting:DFSettingAutoSaveToCameraRoll];
  NSString *opposteSettingValue;
  if ([autoSavePref isEqualToString:DFSettingValueYes]) {
    autoSaveString = @"Disable Save to Camera Roll";
    opposteSettingValue = DFSettingValueNo;
  } else {
    autoSaveString = @"Enable Save to Camera Roll";
    opposteSettingValue = DFSettingValueYes;
  }
  [alertController addAction:[DFAlertAction
                              actionWithTitle:autoSaveString
                              style:DFAlertActionStyleDefault
                              handler:^(DFAlertAction *action) {
                                [DFSettingsManager setObject:opposteSettingValue
                                                  forSetting:DFSettingAutoSaveToCameraRoll];
                              }]];
  
  // Auto Import Screenshots
  NSString *autoImportScreenshotsLabel;
  NSString *autoImportScreenshotsPref = [DFSettingsManager objectForSetting:DFSettingAutoImportScreenshots];
  NSString *oppositeAutoImportValue;
  if ([autoImportScreenshotsPref isEqualToString:DFSettingValueYes]) {
    autoImportScreenshotsLabel = @"Disable Auto Import Screenshots";
    oppositeAutoImportValue = DFSettingValueNo;
  } else {
    autoImportScreenshotsLabel = @"Enable Auto Import Screenshots";
    oppositeAutoImportValue = DFSettingValueYes;
  }
  [alertController addAction:[DFAlertAction
                              actionWithTitle:autoImportScreenshotsLabel
                              style:DFAlertActionStyleDefault
                              handler:^(DFAlertAction *action) {
                                [DFSettingsManager setObject:oppositeAutoImportValue
                                                  forSetting:DFSettingAutoImportScreenshots];
                              }]];
  
  // Edit categories
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Edit Category Speed Dial"
                              style:DFAlertActionStyleDefault
                              handler:^(DFAlertAction *action) {
                                categorizeController = [[DFCategorizeController alloc] init];
                                categorizeController.isEditModeEnabled = YES;
                                [categorizeController presentInViewController:presentingViewController];
                              }]];
  
  // Cancel
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Cancel"
                              style:DFAlertActionStyleCancel
                              handler:^(DFAlertAction *action) {
                              }]];
  [alertController showWithParentViewController:presentingViewController animated:YES completion:nil];
}

@end
