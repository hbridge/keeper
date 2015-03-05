//
//  DFInsetTextField.m
//  Keeper
//
//  Created by Henry Bridge on 3/5/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFInsetTextField.h"

@implementation DFInsetTextField

- (void)setTextInsets:(UIEdgeInsets)textInsets
{
  _textInsets = textInsets;
  [self setNeedsLayout];
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
  CGRect rect = [super textRectForBounds:bounds];
  return [self insetRectForRect:rect];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
  CGRect rect = [super placeholderRectForBounds:bounds];
  return [self insetRectForRect:rect];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
  CGRect rect = [super editingRectForBounds:bounds];
  return [self insetRectForRect:rect];
}

- (CGRect)insetRectForRect:(CGRect)rect
{
  rect.origin.x = rect.origin.x + self.textInsets.left;
  rect.origin.y = rect.origin.y + self.textInsets.top;
  rect.size.width = rect.size.width - self.textInsets.left - self.textInsets.right;
  rect.size.height = rect.size.height - self.textInsets.top - self.textInsets.bottom;
  return rect;
}

@end
