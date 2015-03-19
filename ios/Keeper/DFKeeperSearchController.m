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
#import "DFKeeperSearchIndexManager.h"
#import "DFImageManager.h"
#import "DFKeeperSearchPhotoTableViewCell.h"
#import "NSDateFormatter+DFPhotoDateFormatters.h"

@interface DFKeeperSearchController()

@property (nonatomic, retain) NSMutableOrderedSet *sectionTitles;
@property (nonatomic, retain) NSArray *categoriesSection;
@property (nonatomic, retain) NSArray *photosSection;

@end

@implementation DFKeeperSearchController


- (instancetype)init
{
  self = [super init];
  if (self) {
    self.sectionTitles = [NSMutableOrderedSet new];
  }
  return self;
}

- (void)setTableView:(UITableView *)tableView
{
  _tableView = tableView;
  
  tableView.delegate = self;
  tableView.dataSource = self;
  
  [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
  [tableView registerNib:[UINib nibWithNibName:[[DFKeeperSearchPhotoTableViewCell class] description]
                                        bundle:nil] forCellReuseIdentifier:@"photoCell"];
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
  [self updateSearchResults:[searchText copy]];
}

static NSString *CategoriesSectionTitle = @"Categories";
static NSString *PhotosSectionTitle = @"Text";

- (void)updateSearchResults:(NSString *)searchText
{
  NSArray *allCateogries = [[DFKeeperStore sharedStore] allCategories];
  NSLog(@"updateSearchResults: %@", searchText);
  if ([searchText isNotEmpty]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.categoriesSection = [allCateogries objectsPassingTestBlock:^BOOL(NSString *category) {
        NSString *lowercaseQuery = [searchText lowercaseString];
        NSString *lowerCaseCategory = [category lowercaseString];
        return [lowerCaseCategory hasPrefix:lowercaseQuery];
      }];
      if (self.categoriesSection.count > 0) {
        [self.sectionTitles insertObject:CategoriesSectionTitle atIndex:0];
      } else {
        [self.sectionTitles removeObject:CategoriesSectionTitle];
      }
      [self.tableView reloadData];
    });
    
    // text content
    [[DFKeeperSearchIndexManager sharedManager]
     keysMatchingSearch:searchText
     completion:^(NSArray *results) {
       dispatch_async(dispatch_get_main_queue(), ^{
         self.photosSection = results;
         if (self.photosSection.count > 0) {
           [self.sectionTitles insertObject:PhotosSectionTitle atIndex:0];
         } else {
           [self.sectionTitles removeObject:PhotosSectionTitle];
         }

         [self.tableView reloadData];
         DDLogVerbose(@"%@ got %@ matches for %@",
                      self.class,
                      @(results.count),
                      searchText);
       });
     }];
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.sectionTitles removeAllObjects];
      [self.sectionTitles addObject:CategoriesSectionTitle];
      self.categoriesSection = allCateogries;
      [self.tableView reloadData];
    });
    
  }
}

#pragma mark - TableView Datasource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return self.sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if ([self.sectionTitles[section] isEqual:CategoriesSectionTitle]) {
    return self.categoriesSection.count;
  } else if ([self.sectionTitles[section] isEqual:PhotosSectionTitle]) {
    return self.photosSection.count;
  }
  
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.sectionTitles[indexPath.section] isEqual:CategoriesSectionTitle]) {
    return [self cellForCategoryAtIndexPath:indexPath];
  } else if ([self.sectionTitles[indexPath.section] isEqual:PhotosSectionTitle]) {
    return [self cellForPhotoAtIndexPath:indexPath];
  }
  
  [NSException raise:@"no cell" format:@"unexpected section"];
  return nil;
}

- (UITableViewCell *)cellForCategoryAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
  cell.textLabel.font = [[DFKeeperConstants LabelFont] fontWithSize:cell.textLabel.font.pointSize];
  cell.tintColor = [UIColor darkTextColor];
  
  NSString *category = self.categoriesSection[indexPath.row];
  cell.textLabel.text = category;
  cell.imageView.image = [[[DFCategoryConstants gridIconForCategory:category]
                           thumbnailImage:20
                           transparentBorder:0
                           cornerRadius:0
                           interpolationQuality:kCGInterpolationDefault]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  return cell;

}

- (UITableViewCell *)cellForPhotoAtIndexPath:(NSIndexPath *)indexPath
{
  DFKeeperSearchPhotoTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"photoCell"];
  cell.tintColor = [UIColor darkTextColor];
  DFKeeperSearchResult *searchResult = self.photosSection[indexPath.row];
  DFKeeperPhoto *photo = [[DFKeeperStore sharedStore]
                          photoWithKey:searchResult.objectKey];
  
  // set the cell data
  BOOL clearData = cell.representativeObject != photo;
  cell.representativeObject = photo;
  cell.indextedTextLabel.attributedText = [searchResult attributedSnippetForSearch:self.searchBar.text
                                           baseFont:cell.indextedTextLabel.font];
  if (clearData)
    cell.photoPreviewImageView.image = nil;
  static NSDateFormatter *dateFormatter = nil;
  if (!dateFormatter) dateFormatter = [NSDateFormatter HumanDateFormatter];
  cell.dateLabel.text = [dateFormatter stringFromDate:photo.saveDate];
  
  [[DFImageManager sharedManager]
   imageForKey:photo.imageKey
   pointSize:cell.photoPreviewImageView.frame.size
   contentMode:DFImageRequestContentModeAspectFill
   deliveryMode:DFImageRequestOptionsDeliveryModeFastFormat
   completion:^(UIImage *image) {
     dispatch_async(dispatch_get_main_queue(), ^{
       if ([[self.tableView indexPathForCell:cell] isEqual:indexPath]) {
         DDLogVerbose(@"setting image size: %@", NSStringFromCGSize(image.size));
         cell.photoPreviewImageView.clipsToBounds = YES;
         cell.photoPreviewImageView.image = image;
         [cell setNeedsLayout];
       }
     });
   }];
  
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return self.sectionTitles[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.sectionTitles[indexPath.section] isEqual:CategoriesSectionTitle]) {
    return 44.0;
  } else if ([self.sectionTitles[indexPath.section] isEqual:PhotosSectionTitle]) {
    return 61.0;
  }
  
  return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.sectionTitles[indexPath.section] isEqual:CategoriesSectionTitle]) {
    NSString *query = self.categoriesSection[indexPath.row];
    NSArray *allPhotos = [[DFKeeperStore sharedStore] photos];
    NSArray *searchResults = [allPhotos objectsPassingTestBlock:^BOOL(DFKeeperPhoto *photo){
      return [photo.category isEqual:query];
    }];
    
    [self.delegate searchController:self
                 completedWithQuery:query
                            results:searchResults];
  } else if([self.sectionTitles[indexPath.section] isEqual:PhotosSectionTitle]) {
    DFKeeperSearchResult *searchResult = self.photosSection[indexPath.row];
    [self.delegate searchController:self
                 completedWithQuery:self.searchBar.text
                         selectedId:searchResult.objectKey];
  }
}

@end
