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
@property (nonatomic, retain) NSMutableSet *categorySet;

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
    self.categorySet = [NSMutableSet new];
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

- (void)saveImage:(DFKeeperImage *)image
{
  Firebase *imageRef = self.imageDataRef;
  if ([image.key isNotEmpty]) {
    imageRef = [self.imageDataRef childByAppendingPath:image.key];
  } else {
    imageRef = [self.imageDataRef childByAutoId];
    image.key = imageRef.key;
  }
  
  [imageRef setValue:[image dictionary]];
}

- (void)deletePhoto:(DFKeeperPhoto *)photo
{
  Firebase *photoRef = [self.photosRef childByAppendingPath:photo.key];
  Firebase *imageRef = [self.imageDataRef childByAppendingPath:photo.imageKey];
  [photoRef setValue:nil];
  [imageRef setValue:nil];
}

- (NSArray *)photos
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    self.allPhotos = [NSMutableArray new];
    [[[self.photosRef queryOrderedByChild:@"user"]
      queryEqualToValue:[DFUser loggedInUser]]
     observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
       DFKeeperPhoto *keeperPhoto = [[DFKeeperPhoto alloc] initWithSnapshot:snapshot];
       
       // keep track of the category
       [self.categorySet addObject:keeperPhoto.category];
       
       // add the photo at the right spot in the array
       BOOL inserted = NO;
       for (NSUInteger i = 0; i < self.allPhotos.count; i++) {
         if ([keeperPhoto.saveDate timeIntervalSinceDate:[self.allPhotos[i] saveDate]] >= 0) {
           [self.allPhotos insertObject:keeperPhoto atIndex:i];
           inserted = YES;
           break;
         }
       }
       if (!inserted)
         [self.allPhotos addObject:keeperPhoto];
       dispatch_async(dispatch_get_main_queue(), ^{
         [[NSNotificationCenter defaultCenter] postNotificationName:DFPhotosChangedNotification
                                                             object:self];
       });
     }];
    [[self.photosRef queryOrderedByKey] observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
      NSUInteger photoIndex = [self indexOfPhotoWithKey:snapshot.key];
      if (photoIndex != NSNotFound) {
        DFKeeperPhoto *newPhoto = [[DFKeeperPhoto alloc] initWithSnapshot:snapshot];
        [self.categorySet addObject:newPhoto.category];
        [self.allPhotos replaceObjectAtIndex:photoIndex withObject:newPhoto];
        [[NSNotificationCenter defaultCenter] postNotificationName:DFPhotosChangedNotification
                                                            object:self];
      }
    }];
    [[self.photosRef queryOrderedByKey] observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
      NSUInteger photoIndex = [self indexOfPhotoWithKey:snapshot.key];
      if (photoIndex != NSNotFound) {
        [self.allPhotos removeObjectAtIndex:photoIndex];
        [[NSNotificationCenter defaultCenter] postNotificationName:DFPhotosChangedNotification
                                                            object:self];
      }
    }];
    
  });
  return [self.allPhotos copy];
}

- (void)fetchPhotosWithCompletion:(void (^)(NSArray *))completion
{
  [[[self.photosRef queryOrderedByChild:@"user"]
    queryEqualToValue:[DFUser loggedInUser]]
   observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
     NSMutableArray *photos = [NSMutableArray new];
     for (FDataSnapshot *photoSnapshot in snapshot.children) {
       DFKeeperPhoto *photo = [[DFKeeperPhoto alloc] initWithSnapshot:photoSnapshot];
       [photos addObject:photo];
     }
     
     completion(photos);
   }];
}

- (void)fetchImagesWithCompletion:(void (^)(NSArray *images))completion
{
  [[[self.imageDataRef queryOrderedByChild:@"user"]
    queryEqualToValue:[DFUser loggedInUser]]
   observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
     NSMutableArray *images = [NSMutableArray new];
     for (FDataSnapshot *photoSnapshot in snapshot.children) {
       DFKeeperImage *image = [[DFKeeperImage alloc] initWithSnapshot:photoSnapshot];
       [images addObject:image];
     }
     
     completion(images);
   }];
}

- (NSUInteger)indexOfPhotoWithKey:(NSString *)key
{
  for (NSUInteger i = 0; i < self.allPhotos.count; i++) {
    DFKeeperPhoto *photo = self.allPhotos[i];
    if ([photo.key isEqual:key]) {
      return i;
    }
  }
  return NSNotFound;
}

- (DFKeeperPhoto *)photoWithKey:(NSString *)key
{
  for (DFKeeperPhoto *photo in self.allPhotos) {
    if ([photo.key isEqual:key]) return photo;
  }
  return nil;
}

- (DFKeeperPhoto *)photoWithImageKey:(NSString *)imageKey
{
  for (DFKeeperPhoto *photo in self.allPhotos) {
    if ([photo.key isEqual:imageKey]
        || [photo.imageKey isEqual:imageKey]) return photo;
  }
  return nil;
}

- (void)fetchImageWithKey:(NSString *)key
                          completion:(void (^)(DFKeeperImage *image))completion
{
  Firebase *imageRef = [self.imageDataRef childByAppendingPath:key];
  [imageRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    completion([[DFKeeperImage alloc] initWithSnapshot:snapshot]);
  }];
}


- (NSArray *)allCategories
{
  NSArray *categoryArray = [[self.categorySet allObjects]
                            sortedArrayUsingComparator:^NSComparisonResult(NSString *cat1, NSString *cat2) {
                              return [cat1 compare:cat2];
  }];
  return categoryArray;
}

@end
