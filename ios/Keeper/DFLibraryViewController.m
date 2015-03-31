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
#import "DFAssetLibraryHelper.h"
#import "DFSettingsViewController.h"
#import "DFSettingsManager.h"
#import <Photos/Photos.h>
#import "DFImageImportManager.h"
#import "DFCameraRollScanManager.h"
#import "UIImage+DFHelpers.h"

@interface DFLibraryViewController ()

@property (nonatomic, retain) NSArray *allPhotos;
@property (nonatomic, retain) NSString *categoryFilter;
@property (nonatomic, retain) DFCategorizeController *categorizeController;
@property (nonatomic, retain) NSURL *lastPickedAssetURL;
@property (nonatomic, retain) DFKeeperSearchController *searchController;

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
  [self configureSearch];
  
  self.searchBar.backgroundImage = [UIImage imageWithColor:[DFKeeperConstants BarBackgroundColor]];
  self.searchBar.tintColor = [UIColor whiteColor];
  
  UIFont *labelFont = [DFKeeperConstants LabelFont];
  [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setFont:labelFont];
  [[UILabel appearanceWhenContainedIn:[UITableView class], nil] setFont:labelFont];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (![self.categoryFilter isNotEmpty])
    [self setAutomaticallyAdjustTableViewFrameOnKeyboardChange:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self upsellScreenshotAutoImport];
    [DFAnalytics logViewController:self appearedWithParameters:nil];
}

- (void)upsellScreenshotAutoImport
{
  if (![DFSettingsManager objectForSetting:DFSettingAutoImportScreenshots]
      && [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
    DFAlertController *promptForAutoImport =
    [DFAlertController
     alertControllerWithTitle:@"Import Screenshots"
     message:@"Would you like Keeper to automatically import any screenshots you take in the future?"
     preferredStyle:DFAlertControllerStyleAlert];
    [promptForAutoImport addAction:[DFAlertAction
                                    actionWithTitle:@"Not Now"
                                    style:DFAlertActionStyleCancel
                                    handler:^(DFAlertAction *action) {
                                      [DFSettingsManager setAutoImportScreenshotsEnabled:NO];
                                    }]];
    [promptForAutoImport addAction:[DFAlertAction
                                    actionWithTitle:@"Yes"
                                    style:DFAlertActionStyleDefault
                                    handler:^(DFAlertAction *action) {
                                      [DFSettingsManager setAutoImportScreenshotsEnabled:YES];
                                      // our first scan should ignore new screenshots
                                      [[DFCameraRollScanManager sharedManager]
                                       scanWithMode:DFCameraRollScanModeIgnoreNewScreenshots
                                       promptForAccess:YES];
                                    }]];
    [promptForAutoImport showWithParentViewController:self animated:YES completion:nil];
  }
  
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self setAutomaticallyAdjustTableViewFrameOnKeyboardChange:NO];
}


- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  CGFloat itemWidth = [DFKeeperConstants DefaultThumbnailSize];
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
    self.navigationItem.title = @"Keeper";
    self.navigationItem.leftBarButtonItems = @[
                                               [[UIBarButtonItem alloc]
                                                initWithImage:[UIImage imageNamed:@"Assets/Icons/SettingsBarButton"]
                                                style:UIBarButtonItemStylePlain
                                                target:self
                                                action:@selector(settingsButtonPressed:)],
                                               ];

  }

  self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc]
                                               initWithImage:[UIImage imageNamed:@"Assets/Icons/CameraBarButton"]
                                               style:UIBarButtonItemStylePlain
                                               target:self
                                               action:@selector(cameraButtonPressed:)],
                                              [[UIBarButtonItem alloc]
                                               initWithImage:[UIImage imageNamed:@"Assets/Icons/CameraRollBarButton"]
                                               style:UIBarButtonItemStylePlain
                                               target:self
                                               action:@selector(addButtonPressed:)],
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

- (void)configureSearch
{
  if ([self.categoryFilter isNotEmpty]) {
    [self.searchBar removeFromSuperview];
  } else {
    self.searchController = [[DFKeeperSearchController alloc] init];
    self.searchController.searchBar = self.searchBar;
    self.searchController.tableView = self.tableView;
    self.searchController.delegate = self;
  }
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
    self.noPhotosLabel.hidden = (self.allPhotos.count > 0);
  });
}

- (void)setNoPhotosVisible:(BOOL)visible
{
  
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
  UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
  imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  imagePickerController.editing = NO;
  imagePickerController.delegate = self;
  [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  self.lastPickedAssetURL = info[UIImagePickerControllerReferenceURL];
  self.categorizeController = [[DFCategorizeController alloc] init];
  self.categorizeController.delegate = self;
  [self.categorizeController presentInViewController:picker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [self dismissViewControllerAnimated:YES completion:nil];
  self.lastPickedAssetURL = nil;
}

- (void)cameraButtonPressed:(id)sender
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
  if (category) {
    if (self.lastPickedAssetURL) {
      [[DFImageImportManager sharedManager]
       importAssetsWithALAssetURLsToCategories:@{
                                                 self.lastPickedAssetURL : category
                                                 }];
      self.lastPickedAssetURL = nil;
      [DFAnalytics logEvent:DFAnalyticsEventPhotoImported
             withParameters:@{@"category" : category}];
    }
  }
}

- (void)settingsButtonPressed:(id)sender
{
  [DFSettingsViewController presentInViewController:self];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  DFKeeperPhotoViewController *pvc = [[DFKeeperPhotoViewController alloc] init];
  pvc.photo = self.allPhotos[indexPath.row];
  [self.navigationController pushViewController:pvc animated:YES];
  [DFAnalytics logEvent:DFAnalyticsEventLibraryPhotoTapped
         withParameters:@{@"categoryFilter" : self.categoryFilter ? self.categoryFilter : @"none"}];
}

#pragma mark - Search Delegate

- (void)searchControllerDidCancel:(DFKeeperSearchController *)searchController
{
  
}

- (void)searchController:(DFKeeperSearchController *)searchController
      completedWithQuery:(NSString *)query
                 results:(NSArray *)keeperPhotos
{
  DFLibraryViewController *libraryVC = [[DFLibraryViewController alloc] init];
  libraryVC.categoryFilter = query;
  [self.navigationController pushViewController:libraryVC animated:YES];
  [DFAnalytics logEvent:DFAnalyticsEventLibraryFiltered
         withParameters:@{@"category" : query}];
}

- (void)searchController:(DFKeeperSearchController *)searchController
      completedWithQuery:(NSString *)query
              selectedId:(NSString *)objectIdentifier
{
  DFKeeperPhotoViewController *pvc = [[DFKeeperPhotoViewController alloc] init];
  pvc.photo = [[DFKeeperStore sharedStore] photoWithKey:objectIdentifier];
  [self.navigationController pushViewController:pvc animated:YES];
  [DFAnalytics logEvent:DFAnalyticsEventLibraryPhotoTapped
         withParameters:@{@"searchQuery" : query ? query : @""}];
}


@end
