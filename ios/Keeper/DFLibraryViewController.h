//
//  DFLibraryViewController.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFCategorizeController.h"

@interface DFLibraryViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, DFCategorizeControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@end
