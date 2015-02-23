//
//  DFImageStore.m
//  Strand
//
//  Created by Henry Bridge on 7/20/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "DFImageDiskCache.h"

#import <FMDB/FMDB.h>
#import "DFTypedefs.h"
#import "DFImageDownloadManager.h"
#import "DFPhotoResizer.h"
#import "DFImageManager.h"

@interface DFImageDiskCache()

@property (nonatomic, readonly, retain) FMDatabase *db;
@property (nonatomic, readonly, retain) FMDatabaseQueue *dbQueue;
@property (atomic, retain) NSMutableDictionary *idsByImageTypeCache;

@end

@implementation DFImageDiskCache

@synthesize db = _db;

static DFImageDiskCache *defaultStore;

+ (DFImageDiskCache *)sharedStore {
  if (!defaultStore) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      defaultStore = [[super allocWithZone:nil] init];
    });
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
    [DFImageDiskCache createCacheDirectories];
    [self initDB];
    [self loadDownloadedImagesCache];
    [self integrityCheck];
  }
  return self;
}

- (void)initDB
{
  _db = [FMDatabase databaseWithPath:[self.class dbPath]];
  
  if (![_db open]) {
    DDLogError(@"Error opening downloadedImages database, error code: %d", [_db lastErrorCode]);
    _db = nil;
  }
  if (![_db tableExists:@"downloadedImages"]) {
    [_db executeUpdate:@"CREATE TABLE downloadedImages (image_type NUMBER, photo_key STRING)"];
  }
  
  _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self.class dbPath]];
}

+ (NSString *)dbPath
{
  NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  NSURL *dbURL = [documentsURL URLByAppendingPathComponent:@"downloaded_images.db"];
  return [dbURL path];
}


- (NSMutableSet *)keysFromDBForType:(DFImageType)type
{
  FMResultSet *results = [self.db executeQuery:@"SELECT photo_key FROM downloadedImages WHERE image_type=(?)", @(type)];
  NSMutableSet *resultIDs = [NSMutableSet new];
  while ([results next]) {
    [resultIDs addObject:[results stringForColumn:@"photo_key"]];
  }
  return resultIDs;
}

- (BOOL)isImageTypeCached:(DFImageType)type forKey:(NSString *)imageKey
{
  NSSet *ids = [self keysFromDBForType:type];
  return [ids containsObject:imageKey];
}

- (void)addToDBImageForType:(DFImageType)type forKey:(NSString *)key
{
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"INSERT INTO downloadedImages VALUES (?, ?)",
     @(type),
     key];
    DDLogInfo(@"%@ setting cached photo %@ type:%@", self.class,
              key,
              type == DFImageFull ? @"full" : @"thumbnail");
  }];
}

- (NSMutableSet *)cachedImageKeysForType:(DFImageType)type
{
  return self.idsByImageTypeCache[@(type)];
}

- (void)loadDownloadedImagesCache
{
  _idsByImageTypeCache = [NSMutableDictionary new];
  
  NSMutableSet *imageKeys = [self keysFromDBForType:DFImageThumbnail];
  [self.idsByImageTypeCache setObject:imageKeys forKey:@(DFImageThumbnail)];
  
  imageKeys = [self keysFromDBForType:DFImageFull];
  [self.idsByImageTypeCache setObject:imageKeys forKey:@(DFImageFull)];
}

- (void)integrityCheck
{
  NSError *error;
  NSArray *thumnbailFiles = [[NSFileManager defaultManager]
                             contentsOfDirectoryAtURL:[DFImageDiskCache localThumbnailsDirectoryURL]
                             includingPropertiesForKeys:nil
                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                             error:&error];
  NSArray *fullFiles = [[NSFileManager defaultManager]
                        contentsOfDirectoryAtURL:[DFImageDiskCache localFullImagesDirectoryURL]
                        includingPropertiesForKeys:nil
                        options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                        error:&error];
  NSSet *thumbnailsInDB = self.idsByImageTypeCache[@(DFImageThumbnail)];
  NSSet *fullsInDB = self.idsByImageTypeCache[@(DFImageFull)];
  
  DDLogInfo(@"%@ thumbnailFiles: %@ thumbnailsInDB: %@ fullFiles: %@ fulsInDB: %@",
            self.class, @(thumnbailFiles.count), @(thumbnailsInDB.count), @(fullFiles.count), @(fullsInDB.count));
  
  if (thumbnailsInDB.count != thumnbailFiles.count
      || fullsInDB.count != fullFiles.count) {
    DDLogWarn(@"%@ count mismatch. Clearing disk cache.", self.class);
    [self clearCache];
  }
  
}

- (void)setImage:(UIImage *)image
            type:(DFImageType)type
           forKey:(NSString *)key
      completion:(SetImageCompletion)completion
{
  NSURL *url = [DFImageDiskCache localURLForPhotoKey:key type:type];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    @autoreleasepool {
      BOOL writeSuccessful = NO;
      NSData *data = UIImageJPEGRepresentation(image, 0.75);
      if (data) {
        writeSuccessful = [data writeToURL:url atomically:YES];
      }
      
      if (writeSuccessful) {
        // Record that we've written this file out
        NSMutableSet *photoKeys = self.idsByImageTypeCache[@(type)];
        [photoKeys addObject:key];
        [self addToDBImageForType:type forKey:key];
        if (completion) completion(nil);
      } else {
        NSString *description = [NSString stringWithFormat:@"%@ writing %@ bytes failed.",
                                       self.class,
                                       @(data.length)];
        if (completion) completion([NSError errorWithDomain:@"com.duffyapp.strand"
                                                       code:-1030
                                                   userInfo:@{NSLocalizedDescriptionKey : description}]);
      }
    }
  });
}

- (void)imageForKey:(NSString *)key
     preferredType:(DFImageType)type
        completion:(ImageLoadCompletionBlock)completionBlock
{
  NSURL *localUrl = [DFImageDiskCache localURLForPhotoKey:key type:type];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    @autoreleasepool {
      NSData *imageData = [NSData dataWithContentsOfURL:localUrl];
      if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        completionBlock(image);
      } else {
        completionBlock(nil);
      }
    }
  });
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
+ (NSURL *)applicationDocumentsDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (void)createCacheDirectories
{
  NSFileManager *fm = [NSFileManager defaultManager];
  
  NSArray *directoriesToCreate = @[[[self localThumbnailsDirectoryURL] path],
                                   [[self localFullImagesDirectoryURL] path]];
  
  for (NSString *path in directoriesToCreate) {
    if (![fm fileExistsAtPath:path]) {
      NSError *error;
      [fm createDirectoryAtPath:path withIntermediateDirectories:NO
                     attributes:nil
                          error:&error];
      if (error) {
        DDLogError(@"Error creating cache directory: %@, error: %@", path, error.description);
        abort();
      }
    }
    
  }
}

#pragma mark - File Paths


+ (NSURL *)localURLForPhotoKey:(NSString *)key type:(DFImageType)type
{
  if (![key isNotEmpty]) return nil;
  // if we have an actual photo id, that's used in the path
  NSString *filename;
  filename = [NSString stringWithFormat:@"%@.jpg", key];

  if (type == DFImageFull) {
    return [[DFImageDiskCache localFullImagesDirectoryURL] URLByAppendingPathComponent:filename];
  } else if (type == DFImageThumbnail) {
    return [[DFImageDiskCache localThumbnailsDirectoryURL] URLByAppendingPathComponent:filename];
  }
  
  return nil;
}


+ (NSURL *)userLibraryURL
{
  NSArray* paths = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
  
  if ([paths count] > 0)
  {
    return [paths objectAtIndex:0];
  }
  return nil;
}

+ (NSURL *)localFullImagesDirectoryURL
{
  return [[self userLibraryURL] URLByAppendingPathComponent:@"fullsize"];
}

+ (NSURL *)localThumbnailsDirectoryURL
{
  return [[self userLibraryURL] URLByAppendingPathComponent:@"thumbnails"];
}

- (NSError *)clearCache
{
  NSFileManager *fm = [NSFileManager defaultManager];
  
  NSArray *directoriesToDeleteAndCreate = @[[[self.class localThumbnailsDirectoryURL] path],
                                   [[self.class localFullImagesDirectoryURL] path]];
  
  // delete the cache directories
  for (NSString *path in directoriesToDeleteAndCreate) {
    if ([fm fileExistsAtPath:path]) {
      NSError *error;
      [fm removeItemAtPath:path error:&error];
      DDLogInfo(@"%@ deleting: %@", self.class, path.lastPathComponent);
      if (error) {
        DDLogError(@"Error deleting cache directory: %@, error: %@", path, error.description);
        return error;
      }
    }
  }

  // clear the DB table
  if ([self.db tableExists:@"downloadedImages"]) {
    DDLogInfo(@"%@ clearing all rows from downloadedImagesTable", self.class);
    //[self.db executeUpdate:@"DELETE FROM downloadedImages"];
    [self.db executeUpdate:@"DROP TABLE downloadedImages"];
  }
  
  
  [self.class createCacheDirectories];
  [self initDB];
  [self loadDownloadedImagesCache];
  [[DFImageManager sharedManager] clearCache];
  
  return nil;
}

#pragma mark - Image Manager Request Servicing


- (BOOL)canServeRequest:(DFImageManagerRequest *)request
{
  NSSet *imageIDsForType = [self cachedImageKeysForType:[request imageType]];
  return [imageIDsForType containsObject:request.key];
}

- (UIImage *)serveImageForRequest:(DFImageManagerRequest *)request
{
  NSURL *url = [self.class localURLForPhotoKey:request.key type:request.imageType];
  if (request.isDefaultThumbnail) {
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    if (imageData) {
      UIImage *image = [UIImage imageWithData:imageData];
      return image;
    }
  }
  DFPhotoResizer *resizer = [[DFPhotoResizer alloc] initWithURL:url];
  if (request.contentMode == DFImageRequestContentModeAspectFit) {
    CGFloat largerDimension = MAX(request.size.width, request.size.height);
    return [resizer aspectImageWithMaxPixelSize:largerDimension];
  } else if (request.contentMode == DFImageRequestContentModeAspectFill) {
    return [resizer aspectFilledImageWithSize:request.size];
  }
  
  return nil;
}

- (UIImage *)fullImageForKey:(NSString *)key
{
  NSURL *url = [self.class localURLForPhotoKey:key type:DFImageFull];
  NSData *imageData = [NSData dataWithContentsOfURL:url];
  return [UIImage imageWithData:imageData];
}

@end
