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
           @"Architecture",
           @"Card",
           @"Note",
           @"Art",
           @"Buy",
           @"Clothing",
           @"Gadget",
           ];
}

+ (UIImage *)gridIconForCategory:(NSString *)name
{
  NSString *imagePath = [NSString stringWithFormat:@"Assets/Icons/%@GridIcon", name];
  return[UIImage imageNamed:imagePath];
}

+ (UIImage *)defaultGridIcon
{
  return [self gridIconForCategory:@"Tag"];
}

@end
