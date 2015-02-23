//
//  DFUser.m
//  Keeper
//
//  Created by Henry Bridge on 2/23/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFUser.h"
#import <Firebase/Firebase.h>

@implementation DFUser

+ (NSString *)loggedInUser
{
  Firebase *ref = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
  return ref.authData.uid;
}

@end
