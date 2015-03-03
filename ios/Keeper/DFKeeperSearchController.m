//
//  DFKeeperSearchController.m
//  Keeper
//
//  Created by Henry Bridge on 3/3/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperSearchController.h"
#import "DFKeeperStore.h"
#import "DFCategoryConstants.h"
#import "UIImage+Resize.h"

@implementation DFKeeperSearchController


- (void)setTableView:(UITableView *)tableView
{
  _tableView = tableView;
  tableView.delegate = self;
  tableView.dataSource = self;
  
  [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
  tableView.separatorInset = UIEdgeInsetsMake(0, 50.0, 0, 0);
}

- (void)setSearchBar:(UISearchBar *)searchBar
{
  _searchBar = searchBar;
  searchBar.delegate = self;
}

#pragma mark - SearchBar Delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
  self.tableView.hidden = NO;
  [self updateSearchResults:searchBar.text];
  [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
  [self.searchBar setShowsCancelButton:NO animated:YES];
  [self.delegate searchControllerDidCancel:self];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  self.searchBar.text = @"";
  self.tableView.hidden = YES;
  [searchBar endEditing:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
  [self updateSearchResults:searchText];
}

- (void)updateSearchResults:(NSString *)searchText
{
  NSArray *allCateogries = [[DFKeeperStore sharedStore] allCategories];
  if ([searchText isNotEmpty]) {
    self.searchResults = [allCateogries objectsPassingTestBlock:^BOOL(NSString *category) {
      NSString *lowercaseQuery = [searchText lowercaseString];
      NSString *lowerCaseCategory = [category lowercaseString];
      return [lowerCaseCategory hasPrefix:lowercaseQuery];
    }];
  } else {
    self.searchResults = allCateogries;
  }
  [self.tableView reloadData];
}

#pragma mark - TableView Datasource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
  cell.tintColor = [UIColor darkTextColor];
  NSString *category = self.searchResults[indexPath.row];
  cell.textLabel.text = category;
  cell.imageView.image = [[[DFCategoryConstants gridIconForCategory:category]
                          thumbnailImage:20
                          transparentBorder:0
                          cornerRadius:0
                          interpolationQuality:kCGInterpolationDefault]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return @"Categories";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *query = self.searchResults[indexPath.row];
  NSArray *allPhotos = [[DFKeeperStore sharedStore] photos];
  NSArray *searchResults = [allPhotos objectsPassingTestBlock:^BOOL(DFKeeperPhoto *photo){
    return [photo.category isEqual:query];
  }];
  
  [self.delegate searchController:self
               completedWithQuery:query
                          results:searchResults];
}

@end
