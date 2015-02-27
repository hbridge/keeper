//
//  DFImageStore.h
//  Strand
//
//  Created by Henry Bridge on 7/20/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFTypedefs.h"
#import "DFImageManagerRequest.h"

@interface DFImageDiskCache : NSObject

typedef void (^ImageLoadCompletionBlock)(UIImage *image);
typedef void (^SetImageCompletion)(NSError *error);

+ (DFImageDiskCache *)sharedStore;

- (void)imageForKey:(NSString *)key
     preferredType:(DFImageType)type
        completion:(ImageLoadCompletionBlock)completionBlock;

- (void)setImage:(UIImage *)image
            type:(DFImageType)type
           forKey:(NSString *)key
      completion:(SetImageCompletion)completion;
- (UIImage *)serveImageForRequest:(DFImageManagerRequest *)request;

- (NSError *)clearCache;

+ (NSURL *)applicationDocumentsDirectory;
+ (NSURL *)localFullImagesDirectoryURL;
+ (NSURL *)localThumbnailsDirectoryURL;

- (NSSet *)cachedImageKeysForType:(DFImageType)type;
- (BOOL)isImageTypeCached:(DFImageType)type forKey:(NSString *)imageKey;
- (void)loadDownloadedImagesCache;
- (BOOL)canServeRequest:(DFImageManagerRequest *)request;
- (UIImage *)fullImageForKey:(NSString *)key;
- (NSURL *)urlForFullImageWithKey:(NSString *)key;

@end
