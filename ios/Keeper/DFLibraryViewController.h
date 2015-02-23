//
//  DFLibraryViewController.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CNPGridMenu/CNPGridMenu.h>

@interface DFLibraryViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, CNPGridMenuDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@end
