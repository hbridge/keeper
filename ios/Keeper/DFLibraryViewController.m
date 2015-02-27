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
#import "DFAnalytics.h"
#import "DFSettingsManager.h"

@interface DFLibraryViewController ()

@property (nonatomic, retain) NSArray *allPhotos;
@property (nonatomic, retain) NSString *categoryFilter;
@property (nonatomic, retain) DFCategorizeController *categorizeController;

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

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [DFAnalytics logViewController:self appearedWithParameters:nil];
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
        return [photo.category isEqual:self.categoryFilter];
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
                                       if ([[collectionView indexPathForCell:cell] isEqual:indexPath]) {
                                         // make sure we're setting the right image for the cell
                                         cell.imageView.image = image;
                                       }
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
  self.categorizeController = [[DFCategorizeController alloc] init];
  self.categorizeController.delegate = self;
  [self.categorizeController presentInViewController:self];
}

- (void)categorizeController:(DFCategorizeController *)cateogrizeController
       didFinishWithCategory:(NSString *)category
{
  [self dismissGridMenuAnimated:YES completion:nil];
  NSString *categoryToLog = category;
  if (category) {
    DFLibraryViewController *libraryVC = [[DFLibraryViewController alloc] init];
    libraryVC.categoryFilter = category;
    [self dismissGridMenuAnimated:YES completion:nil];
    [self.navigationController pushViewController:libraryVC animated:NO];
  } else {
    categoryToLog = @"cancelled";
  }
  
  [DFAnalytics logEvent:DFAnalyticsEventLibraryFiltered
         withParameters:@{@"category" : categoryToLog}];
}

- (void)settingsButtonPressed:(id)sender
{
  DFAlertController *alertController = [DFAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:DFAlertControllerStyleActionSheet];
  
  //logout
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Logout"
                              style:DFAlertActionStyleDestructive
                              handler:^(DFAlertAction *action) {
                                [DFLoginViewController logoutWithParentViewController:self];
                                abort();
                              }]];
  
  // Auto Save
  NSString *autoSaveString;
  NSString *autoSavePref = [DFSettingsManager objectForSetting:DFSettingAutoSaveToCameraRoll];
  NSString *opposteSettingValue;
  if ([autoSavePref isEqualToString:DFSettingValueYes]) {
    autoSaveString = @"Disable Save to Camera Roll";
    opposteSettingValue = DFSettingValueNo;
  } else {
    autoSaveString = @"Enable Save to Camera Roll";
    opposteSettingValue = DFSettingValueYes;
  }
  [alertController addAction:[DFAlertAction
                              actionWithTitle:autoSaveString
                              style:DFAlertActionStyleDefault
                              handler:^(DFAlertAction *action) {
                                [DFSettingsManager setObject:opposteSettingValue
                                                  forSetting:DFSettingAutoSaveToCameraRoll];
                              }]];
  
  // Edit categories
  [alertController addAction:[DFAlertAction
                              actionWithTitle:@"Edit Category Speed Dial"
                              style:DFAlertActionStyleDefault
                              handler:^(DFAlertAction *action) {
                                self.categorizeController = [[DFCategorizeController alloc] init];
                                self.categorizeController.isEditModeEnabled = YES;
                                [self.categorizeController presentInViewController:self];
                              }]];
  
  // Cancel
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
  [DFAnalytics logEvent:DFAnalyticsEventLibraryPhotoTapped
         withParameters:@{@"categoryFilter" : self.categoryFilter ? self.categoryFilter : @"none"}];
}


@end
