//
//  AppDelegate.m
//  Keeper
//
//  Created by Henry Bridge on 2/15/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <CocoaLumberjack/DDFileLogger.h>
#import <AWSiOSSDKv2/AWSCore.h>
#import "DFNetworkingConstants.h"
#import "DFRootViewController.h"
#import "DFLoginViewController.h"
#import <HockeySDK/HockeySDK.h>
#import "DFAnalytics.h"
#import "DFImageManager.h"
#import "DFCameraRollScanManager.h"

@interface AppDelegate ()

@property (nonatomic,retain) DDFileLogger *fileLogger;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [self printSimulatorInfo];
  [self configureLogs];
  [self configureHockey];
  [self configureNetworking];
  [self configureUI];

  return YES;
}

- (void)printSimulatorInfo
{
#if TARGET_IPHONE_SIMULATOR
  NSLog(@"Simulator build running from: %@", [ [NSBundle mainBundle] bundleURL] );
  NSLog(@"Simulator User Docs: %@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                            inDomains:NSUserDomainMask]
                                     lastObject]);
#endif
}

- (void)configureLogs
{
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  
  self.fileLogger = [[DDFileLogger alloc] init];
  self.fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
  self.fileLogger.logFileManager.maximumNumberOfLogFiles = 3; // 3 days of files
  
  // To simulate the amount of log data saved, use the release log level for the fileLogger
  [DDLog addLogger:self.fileLogger withLogLevel:DFRELEASE_LOG_LEVEL];
}

- (void)configureHockey
{
#ifdef DEBUG
  [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"fdbbec001bdce74a871d514b9ab5e946"
                                                         delegate:nil];
#else
  [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"802dc9c36f5afedf300ef4a70382bd78"
                                                         delegate:nil];
#endif
  
  [[BITHockeyManager sharedHockeyManager] startManager];
  [[BITHockeyManager sharedHockeyManager].authenticator
   authenticateInstallation];
}

- (void)configureNetworking
{
  AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider credentialsWithRegionType:CognitoRegionType
                                                                                                 identityPoolId:CognitoIdentityPoolId];
  AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:DefaultServiceRegionType
                                                                        credentialsProvider:credentialsProvider];
  [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
}


- (void)configureUI
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [self.window makeKeyAndVisible];
  
  if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
    // only create views etc if we're not being launched in the background
    [self showMainView];
  }
}

- (void)showMainView
{
  DFRootViewController *rvc = [[DFRootViewController alloc] init];
  self.window.rootViewController = rvc;
}

- (void)showLoginIfNecessary
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (![DFLoginViewController isUserLoggedIn]) {
      DDLogInfo(@"User not logged in, showing login");
      DFLoginViewController *loginVC = [[DFLoginViewController alloc] init];
      [self.window.rootViewController presentViewController:loginVC animated:YES completion:nil];
    }
  });
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  [DFAnalytics CloseAnalyticsSession];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  [DFAnalytics CloseAnalyticsSession];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  [DFAnalytics ResumeAnalyticsSession];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  [DFAnalytics StartAnalyticsSession];
  [self showLoginIfNecessary];
  [[DFImageManager sharedManager] performForegroundOperations];
  [[DFCameraRollScanManager sharedManager] scan];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  [DFAnalytics CloseAnalyticsSession];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
  NSLog(@"%s",__PRETTY_FUNCTION__);
  /*
   Store the completion handler.
   */
  if ([identifier isEqualToString:BackgroundSessionUploadIdentifier]) {
    self.backgroundUploadSessionCompletionHandler = completionHandler;
  } else if ([identifier isEqualToString:BackgroundSessionDownloadIdentifier]) {
    self.backgroundDownloadSessionCompletionHandler = completionHandler;
  }
}

@end
