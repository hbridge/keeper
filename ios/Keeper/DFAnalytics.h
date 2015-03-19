//
//  DFAnalytics.h
//  Duffy
//
//  Created by Henry Bridge on 4/8/14.
//  Copyright (c) 2014 Duffy Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "DFTypedefs.h"

@class DFPeanutFeedObject;

@interface DFAnalytics : NSObject

extern NSString * const DFAnalyticsActionTypeTap;
extern NSString * const DFAnalyticsActionTypeSwipe;
extern NSString* const DFAnalyticsValueResultSuccess;
extern NSString* const DFAnalyticsValueResultFailure;
extern NSString* const DFAnalyticsValueResultAborted;
extern NSString* const DFAnalyticsValueResultInvalidInput;
extern const int DFMessageComposeResultCouldntStart;

typedef NSString *const DFAnalyticsEventType;
extern DFAnalyticsEventType DFAnalyticsEventPhotoTaken;
extern DFAnalyticsEventType DFAnalyticsEventPhotoImported;
extern DFAnalyticsEventType DFAnalyticsEventLibraryPhotoTapped;
extern DFAnalyticsEventType DFAnalyticsEventLibraryFiltered;
extern DFAnalyticsEventType DFAnalyticsEventSettingChanged;
extern DFAnalyticsEventType DFAnalyticsEventPhotoAction;

/* Stop and Start Session Helpers */
+ (void)StartAnalyticsSession;
+ (void)ResumeAnalyticsSession;
+ (void)CloseAnalyticsSession;

/* Generic logging for view controllers */
+ (void)logViewController:(UIViewController *)viewController
   appearedWithParameters:(NSDictionary *)params;
+ (void)logViewController:(UIViewController *)viewController
disappearedWithParameters:(NSDictionary *)params;

/* Generic event logging */
+ (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters;

@end
