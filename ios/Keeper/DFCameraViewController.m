//
//  DFCameraViewController.m
//  Strand
//
//  Created by Henry Bridge on 6/9/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "DFCameraViewController.h"
#import "DFCameraOverlayView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "DFKeeperStore.h"
#import "UIImage+Resize.h"
#import "DFUser.h"
#import "DFCategoryConstants.h"
#import "DFAnalytics.h"
#import "DFRootViewController.h"
#import "DFUIKit.h"
#import "DFAssetLibraryHelper.h"
#import "DFSettingsManager.h"

static NSString *const DFStrandCameraHelpWasShown = @"DFStrandCameraHelpWasShown";
static NSString *const DFStrandCameraJoinableHelpWasShown = @"DFStrandCameraJoinableHelpWasShown";

const unsigned int MaxRetryCount = 3;
const CLLocationAccuracy MinLocationAccuracy = 65.0;
const NSTimeInterval MaxLocationAge = 15 * 60;
const unsigned int RetryDelaySecs = 5;
const NSTimeInterval WifiPromptInterval = 10 * 60;
const unsigned int SavePromptMinPhotos = 3;

@interface DFCameraViewController ()

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) NSTimer *updateUITimer;
@property (nonatomic, retain) NSDate *lastWifiPromptDate;


@property (nonatomic, retain) UIImage* lastImageCaptured;
@property (nonatomic, retain) NSDictionary *lastMetadataCaptured;
@property (nonatomic, retain) DFCategorizeController *categorizeController;

@end

@implementation DFCameraViewController

@synthesize customCameraOverlayView = _customCameraOverlayView;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self configureLocationManager];
    [self observeNotifications];
    self.lastWifiPromptDate = [NSDate dateWithTimeIntervalSince1970:0];
  }
  return self;
}

- (void)observeNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidEnterBackground:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidResignActive:)
                                               name:UIApplicationWillResignActiveNotification
                                             object:nil];
 }

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.cameraOverlayView = self.customCameraOverlayView;
  self.customCameraOverlayView.flashButton.tag = (NSInteger)self.cameraFlashMode;
  [self.customCameraOverlayView updateUIForFlashMode:UIImagePickerControllerCameraFlashModeOff];
  
  self.delegate = self;
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  if (!CGRectEqualToRect(self.customCameraOverlayView.frame, self.view.bounds)) {
    self.customCameraOverlayView.frame = self.view.bounds;
    [self.view layoutIfNeeded];
  }
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self viewDidBecomeActive];
  [DFAnalytics logViewController:self appearedWithParameters:nil];
}


- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self viewDidResignActive];
}

- (void)configureLocationManager
{
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
  self.locationManager.distanceFilter = 10;
  self.locationManager.delegate = self;
}

- (void)viewDidBecomeActive
{

}

- (void)viewDidResignActive
{

}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
  if (self.isViewLoaded && self.view.window) {
    [self viewDidBecomeActive];
  }
}

- (void)applicationDidEnterBackground:(NSNotification *)note
{
  if (self.isViewLoaded && self.view.window) {
    [self viewDidResignActive];
  }
}

- (void)applicationDidResignActive:(NSNotification *)note
{
  if (self.isViewLoaded && self.view.window) {
    [self viewDidResignActive];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Overlay setup

- (DFCameraOverlayView *)customCameraOverlayView
{
  if (!_customCameraOverlayView) {
    _customCameraOverlayView = [[[UINib nibWithNibName:@"DFCameraOverlayView" bundle:nil]
                                 instantiateWithOwner:self options:nil]
                                firstObject];
    _customCameraOverlayView.frame = self.view.frame;
    // only wire up buttons if we're not in the simulator
    [_customCameraOverlayView.takePhotoButton addTarget:self
                                                 action:@selector(takePhotoButtonPressed:)
                                       forControlEvents:UIControlEventTouchUpInside];
    [_customCameraOverlayView.galleryButton addTarget:self
                                               action:@selector(galleryButtonPressed:)
                                     forControlEvents:UIControlEventTouchUpInside];
    [_customCameraOverlayView.flashButton addTarget:self
                                             action:@selector(flashButtonPressed:)
                                   forControlEvents:UIControlEventTouchUpInside];
    [_customCameraOverlayView.swapCameraButton addTarget:self
                                                  action:@selector(swapCameraButtonPressed:)
                                        forControlEvents:UIControlEventTouchUpInside];
  }
  
  
  return _customCameraOverlayView;
}



#pragma mark - User actions

- (void)takePhotoButtonPressed:(UIButton *)sender
{
  DDLogInfo(@"%@ Take photo button pressed.",
            [self.class description]);
  [self takePicture];
  [self flashCameraView];
}

- (void)showAutoSavePrompt
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Auto-Save Photos?"
                                                  message:@"Would you like photos you take in Strand to automatically be saved to your Camera Roll?"
                                                 delegate:self
                                        cancelButtonTitle:@"Not Now"
                                        otherButtonTitles:@"Yes", nil];
  [alert show];
}

- (void)flashButtonPressed:(UIButton *)flashButton
{
  UIImagePickerControllerCameraFlashMode newMode;
  if (flashButton.tag == (NSInteger)UIImagePickerControllerCameraFlashModeAuto) {
    newMode = UIImagePickerControllerCameraFlashModeOn;
  } else if (flashButton.tag == (NSInteger)UIImagePickerControllerCameraFlashModeOn) {
    newMode = UIImagePickerControllerCameraFlashModeOff;
  } else if (flashButton.tag == (NSInteger)UIImagePickerControllerCameraFlashModeOff) {
    newMode = UIImagePickerControllerCameraFlashModeAuto;
  }
  
  flashButton.tag = newMode;
  self.cameraFlashMode = newMode;
  [self.customCameraOverlayView updateUIForFlashMode:newMode];
}

- (void)swapCameraButtonPressed:(UIButton *)sender
{
  if (self.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
    self.cameraDevice = UIImagePickerControllerCameraDeviceRear;
  } else if (self.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
    self.cameraDevice = UIImagePickerControllerCameraDeviceFront;
  }
}

- (void)flashCameraView
{
  [UIView animateWithDuration:0.3 animations:^{
    self.cameraOverlayView.backgroundColor = [UIColor blackColor];
  } completion:^(BOOL finished) {
    if (finished) [UIView animateWithDuration:0.3 animations:^{
      self.cameraOverlayView.backgroundColor = [UIColor clearColor];
    }];
  }];
}

#pragma mark - Image Picker Controller delegate methods

- (void)cameraView:(DFAVCameraViewController *)cameraView
   didCaptureImage:(UIImage *)image
          metadata:(NSDictionary *)metadata
{
  DDLogInfo(@"%@ image captured", [self.class description]);
  
  self.categorizeController = [DFCategorizeController new];
  self.categorizeController.delegate = self;
  [self.categorizeController presentInViewController:self];
  
  self.lastImageCaptured = image;
  self.lastMetadataCaptured = metadata;
}

- (void)autosaveToCameraRoll:(UIImage *)image metadata:(NSDictionary *)metadata
{
  NSString *autosaveSetting = [DFSettingsManager objectForSetting:DFSettingAutoSaveToCameraRoll];
  if (!autosaveSetting) {
    DFAlertController *alertController = [DFAlertController
                                          alertControllerWithTitle:@"Autosave to Camera Roll?"
                                          message:@"Would you like photos you take in Keeper "
                                          "to automatically save to your camera roll?"
                                          preferredStyle:DFAlertControllerStyleAlert];
    [alertController addAction:[DFAlertAction
                                actionWithTitle:@"Not Now"
                                style:DFAlertActionStyleCancel
                                handler:^(DFAlertAction *action) {
                                  [DFSettingsManager setObject:DFSettingValueNo forSetting:DFSettingAutoSaveToCameraRoll];
                                }]];
    [alertController addAction:[DFAlertAction
                                actionWithTitle:@"Yes"
                                style:DFAlertActionStyleDefault
                                handler:^(DFAlertAction *action) {
                                  [DFSettingsManager setObject:DFSettingValueNo forSetting:DFSettingAutoSaveToCameraRoll];
                                  [self autosaveToCameraRoll:image metadata:metadata];
                                }]];
    [alertController showWithParentViewController:self animated:YES completion:nil];
  } else if ([autosaveSetting isEqual:DFSettingValueYes]) {
    [DFAssetLibraryHelper saveImageToCameraRoll:image withMetadata:metadata completion:nil];
  }
}

- (void)categorizeController:(DFCategorizeController *)cateogrizeController
       didFinishWithCategory:(NSString *)category
{
  if (category) {
    [self saveImage:self.lastImageCaptured
               text:category
       withMetadata:self.lastMetadataCaptured
        retryNumber:0];
    [self autosaveToCameraRoll:self.lastImageCaptured metadata:self.lastMetadataCaptured];
  }
  
  
  [DFAnalytics logEvent:DFAnalyticsEventPhotoTaken
         withParameters:@{@"category" : category ? category : @"cancelled" }];

}

- (void)animateImageCaptured:(UIImage *)image{
  dispatch_async(dispatch_get_main_queue(), ^{
    DDLogInfo(@"%@ animating picture taken.", [self.class description]);
    CGRect imageViewFrame = CGRectMake(self.view.frame.origin.x,
                                       self.view.frame.origin.y,
                                       320,
                                       348);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.customCameraOverlayView addSubview:imageView];
    
    [UIView animateWithDuration:0.5 animations:^{
      // Change the position explicitly.
      imageView.frame = self.customCameraOverlayView.galleryButton.frame;
      imageView.alpha = 0.1;
    } completion:^(BOOL finished) {
      [imageView removeFromSuperview];
      DDLogInfo(@"%@ animation complete.", [self.class description]);
    }];
  });
}

- (void)saveImage:(UIImage *)image
             text:(NSString *)text
     withMetadata:(NSDictionary *)metadata
      retryNumber:(int)retryNumber
{
  DFKeeperPhoto *photo = [[DFKeeperPhoto alloc] init];
  photo.category = text;
  photo.metadata = metadata;
  photo.saveDate = [NSDate date];
  photo.user = [DFUser loggedInUser];
  [[DFKeeperStore sharedStore] savePhoto:photo];
  
  
  DFKeeperImage *imageRecord = [[DFKeeperImage alloc]
                                initWithImage:[image
                                               resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                               bounds:CGSizeMake(DFKeeperPhotoHighQualityMaxLength, DFKeeperPhotoHighQualityMaxLength)
                                               interpolationQuality:kCGInterpolationDefault]];
  [[DFKeeperStore sharedStore] storeImage:imageRecord forPhoto:photo];
}

- (void)galleryButtonPressed:(id)sender
{
  [[DFRootViewController rootViewController] showLibrary];
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
  return NO;
}


@end
