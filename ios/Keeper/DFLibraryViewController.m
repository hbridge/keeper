//
//  DFLibraryViewController.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFLibraryViewController.h"
#import "DFUIKit.h"
#import "DFRootViewController.h"
#import "DFKeeperStore.h"

@interface DFLibraryViewController ()

@property (nonatomic, retain) NSArray *allPhotos;

@end

@implementation DFLibraryViewController

- (instancetype)init
{
  self = [super init];
  if (self) {
    [self observeNotifications];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self configureNav];
  [self configureCollectionView];
}

- (void)observeNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reloadData)
                                               name:DFPhotosChangedNotification
                                             object:nil];

}

- (void)configureNav
{
  self.navigationItem.title = @"Library";
  self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc]
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                               target:self
                                               action:@selector(addButtonPressed:)]];
}

- (void)configureCollectionView
{
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  [self.collectionView registerNib:[UINib nibForClass:[DFImageCollectionViewCell class]]
        forCellWithReuseIdentifier:@"cell"];
  [self reloadData];
}


- (void)reloadData
{
  dispatch_async(dispatch_get_main_queue(), ^{
    self.allPhotos = [[DFKeeperStore sharedStore] photos];
    [self.collectionView reloadData];
  });
}

#pragma mark - UICollectionView Datasource/Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return self.allPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  DFImageCollectionViewCell *cell = [self.collectionView
                                     dequeueReusableCellWithReuseIdentifier:@"cell"
                                     forIndexPath:indexPath];
  
  DFKeeperPhoto *photo = [self.allPhotos objectAtIndex:indexPath.row];
  cell.imageView.image = photo.image;
  
  return cell;
}


#pragma mark - Action Handlers

- (void)addButtonPressed:(id)sender
{
  [[DFRootViewController rootViewController] showCamera];
}


@end
