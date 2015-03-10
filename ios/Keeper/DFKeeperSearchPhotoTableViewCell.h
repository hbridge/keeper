//
//  DFKeeperSearchPhotoTableViewCell.h
//  Keeper
//
//  Created by Henry Bridge on 3/10/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DFKeeperSearchPhotoTableViewCell : UITableViewCell

@property (nonatomic, retain) id representativeObject;
@property (weak, nonatomic) IBOutlet UIImageView *photoPreviewImageView;
@property (weak, nonatomic) IBOutlet UILabel *indextedTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end
