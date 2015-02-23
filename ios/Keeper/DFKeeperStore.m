//
//  DFKeeperStore.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperStore.h"
#import "DFUser.h"

@interface DFKeeperStore()

@property (nonatomic, retain) Firebase *baseRef;
@property (nonatomic, retain) Firebase *photosRef;
@property (nonatomic, retain) Firebase *imageDataRef;
@property (nonatomic, retain) NSMutableArray *allPhotos;

@end

@implementation DFKeeperStore

+ (DFKeeperStore *)sharedStore {
  static DFKeeperStore *defaultStore = nil;
  if (!defaultStore) {
    defaultStore = [[super allocWithZone:nil] init];
  }
  return defaultStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
  return [self sharedStore];
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.baseRef = [[Firebase alloc] initWithUrl:DFFirebaseRootURLString];
    self.photosRef = [_baseRef childByAppendingPath:@"photos"];
    self.imageDataRef = [_baseRef childByAppendingPath:@"imageData"];
  }
  return self;
}

- (void)savePhoto:(DFKeeperPhoto *)photo
{
  NSMutableDictionary *photoDict = photo.dictionary.mutableCopy;

  Firebase *photoRef;
  if ([photo.key isNotEmpty]) {
    photoRef = [self.photosRef childByAppendingPath:photo.key];
  } else {
    photoRef = [self.photosRef childByAutoId];
    photo.key = photoRef.key;
  }
  [photoRef setValue:photoDict];
}

- (NSArray *)photos
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    self.allPhotos = [NSMutableArray new];
    [[self.photosRef queryOrderedByChild:@"saveDate"] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
      DFKeeperPhoto *keeperPhoto = [[DFKeeperPhoto alloc] initWithSnapshot:snapshot];
      [self.allPhotos addObject:keeperPhoto];
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DFPhotosChangedNotification
                                                            object:self];
      });
    }];
    [[self.photosRef queryOrderedByKey] observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
      for (NSUInteger i = 0; i < self.allPhotos.count; i++) {
        DFKeeperPhoto *photo = self.allPhotos[i];
        if ([photo.key isEqual:snapshot.key]) {
          DFKeeperPhoto *newPhoto = [[DFKeeperPhoto alloc] initWithSnapshot:snapshot];
          [self.allPhotos replaceObjectAtIndex:i withObject:newPhoto];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:DFPhotosChangedNotification
                                                            object:self];
      }
    }];

  });
  return [self.allPhotos copy];
}


- (void)storeImage:(DFKeeperImage *)image forPhoto:(DFKeeperPhoto *)photo
{
  // create the image
  image.user = [DFUser loggedInUser];
  NSMutableDictionary *imageDict = image.dictionary.mutableCopy;
  Firebase *imageRef = [self.imageDataRef childByAutoId];
  [imageRef setValue:imageDict];
  image.key = imageRef.key;
  
  photo.imageKey = image.key;
  [self savePhoto:photo];
}



@end
