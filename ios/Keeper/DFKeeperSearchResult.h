//
//  DFKeeperSearchResult.h
//  Keeper
//
//  Created by Henry Bridge on 3/9/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFKeeperSearchResult : NSObject

@property (nonatomic, retain) NSString *objectKey;
@property (nonatomic, retain) NSString *documentString;

- (NSAttributedString *)attributedSnippetForSearch:(NSString *)searchString baseFont:(UIFont *)baseFont;

@end
