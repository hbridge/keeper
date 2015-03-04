//
//  DFShareCategorizeViewController.m
//  Keeper
//
//  Created by Henry Bridge on 3/3/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFShareCategorizeViewController.h"
#import "DFKeeperStore.h"
#import "DFCategoryConstants.h"
#import "UIImage+Resize.h"
#import "DFImageManager.h"
#import "DFExifHelper.h"
#import <AWSiOSSDKv2/AWSCore.h>
#import "DFNetworkingConstants.h"

@interface DFShareCategorizeViewController ()

@property (nonatomic, retain) NSArray *categories;

@end

@implementation DFShareCategorizeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
  [self reloadData];
  
  CGSize preferredSize = [[UIScreen mainScreen] bounds].size;
  preferredSize.height = preferredSize.height - 40;
  preferredSize.width = preferredSize.width - 40;
  self.preferredContentSize = preferredSize;
  self.tableView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
  [self configureNav];
  [self configureNetworking];
}

- (void)configureNetworking
{
  AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider credentialsWithRegionType:CognitoRegionType
                                                                                                 identityPoolId:CognitoIdentityPoolId];
  AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:DefaultServiceRegionType
                                                                        credentialsProvider:credentialsProvider];
  [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
}

- (void)configureNav
{
  self.navigationItem.title = @"Select Category";
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                           target:self
                                           action:@selector(cancelButtonPressed:)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadData
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [[DFKeeperStore sharedStore] fetchPhotosWithCompletion:^(NSArray *photos) {
      self.categories = [[DFKeeperStore sharedStore] allCategories];
      [self.tableView reloadData];
    }];
  });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.categories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
  NSString *category = self.categories[indexPath.row];
  cell.textLabel.text = category;
  cell.imageView.image = [[[DFCategoryConstants gridIconForCategory:category]
                           thumbnailImage:20
                           transparentBorder:0
                           cornerRadius:0
                           interpolationQuality:kCGInterpolationDefault]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  cell.backgroundColor = [UIColor clearColor];
  
  return cell;
}

#pragma mark - Actions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *category = self.categories[indexPath.row];
  
  DDLogInfo(@"%@ '%@' selected for context: %@", self.class, category, self.extensionContext);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    dispatch_semaphore_t loadSemaphore = dispatch_semaphore_create(0);
    for (NSExtensionItem *extensionItem in self.extensionContext.inputItems) {
      for (NSItemProvider *itemProvider in extensionItem.attachments)
        if ([itemProvider hasItemConformingToTypeIdentifier:@"public.image"]) {
          [itemProvider
           loadItemForTypeIdentifier:@"public.image"
           options:@{}
           completionHandler:^(id<NSSecureCoding> item, NSError *error) {
             NSURL *imageURL = (NSURL *)item;
             NSDictionary *metadata = [DFExifHelper metadataForImageAtURL:imageURL];
             UIImage *image = [UIImage imageWithContentsOfFile:[imageURL path]];
             DDLogInfo(@"%@ importing image URL: %@", self.class, imageURL);
             
             NSString *imageKey = [[DFImageManager sharedManager] saveImage:image category:category withMetadata:metadata];
             [[DFKeeperStore sharedStore]
              fetchImageWithKey:imageKey
              completion:^(DFKeeperImage *keeperImage) {
                Firebase *imageRef = [keeperImage firebaseRef];
                [imageRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                  DFKeeperImage *changedImage = [[DFKeeperImage alloc] initWithSnapshot:snapshot];
                  if (changedImage.uploaded.boolValue) dispatch_semaphore_signal(loadSemaphore);
                }];
              }];
             
           }];
        }
    }
    dispatch_semaphore_wait(loadSemaphore, dispatch_time(DISPATCH_TIME_NOW, 10000000000));
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
  });
}

- (void)cancelButtonPressed:(id)sender
{
  [self.extensionContext cancelRequestWithError:nil];
}





@end
