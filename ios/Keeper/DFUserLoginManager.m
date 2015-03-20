//
//  DFUserLoginManager.m
//  Keeper
//
//  Created by Henry Bridge on 3/5/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFUserLoginManager.h"
#import <Firebase/Firebase.h>
#import "DFNotLoggedInViewController.h"
#import "AppDelegate.h"
#import <SVProgressHUD/SVProgressHUD.h>

@implementation DFUserLoginManager

+ (DFUserLoginManager *)sharedManager {
  static DFUserLoginManager *defaultManager = nil;
  if (!defaultManager) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      defaultManager = [[super allocWithZone:nil] init];
    });
  }
  return defaultManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
  return [self sharedManager];
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    [self observeLoginChanges];
  }
  return self;
}

static DFNotLoggedInViewController *notLoggedInController;
- (void)observeLoginChanges
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Firebase *ref = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
    [ref observeAuthEventWithBlock:^(FAuthData *authData) {
      if (!authData) {
        DDLogInfo(@"User not logged in, showing login");
        dispatch_async(dispatch_get_main_queue(), ^{
          notLoggedInController = [[DFNotLoggedInViewController alloc] init];
          UIViewController *rootController = [UIApplication sharedApplication].delegate.window.rootViewController;
          if (rootController.presentedViewController) {
            [rootController dismissViewControllerAnimated:NO completion:^{
              [rootController presentViewController:notLoggedInController animated:YES completion:nil];
            }];
          } else {
            [rootController presentViewController:notLoggedInController animated:YES completion:nil];
          }
        });
      }
    }];
  });
}

- (void)dismissNotLoggedInControllerWithCompletion:(DFVoidBlock)completion
{
  if (notLoggedInController) {
    DDLogWarn(@"%@ dismissing not loggedin controller", self.class);
    [notLoggedInController.presentingViewController
     dismissViewControllerAnimated:YES
     completion:^{
       dispatch_async(dispatch_get_main_queue(), ^{
         if (completion) completion();
         notLoggedInController = nil;
       });
     }];
  } else {
    DDLogWarn(@"%@ asked to dismiss not logged in controller, but it's nil", self.class);
    if (completion) completion();
  }
}

- (void)createUserWithName:(NSString *)name
                     email:(NSString *)email
                  password:(NSString *)password
                 otherInfo:(NSDictionary *)otherInfo
                   success:(DFSuccessBlock)success
                   failure:(DFFailureBlock)failure
{
  Firebase *rootBase = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  [rootBase
   createUser:email
   password:password
   withValueCompletionBlock:^(NSError *error,
                              NSDictionary *result) {
     if (error) {
       failure(error);
       DDLogVerbose(@"%@ auth error: %@", self.class, error);
     } else {
       // the account was created, now log the user in
       DDLogVerbose(@"%@ created account:%@", self.class, result);
       [self loginWithEmail:email
                   password:password
                    success:^{
                      Firebase *userRef = [[rootBase childByAppendingPath:@"users"] childByAppendingPath:result[@"uid"]];
                      NSMutableDictionary *userInfo = [@{
                                                        @"name" : name,
                                                        @"email" : email,
                                                        } mutableCopy];
                      [userInfo addEntriesFromDictionary:otherInfo];
                      [userRef setValue:userInfo];
                      success();
                    }
                    failure:failure];
     }
   }];
}


- (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
               success:(DFSuccessBlock)success
               failure:(DFFailureBlock)failure
{
  Firebase *rootBase = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  [rootBase authUser:email password:password
 withCompletionBlock:^(NSError *error, FAuthData *authData) {
   if (error) {
     failure(error);
     DDLogVerbose(@"%@ auth error: %@", self.class, error);
   } else {
     success();
     DDLogVerbose(@"%@ user authed authData:%@", self.class, authData);
   }
 }];
}

- (BOOL)isUserLoggedIn
{
  Firebase *ref = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  if (ref.authData) {
    return YES;
  } else {
    return NO;
  }
}

- (void)logout
{
  Firebase *ref = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  [[NSNotificationCenter defaultCenter] postNotificationName:DFUserLoggedOutNotification object:self];
  NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
  [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
  [ref unauth];
}

- (NSString *)loggedInEmailAddress
{
  Firebase *ref = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  if (ref.authData) {
    return ref.authData.providerData[@"email"];
  }
  return nil;
}

- (BOOL)isLoggedInUserDeveloper
{
  #ifdef DEBUG
    return YES;
  #else 
    NSString *email = [self loggedInEmailAddress];
    if ([email containsString:@"@duffytech.co"]) return YES;
  
    NSArray *devEmails = @[
                           @"hbridge@gmail.com",
                           @"aseem123@gmail.com",
                           @"dparham@gmail.com",
                           ];
  
    for (NSString *devEmail in devEmails) {
      if ([devEmail isEqualToString:email]) return YES;
    }
    
    return NO;
  #endif
}


@end
