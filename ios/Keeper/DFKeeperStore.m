//
//  DFKeeperStore.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperStore.h"

@interface DFKeeperStore()

@property (nonatomic, retain) Firebase *baseRef;
@property (nonatomic, retain) Firebase *photosRef;
@property (nonatomic, retain) NSString *user;
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
    self.baseRef = [[Firebase alloc] initWithUrl:@"https://blazing-heat-8620.firebaseio.com"];
    self.photosRef = [_baseRef childByAppendingPath:@"photos"];
    [self login];
  }
  return self;
}

- (void)login
{
  self.user = @"hbridge@gmail.com";
  [self.photosRef authUser:self.user password:@"duffyhenry"
       withCompletionBlock:^(NSError *error, FAuthData *authData) {
         if (error) {
           DDLogVerbose(@"%@ auth error: %@", self.class, error);
         } else {
           DDLogVerbose(@"%@ user authed authData:%@", self.class, authData);
         }
       }];
}

- (void)storePhoto:(DFKeeperPhoto *)photo
{
  photo.user = self.user;
  photo.saveDate = [NSDate date];
  NSMutableDictionary *photoDict = photo.dictionary.mutableCopy;
  Firebase *photoRef = [self.photosRef childByAutoId];
  [photoRef setValue:photoDict];
  photo.key = photoRef.key;
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
  });
  return [self.allPhotos copy];
}




@end
