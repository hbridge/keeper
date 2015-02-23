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
#import "DFKeeperPhotoViewController.h"
#import "DFCategoryConstants.h"

@interface DFLibraryViewController ()

@property (nonatomic, retain) NSArray *allPhotos;
@property (nonatomic, retain) NSString *categoryFilter;

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
  if (self.categoryFilter) {
    self.navigationItem.title = self.categoryFilter;
  } else {
    self.navigationItem.title = @"Library";
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
    if ([self.categoryFilter isNotEmpty]) {
      self.allPhotos = [self.allPhotos objectsPassingTestBlock:^BOOL(DFKeeperPhoto *photo) {
        return [photo.text isEqual:self.categoryFilter];
      }];
    }
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
  NSArray *items =
  [[DFCategoryConstants defaultCategoryNames] arrayByMappingObjectsWithBlock:^id(NSString *title) {
    CNPGridMenuItem *item = [CNPGridMenuItem new];
    item.title = title;
    item.icon = [DFCategoryConstants gridIconForCategory:title];
    return item;
  }];
  CNPGridMenu *gridMenu = [[CNPGridMenu alloc] initWithMenuItems:items];
  
  gridMenu.delegate = self;
  [self presentGridMenu:gridMenu animated:YES completion:nil];
}

- (void)gridMenuDidTapOnBackground:(CNPGridMenu *)menu
{
  [self dismissGridMenuAnimated:YES completion:nil];
}

- (void)gridMenu:(CNPGridMenu *)menu didTapOnItem:(CNPGridMenuItem *)item
{
  NSString *category = item.title;
  DFLibraryViewController *libraryVC = [[DFLibraryViewController alloc] init];
  libraryVC.categoryFilter = category;
  [self dismissGridMenuAnimated:YES completion:nil];
  [self.navigationController pushViewController:libraryVC animated:NO];
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  DFKeeperPhotoViewController *pvc = [[DFKeeperPhotoViewController alloc] init];
  pvc.photo = self.allPhotos[indexPath.row];
  [self.navigationController pushViewController:pvc animated:YES];
}


@end
