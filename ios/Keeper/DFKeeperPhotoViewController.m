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

@interface DFKeeperPhotoViewController ()

@property (nonatomic, retain) DFCategorizeController *categorizeController;

@end

@implementation DFKeeperPhotoViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (self.photo)
    [self reloadData];
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
  [self.tagButton setImage:[icon thumbnailImage:20
                              transparentBorder:0
                                   cornerRadius:0
                           interpolationQuality:kCGInterpolationDefault]
                  forState:UIControlStateNormal];
  [self.tagButton setTitle:self.photo.category forState:UIControlStateNormal];
}

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

@end
