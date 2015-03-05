//
//  DFUserLoginManager.h
//  Keeper
//
//  Created by Henry Bridge on 3/5/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFUserLoginManager : NSObject

+ (DFUserLoginManager *)sharedManager;
- (void)observeLoginChanges;

- (void)createUserWithName:(NSString *)name
                     email:(NSString *)email
                  password:(NSString *)password
                   success:(DFSuccessBlock)success
                   failure:(DFFailureBlock)failure;

- (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
               success:(DFSuccessBlock)success
               failure:(DFFailureBlock)failure;
- (BOOL)isUserLoggedIn;
- (void)logout;
- (void)dismissNotLoggedInControllerWithCompletion:(DFVoidBlock)completion;

@end
