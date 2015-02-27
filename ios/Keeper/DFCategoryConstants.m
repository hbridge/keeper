//
//  DFCategoryConstants.m
//  Keeper
//
//  Created by Henry Bridge on 2/23/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFCategoryConstants.h"

@implementation DFCategoryConstants

+ (NSArray *)defaultCategoryNames
{

  return @[@"Document",
           @"Receipt",
           @"Buy",
           @"Clothing",
           ];
}

+ (UIImage *)gridIconForCategory:(NSString *)name
{
  NSString *imagePath = [NSString stringWithFormat:@"Assets/Icons/%@GridIcon", name];
  UIImage *image = [UIImage imageNamed:imagePath];
  return image ? image : [self defaultGridIcon];
}

+ (UIImage *)defaultGridIcon
{
  return [self gridIconForCategory:@"Tag"];
}

@end
