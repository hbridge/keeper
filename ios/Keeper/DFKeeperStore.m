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

- (void)deletePhoto:(DFKeeperPhoto *)photo
{
  Firebase *photoRef = [self.photosRef childByAppendingPath:photo.key];
  [photoRef setValue:nil];
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
   observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
     NSMutableArray *photos = [NSMutableArray new];
     for (FDataSnapshot *photoSnapshot in snapshot.children) {
       DFKeeperPhoto *photo = [[DFKeeperPhoto alloc] initWithSnapshot:photoSnapshot];
       [photos addObject:photo];
     }
     
     completion(photos);
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



@end
