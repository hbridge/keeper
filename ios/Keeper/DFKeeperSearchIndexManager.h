//
//  DFKeeperSearchIndexManager.h
//  Keeper
//
//  Created by Henry Bridge on 3/6/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFKeeperSearchResult.h"

@interface DFKeeperSearchIndexManager : NSObject

+ (DFKeeperSearchIndexManager *)sharedManager;
- (void)keysMatchingSearch:(NSString *)searchString completion:(void(^)(NSArray *results))completion;
- (void)resumeIndexing;
- (void)deleteIndexedDocumentForObject:(NSString *)objectKey;
- (void)resetIndex;

@end
