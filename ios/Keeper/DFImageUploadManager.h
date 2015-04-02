//
//  DFImageUploadManager.h
//  Keeper
//
//  Created by Henry Bridge on 2/27/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFImageUploadManager : NSObject <NSURLSessionDelegate, NSURLConnectionDataDelegate>

+ (DFImageUploadManager *)sharedManager;

- (void)uploadImageFile:(NSURL *)imageFile
            contentType:(NSString *)contentType
                 forKey:(NSString *)key;
- (void)uploadImageData:(NSData *)imageData
            contentType:(NSString *)contentType
                 forKey:(NSString *)key;
- (void)resumeUploads;
- (void)deleteImageWithKey:(NSString *)key;

@end
