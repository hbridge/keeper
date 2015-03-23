//
//  DFAnalytics.m
//  Duffy
//
//  Created by Henry Bridge on 4/8/14.
//  Copyright (c) 2014 Duffy Productions. All rights reserved.
//

#import "DFAnalytics.h"
#import <Localytics/Localytics.h>
#import "DFUserLoginManager.h"

static BOOL DebugLogging = YES;

@interface DFAnalytics()

@end

@implementation DFAnalytics

/*** Generic Keys and values ***/

NSString* const ActionTypeKey = @"actionType";
NSString* const DFAnalyticsActionTypeTap = @"tap";
NSString* const DFAnalyticsActionTypeSwipe = @"swipe";
NSString* const NumberKey = @"number";

NSString* const ResultKey = @"result";
NSString* const DFAnalyticsValueResultSuccess = @"success";
NSString* const DFAnalyticsValueResultFailure = @"failure";
NSString* const DFAnalyticsValueResultInvalidInput = @"invalidInput";
NSString* const DFAnalyticsValueResultAborted = @"aborted";
NSString* const ParentViewControllerKey = @"parentView";

DFAnalyticsEventType DFAnalyticsEventPhotoTaken = @"PhotoTaken";
DFAnalyticsEventType DFAnalyticsEventPhotoImported = @"PhotoImported";
DFAnalyticsEventType DFAnalyticsEventLibraryPhotoTapped = @"LibraryPhotoTapped";
DFAnalyticsEventType DFAnalyticsEventLibraryFiltered = @"LibraryFiltered";
DFAnalyticsEventType DFAnalyticsEventSettingChanged = @"SettingChanged";
DFAnalyticsEventType DFAnalyticsEventPhotoAction = @"PhotoAction";
DFAnalyticsEventType DFAnalyticsEventSearchCompleted = @"SearchCompleted";


static DFAnalytics *defaultLogger;

+ (void)StartAnalyticsSession
{
  if ([[DFUserLoginManager sharedManager] isLoggedInUserDeveloper]) {
    [Localytics integrate:@"9630379c33cbeb730f3d801-e30ec20c-bbb1-11e4-ad26-009c5fda0a25"];
  } else {
    [Localytics integrate:@"1f0f9ab17ebeff8753e9ee9-002ad6e6-bbb3-11e4-ad25-009c5fda0a25"];
  }
  #ifndef DEBUG
    DebugLogging = NO;
  #endif
  
  [Localytics setLoggingEnabled:DebugLogging];

  [DFAnalytics ResumeAnalyticsSession];
}

+ (void)ResumeAnalyticsSession
{
  [Localytics openSession];
  [Localytics upload];
}

+ (void)CloseAnalyticsSession
{
  [Localytics closeSession];
  [Localytics upload];
}

+ (void)setCustomerId:(NSString *)customerId
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [Localytics setCustomerId:customerId];
  });
}

+ (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters
{
  [Localytics tagEvent:eventName attributes:parameters];
  if ([Localytics isLoggingEnabled]) {
    DDLogVerbose(@"%@: \n%@", eventName, parameters);
  }
}

+ (void)logEvent:(NSString *)eventName
{
  [Localytics tagEvent:eventName];
}


+ (void)logViewController:(UIViewController *)viewController appearedWithParameters:(NSDictionary *)params
{
  NSString *screenName = [self screenNameForControllerViewed:viewController];
  [Localytics tagScreen:screenName];
  [DFAnalytics logEvent:[NSString stringWithFormat:@"%@Viewed",screenName] withParameters:params];
}

+ (void)logViewController:(UIViewController *)viewController disappearedWithParameters:(NSDictionary *)params
{
  // Do nothing for now
}

+ (NSString *)screenNameForControllerViewed:(UIViewController *)viewController
{
  NSMutableString *className = [[viewController.class description] mutableCopy];
  //remove DF
  [className replaceOccurrencesOfString:@"DF"
                             withString:@""
                                options:0
                                  range:(NSRange){0,2}];
  //remove ViewController
  [className replaceOccurrencesOfString:@"ViewController"
                             withString:@""
                                options:0
                                  range:(NSRange) {0, className.length}];
  
  
  return className ? className : @"";
}






@end
