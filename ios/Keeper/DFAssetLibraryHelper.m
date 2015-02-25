//
//  DFAssetLibraryHelper.m
//  Keeper
//
//  Created by Henry Bridge on 2/25/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFAssetLibraryHelper.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "UIImage+DFHelpers.h"

@implementation DFAssetLibraryHelper

static ALAssetsLibrary *assetsLibrary;

+ (void)saveImageToCameraRoll:(UIImage *)image
                 withMetadata:(NSDictionary *)metadata
                   completion:(void(^)(NSURL *assetURL, NSError *error))completion
{
  NSMutableDictionary *mutableMetadata = metadata.mutableCopy;
  [self addOrientationToMetadata:mutableMetadata forImage:image];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self.assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage
                                            metadata:mutableMetadata
                                     completionBlock:^(NSURL *assetURL, NSError *error) {
                                       if (error) {
                                         DDLogError(@"%@ couldn't save photo to Camera Roll:%@",
                                                    [self.class description],
                                                    error.description);
                                       } else {
                                         [self addAssetWithURL:assetURL toPhotoAlbum:@"Keeper"];
                                       }
                                       if (completion) completion(assetURL, error);
                                     }];
  });
}

+ (void)addOrientationToMetadata:(NSMutableDictionary *)metadata forImage:(UIImage *)image
{
  metadata[@"Orientation"] = @([image CGImageOrientation]);
}

+ (ALAssetsLibrary *)assetsLibrary
{
  if (!assetsLibrary) {
    assetsLibrary = [[ALAssetsLibrary alloc] init];
  }
  return assetsLibrary;
}

/*
 * Add image to a custom photo album
 * Iterates through all the users's groups looking for the correct album, if it doesn't exist, it gets created.
 */
+ (void) addAssetWithURL:(NSURL *) assetURL toPhotoAlbum:(NSString *) albumName
{
  [self.assetsLibrary assetForURL:assetURL
                      resultBlock:^(ALAsset *asset)
   {
     __block BOOL found = NO;
     [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop)
      {
        NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
        if ([albumName isEqualToString:groupName])
        {
          [group addAsset:asset];
          found = YES;
        }
      } failureBlock:^(NSError *error)
      {
        DDLogError(@"Error looping over albums: %@, %@", error, error.userInfo);
      }];
     
     if (!found) {
       [self.assetsLibrary addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group){
         [group addAsset:asset];
       } failureBlock:^(NSError *error) {
         DDLogError(@"Error creating custom Strand album: %@, %@", error, error.userInfo);
       }];
     }
     
   } failureBlock:^(NSError *error)
   {
   }];
}

@end
