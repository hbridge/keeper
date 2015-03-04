//
//  DFImageDataHelper.h
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFImageDataHelper : NSObject

+ (NSDictionary *)metadataForImageData:(NSData *)data;

@end
