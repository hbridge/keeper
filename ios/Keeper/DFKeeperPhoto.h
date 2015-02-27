//
//  DFKeeperPhoto.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface DFKeeperPhoto : NSObject

/* unique */
@property (nonatomic, retain) NSString *key;
/* simple mappings */
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *category;
@property (nonatomic, retain) NSDictionary *metadata;
@property (nonatomic, retain) NSString *imageKey;
@property (nonatomic, retain) NSNumber *uploaded;
/* calculated conversion */
@property (nonatomic, retain) NSDate *saveDate;


@property (readonly, nonatomic, retain) NSDictionary *dictionary;

- (instancetype)initWithSnapshot:(FDataSnapshot *)snapshot;

@end
