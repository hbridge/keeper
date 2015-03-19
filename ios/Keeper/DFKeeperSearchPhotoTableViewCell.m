//
//  DFKeeperSearchPhotoTableViewCell.m
//  Keeper
//
//  Created by Henry Bridge on 3/10/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperSearchPhotoTableViewCell.h"

@implementation DFKeeperSearchPhotoTableViewCell

- (void)awakeFromNib {
  self.indextedTextLabel.font = [[DFKeeperConstants LabelFont] fontWithSize:12.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
  if (self.indextedTextLabel.frame.size.width != self.indextedTextLabel.preferredMaxLayoutWidth) {
    self.indextedTextLabel.preferredMaxLayoutWidth = self.indextedTextLabel.frame.size.width;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    }
}

@end
