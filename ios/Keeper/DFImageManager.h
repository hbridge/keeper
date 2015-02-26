//
//  DFImageManager.h
//  Strand
//
//  Created by Henry Bridge on 10/28/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFImageManagerRequest.h"
#import "DFKeeperPhoto.h"

@interface DFImageManager : NSObject

typedef void (^SetImageCompletion)(NSError *error);

+ (DFImageManager *)sharedManager;

// convenience method, converts points (logical size) to screen pixel size
- (void)imageForKey:(NSString *)imageKey
          pointSize:(CGSize)size
        contentMode:(DFImageRequestContentMode)contentMode
       deliveryMode:(DFImageRequestDeliveryMode)deliveryMode
         completion:(ImageLoadCompletionBlock)completionBlock;

- (void)imageForKey:(NSString *)imageKey
               size:(CGSize)size
        contentMode:(DFImageRequestContentMode)contentMode
       deliveryMode:(DFImageRequestDeliveryMode)deliveryMode
         completion:(ImageLoadCompletionBlock)completionBlock;

// highest resolution version of image available, skips cache
- (void)originalImageForID:(NSString *)imageKey
                completion:(ImageLoadCompletionBlock)completion;

- (void)startCachingImagesForKeys:(NSArray *)keys
                       targetSize:(CGSize)size
                      contentMode:(DFImageRequestContentMode)contentMode;
- (void)clearCache;
- (void)setImageChanged:(NSString *)imageKey;

@end
