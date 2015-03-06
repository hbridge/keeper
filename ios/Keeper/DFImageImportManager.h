//
//  DFImageImportManager.h
//  Keeper
//
//  Created by Henry Bridge on 3/5/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFImageImportManager : NSObject

+ (DFImageImportManager *)sharedManager;
- (void)importAssetsWithALAssetURLsToCategories:(NSDictionary *)assetURLsToCategories;
- (void)importAssetsWithIdentifiersToCategories:(NSDictionary *)assetsToCategories;
- (void)resumeImports;

@end
