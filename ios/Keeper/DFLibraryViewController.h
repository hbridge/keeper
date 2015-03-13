//
//  DFLibraryViewController.h
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFCategorizeController.h"
#import "DFKeeperSearchController.h"

@interface DFLibraryViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, DFCategorizeControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DFKeeperSearchControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *noPhotosLabel;

@end
