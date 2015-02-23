//
//  DFCategoryConstants.h
//  Keeper
//
//  Created by Henry Bridge on 2/23/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFCategoryConstants : NSObject

+ (NSArray *)defaultCategoryNames;
+ (UIImage *)gridIconForCategory:(NSString *)name;
+ (UIImage *)defaultGridIcon;

@end
