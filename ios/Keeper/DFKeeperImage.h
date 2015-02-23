//
//  DFKeeperImage.h
//  Keeper
//
//  Created by Henry Bridge on 2/23/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface DFKeeperImage : NSObject

@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSData *data;

- (instancetype)initWithSnapshot:(FDataSnapshot *)snapshot;
- (instancetype)initWithImage:(UIImage *)image;
- (NSDictionary *)dictionary;
- (UIImage *)UIImage;


@end
