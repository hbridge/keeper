//
//  DFKeeperPhotoViewController.m
//  Keeper
//
//  Created by Henry Bridge on 2/23/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperPhotoViewController.h"
#import "DFImageManager.h"
#import "DFCategoryConstants.h"
#import "UIImage+Resize.h"
#import "DFRootViewController.h"
#import "DFAnalytics.h"
#import "DFKeeperStore.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "DFUIKit.h"
#import "UIImage+DFHelpers.h"
#import "DFKeeperStore.h"
#import "DFKeeperPhotoInfoViewController.h"
#import "DFUserLoginManager.h"

@interface DFKeeperPhotoViewController ()

@property (nonatomic, retain) DFCategorizeController *categorizeController;

@end

@implementation DFKeeperPhotoViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self configureNav];
  
  if (self.photo)
    [self reloadData];
}

- (void)configureNav
{
  NSMutableArray *items = [NSMutableArray new];
  [items addObject:
   [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemAction
    target:self
    action:@selector(actionPressed:)]];
  if ([[DFUserLoginManager sharedManager] isLoggedInUserDeveloper]) {
    [items addObject:[[UIBarButtonItem alloc]
                      initWithImage:[UIImage imageNamed:@"Assets/Icons/InfoBarButton"]
                      style:UIBarButtonItemStylePlain
                      target:self
                      action:@selector(infoPressed:)]];
  }
  self.navigationItem.rightBarButtonItems = items;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [DFAnalytics logViewController:self appearedWithParameters:@{@"category" : NonNull(self.photo.category)}];
  [[DFRootViewController rootViewController] setSwipingEnabled:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[DFRootViewController rootViewController] setSwipingEnabled:YES];
}

- (void)setPhoto:(DFKeeperPhoto *)photo
{
  _photo = photo;
  if (self.imageView) {
    [self reloadData];
  }
}

- (void)reloadData
{
  [[DFImageManager sharedManager]
   imageForKey:self.photo.imageKey
   pointSize:[[UIScreen mainScreen] bounds].size
   contentMode:DFImageRequestContentModeAspectFit
   deliveryMode:DFImageRequestOptionsDeliveryModeHighQualityFormat
   completion:^(UIImage *image) {
     dispatch_async(dispatch_get_main_queue(), ^{
       self.imageView.image = image;
     });
   }];
  
  [self reloadCategory];
}

- (void)reloadCategory
{
  UIImage *icon = [DFCategoryConstants gridIconForCategory:self.photo.category];
  if (!icon) icon = [DFCategoryConstants defaultGridIcon];
  UIImage *resizedIcon = [icon thumbnailImage:20
                            transparentBorder:0
                                  cornerRadius:0
                          interpolationQuality:kCGInterpolationDefault];

  [self.tagButton setImage:[resizedIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                  forState:UIControlStateNormal];
                          
  [self.tagButton setTitle:self.photo.category forState:UIControlStateNormal];
}

#pragma mark - Actions

- (IBAction)categoryButtonPressed:(id)sender {
  self.categorizeController = [DFCategorizeController new];
  self.categorizeController.delegate = self;
  [self.categorizeController presentInViewController:self];
}

- (void)categorizeController:(DFCategorizeController *)cateogrizeController didFinishWithCategory:(NSString *)category
{
  if (category) {
    self.photo.category = category;
    [[DFKeeperStore sharedStore] savePhoto:self.photo];
    [self reloadCategory];
  }
}

- (IBAction)deleteButtonPressed:(id)sender {
  DFAlertController *alertController = [DFAlertController
                                        alertControllerWithTitle:nil
                                        message:nil
                                        preferredStyle:DFAlertControllerStyleActionSheet];
  [alertController addAction:[DFAlertAction actionWithTitle:@"Cancel"
                                                      style:DFAlertActionStyleCancel
                                                    handler:nil]];
  [alertController
   addAction:[DFAlertAction
              actionWithTitle:@"Delete"
              style:DFAlertActionStyleDestructive
              handler:^(DFAlertAction *action) {
                NSString *imageKey = self.photo.imageKey;
                [[DFKeeperStore sharedStore] deletePhoto:self.photo];
                [SVProgressHUD showSuccessWithStatus:@"Deleted"];
                [[DFImageManager sharedManager] deleteImage:imageKey];
                [self.navigationController popViewControllerAnimated:YES];
              }]];
  [alertController showWithParentViewController:self animated:YES completion:nil];
}

- (IBAction)rotateButtonPressed:(id)sender {
  // fetch the correct image orientation from the DFKeeperImage
  [[DFKeeperStore sharedStore]
   fetchImageWithKey:self.photo.imageKey
   completion:^(DFKeeperImage *image) {
     // rotate in UI
     UIImageOrientation newOrientation = [self.imageView.image orientationRotatedLeft];
     UIImage *rotatedImage = [[UIImage alloc] initWithCGImage:self.imageView.image.CGImage
                                                        scale:1.0
                                                  orientation:newOrientation];
     self.imageView.image = rotatedImage;
     
     // Write the new image rotation locally and to the server
     NSNumber *currentOrientation = image.orientation ? image.orientation : @(1); // set default to up
     int newExifOrientation = [UIImage exifImageOrientationLeftFromOrientation:currentOrientation.intValue];
     DDLogVerbose(@"cgImageOrientation old:%d new:%d", image.orientation.intValue,
                  newExifOrientation);
     [[DFImageManager sharedManager] setExifOrientation:newExifOrientation
                                               forImage:image.key];
   }];
}

- (void)actionPressed:(id)sender
{
  [[DFImageManager sharedManager]
   originalImageForID:self.photo.imageKey
   completion:^(UIImage *image) {
     dispatch_async(dispatch_get_main_queue(), ^{
       UIActivityViewController *avc = [[UIActivityViewController alloc]
                                        initWithActivityItems:@[image]
                                        applicationActivities:nil];
       if ([avc respondsToSelector:@selector(setCompletionWithItemsHandler:)]) {
         avc.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
           [DFAnalytics logEvent:DFAnalyticsEventPhotoAction
                  withParameters:@{
                                   @"completed" : @(completed),
                                   @"activityType" : activityType ? activityType : @"none"
                                   }];
         };
       } else if ([avc respondsToSelector:@selector(setCompletionHandler:)]) {
         avc.completionHandler = ^(NSString *activityType, BOOL completed) {
           [DFAnalytics logEvent:DFAnalyticsEventPhotoAction
                  withParameters:@{
                                   @"completed" : @(completed),
                                   @"activityType" : activityType ? activityType : @"none"
                                   }];
         };
       }
       [self presentViewController:avc animated:YES completion:nil];
     });
   }];
}

- (void)infoPressed:(id)sender
{
  DFKeeperPhotoInfoViewController *infoVC = [[DFKeeperPhotoInfoViewController alloc]
                                             initWithPhoto:self.photo];
  [self.navigationController pushViewController:infoVC animated:YES];
}

@end
