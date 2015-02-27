//
//  DFImageUploadManager.h
//  Keeper
//
//  Created by Henry Bridge on 2/27/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFImageUploadManager : NSObject <NSURLSessionDelegate>

+ (DFImageUploadManager *)sharedManager;

- (void)uploadImageFile:(NSURL *)imageFile forKey:(NSString *)key;
- (NSSet *)uploadedKeys;

@end
