//
//  DFKeeperSearchController.h
//  Keeper
//
//  Created by Henry Bridge on 3/3/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFKeeperPhoto.h"

@class DFKeeperSearchController;

@protocol DFKeeperSearchControllerDelegate <NSObject>

- (void)searchController:(DFKeeperSearchController *)searchController
      completedWithQuery:(NSString *)query
                 results:(NSArray *)keeperPhotos;
- (void)searchController:(DFKeeperSearchController *)searchController
      completedWithQuery:(NSString *)query
              selectedId:(NSString *)objectIdentifier;

- (void)searchControllerDidCancel:(DFKeeperSearchController *)searchController;

@end

@interface DFKeeperSearchController : NSObject <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSObject<DFKeeperSearchControllerDelegate> *delegate;

@end
