//
//  DFKeeperPhotoInfoViewController.m
//  Keeper
//
//  Created by Henry Bridge on 3/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperPhotoInfoViewController.h"
#import "DFKeeperSearchIndexManager.h"

@interface DFKeeperPhotoInfoViewController ()

@end

@implementation DFKeeperPhotoInfoViewController

- (instancetype)initWithPhoto:(DFKeeperPhoto *)photo
{
  self = [super init];
  if (self) {
    _keeperPhoto = photo;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.saveDateLabel.text = self.keeperPhoto.saveDate.description;
  self.keyLabel.text = self.keeperPhoto.key;
  
  [[DFKeeperSearchIndexManager sharedManager]
   resultForKey:self.keeperPhoto.key
   completion:^(DFKeeperSearchResult *result) {
     dispatch_async(dispatch_get_main_queue(), ^{
       if (result.documentString.length > 0) {
         self.indexedTextField.text = result.documentString;
       } else {
         self.indexedTextField.text = @"No text found";
       }
     });
   }];
  
}
- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  self.contentViewWidthConstraint.constant = self.view.frame.size.width;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
