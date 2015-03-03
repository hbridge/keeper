//
//  DFAssetLibraryHelper.h
//  Keeper
//
//  Created by Henry Bridge on 2/25/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFAssetLibraryHelper : NSObject

+ (void)saveImageToCameraRoll:(UIImage *)image
                 withMetadata:(NSDictionary *)metadata
                   completion:(void(^)(NSURL *assetURL, NSError *error))completion;

+ (void)fetchMetadataDictForAssetWithURL:(NSURL *)assetURL
                              completion:(void(^)(NSDictionary *metadata))completion;

@end
