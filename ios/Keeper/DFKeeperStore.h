//
//  DFKeeperStore.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import "DFKeeperPhoto.h"
#import "DFKeeperImage.h"

@interface DFKeeperStore : NSObject

+ (DFKeeperStore *)sharedStore;

- (void)savePhoto:(DFKeeperPhoto *)photo;
- (void)saveImage:(DFKeeperImage *)image;
- (void)deletePhoto:(DFKeeperPhoto *)photo;
- (NSArray *)photos;
- (void)fetchPhotosWithCompletion:(void(^)(NSArray *photos))completion;
- (void)fetchImagesWithCompletion:(void (^)(NSArray *images))completion;
- (DFKeeperPhoto *)photoWithKey:(NSString *)key;
- (DFKeeperPhoto *)photoWithImageKey:(NSString *)imageKey;
- (void)fetchImageWithKey:(NSString *)key
                          completion:(void (^)(DFKeeperImage *image))completion;

@end
