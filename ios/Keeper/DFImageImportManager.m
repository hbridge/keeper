//
//  DFImageImportManager.m
//  Keeper
//
//  Created by Henry Bridge on 3/5/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFImageImportManager.h"
#import <Realm/Realm.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "DFImageDataHelper.h"
#import "DFImageManager.h"


@interface DFAssetImport : RLMObject
@property NSString *localIdentifier;
@property NSString *category;
@property BOOL imported;
@end
RLM_ARRAY_TYPE(DFAssetImport)
@implementation DFAssetImport
@end


@interface DFImageImportManager()

@property (atomic) BOOL isImportInProgress;

@end

@implementation DFImageImportManager

+ (DFImageImportManager *)sharedManager {
  static DFImageImportManager *defaultManager = nil;
  if (!defaultManager) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      defaultManager = [[super allocWithZone:nil] init];
    });
  }
  return defaultManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
  return [self sharedManager];
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    // migrate db if necessary
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:[self.class dbPath]
            withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
              if (oldSchemaVersion < 1) {
                // nothing to do, 1-2 just added the imported property
              }
            }];
  }
  return self;
}

- (void)importAssetsWithALAssetURLsToCategories:(NSDictionary *)assetURLsToCategories
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableDictionary *assetIdentifiersToCategories = [NSMutableDictionary new];
    for (NSURL *assetURL in assetURLsToCategories.allKeys) {
      PHAsset *asset = [[PHAsset fetchAssetsWithALAssetURLs:@[assetURL]
                                                         options:nil] firstObject];
      if (!asset.localIdentifier) continue;
      assetIdentifiersToCategories[asset.localIdentifier] = assetURLsToCategories[assetURL];
    }
    
    [self importAssetsWithIdentifiersToCategories:assetIdentifiersToCategories];
  });
}

- (void)importAssetsWithIdentifiersToCategories:(NSDictionary *)assetsToCategories
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    @autoreleasepool {
      RLMRealm *realm = [RLMRealm realmWithPath:[self.class dbPath]];
      
      for (NSString *localIdentifier in assetsToCategories.allKeys) {
        [realm beginWriteTransaction];
        RLMResults *results = [DFAssetImport objectsWhere:@"localIdentifier = %@", localIdentifier];
        if (results.count == 0) {
          DFAssetImport *assetImport = [DFAssetImport new];
          assetImport.localIdentifier = localIdentifier;
          assetImport.category = assetsToCategories[localIdentifier];
          assetImport.imported = NO;
          [realm addObject:assetImport];
        }
        [realm commitWriteTransaction];
      }
      
      [self resumeImports];
    }
  });
}

- (void)resumeImports
{
  DDLogInfo(@"%@ resumeImports", self.class);
  if (self.isImportInProgress) return;
  self.isImportInProgress = YES;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    @autoreleasepool {
      RLMRealm *realm = [RLMRealm realmWithPath:[self.class dbPath]];
      RLMResults *assetImports = [DFAssetImport objectsInRealm:realm where:@"imported = NO"];
      if (assetImports.count == 0) {
        self.isImportInProgress = NO;
        DDLogInfo(@"%@ nothing to import", self.class);
        return;
      }
      
      // translate the asset imports into one PHAsset fetch
      DDLogInfo(@"%@ importing %@ images", self.class, @(assetImports.count));
      NSMutableArray *localIdentifiers = [NSMutableArray new];
      for (DFAssetImport *assetImport in assetImports) {
        [localIdentifiers addObject:assetImport.localIdentifier];
      }
      
      // go through the assets and import the data
      PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:localIdentifiers options:nil];
      for (PHAsset *asset in assets) {
        DFAssetImport *assetImport = [self.class assetImportWithLocalIdentifier:asset.localIdentifier
                                                                      inResults:assetImports];
        DDLogInfo(@"%@ importing %@ with category: %@",
                  self.class,
                  assetImport.localIdentifier,
                  assetImport.category);
        
        PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
        requestOptions.synchronous = YES;
        [[PHImageManager defaultManager]
         requestImageDataForAsset:asset
         options:requestOptions
         resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
           NSDictionary *metadata = [DFImageDataHelper metadataForImageData:imageData];
           UIImage *image = [UIImage imageWithData:imageData];
           [[DFImageManager sharedManager] saveImage:image
                                            category:assetImport.category
                                        withMetadata:metadata];
         }];
        
        // mark the record as imported in the DB
        DDLogInfo(@"%@ imported: %@", self.class, assetImport.localIdentifier);
        [realm beginWriteTransaction];
        assetImport.imported = YES;
        [realm commitWriteTransaction];
      }
    }

    DDLogInfo(@"%@ imports complete", self.class);
    self.isImportInProgress = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
      [self resumeImports];
    });
  });
}

+ (DFAssetImport *)assetImportWithLocalIdentifier:(NSString *)localIdentifier
                                        inResults:(RLMResults *)assetImports
{
  for (DFAssetImport *assetImport in assetImports) {
    if ([assetImport.localIdentifier isEqual:localIdentifier]) return assetImport;
  }
  return nil;
}

+ (NSString *)dbPath
{
  NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  NSURL *dbURL = [documentsURL URLByAppendingPathComponent:@"ImageImportManager.realm"];
  return [dbURL path];
}


@end
