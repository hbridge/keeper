//
//  DFExifHelper.h
//  Keeper
//
//  Created by Henry Bridge on 3/4/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFExifHelper : NSObject

+ (NSDictionary *)metadataForImageAtURL:(NSURL *)url;

@end
