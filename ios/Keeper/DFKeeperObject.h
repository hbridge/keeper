//
//  DFKeeperObject.h
//  Keeper
//
//  Created by Henry Bridge on 3/2/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface DFKeeperObject : NSObject

@property (nonatomic, retain) NSString *key;

+ (NSArray *)directMappingKeys;
+ (NSString *)objectsPath;
- (instancetype)initWithSnapshot:(FDataSnapshot *)snapshot;
- (NSDictionary *)dictionary;

- (Firebase *)firebaseRef;


@end
