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
#import "DFLoginViewController.h"
#import "DFImageManager.h"

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

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  const CGFloat CellsPerRow = 3.0;
  CGFloat itemWidth = (self.view.frame.size.width / CellsPerRow) - (CellsPerRow - 1.0);
  CGSize itemSize = CGSizeMake(itemWidth, itemWidth);
  if (!CGSizeEqualToSize(itemSize, self.flowLayout.itemSize)) {
    self.flowLayout.itemSize = itemSize;
    [self.flowLayout invalidateLayout];
  }
  
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
  
  self.navigationItem.leftBarButtonItems = @[
                                             [[UIBarButtonItem alloc]
                                              initWithImage:[UIImage imageNamed:@"Assets/Icons/FilterBarButton"]
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(filterButtonPressed:)],
                                             [[UIBarButtonItem alloc]
                                              initWithImage:[UIImage imageNamed:@"Assets/Icons/SettingsBarButton"]
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(settingsButtonPressed:)],
                                             ];
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
  [[DFImageManager sharedManager] imageForKey:photo.imageKey
                                    pointSize:self.flowLayout.itemSize
                                  contentMode:DFImageRequestContentModeAspectFill
                                 deliveryMode:DFImageRequestOptionsDeliveryModeFastFormat
                                   completion:^(UIImage *image) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       cell.imageView.image = image;
                                     });
                                   }];
  
  return cell;
}


#pragma mark - Action Handlers

- (void)addButtonPressed:(id)sender
{
  [[DFRootViewController rootViewController] showCamera];
}

- (void)filterButtonPressed:(id)sender
{
  
}

- (void)settingsButtonPressed:(id)sender
{
  DFAlertController *alertController = [DFAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:DFAlertControllerStyleActionSheet];
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Logout"
                              style:DFAlertActionStyleDestructive
                              handler:^(DFAlertAction *action) {
                                [DFLoginViewController logoutWithParentViewController:self];
                                abort();
                              }]];
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Cancel"
                              style:DFAlertActionStyleCancel
                              handler:^(DFAlertAction *action) {
                              }]];
   [alertController showWithParentViewController:self animated:YES completion:nil];
}


@end
