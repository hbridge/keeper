//
//  UIViewController+DFKeyboardObserving.m
//  Strand
//
//  Created by Henry Bridge on 12/31/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "UIViewController+DFKeyboardObserving.h"

@implementation UIViewController (DFKeyboardObserving)


- (CGFloat)keyboardVisibleHeightForNotif:(NSNotification *)note
{
  CGRect keyboardEndFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  CGFloat keyboardMinY = CGRectGetMinY(keyboardEndFrame);
  CGFloat keyboardVisibleHeight = MAX(self.view.window.bounds.size.height - keyboardMinY, 0);
  if ([note.name isEqual:UIKeyboardWillHideNotification]) keyboardVisibleHeight = 0.0;
  return keyboardVisibleHeight;
}

- (void)updateFrameFromKeyboardNotif:(NSNotification *)notification
                otherAnimationsBlock:(DFVoidBlock)otherAnimationsBlock
{
  CGFloat keyboardVisibleHeight = [self keyboardVisibleHeightForNotif:notification];
  CGRect frame = self.view.frame;
  frame.size.height = self.view.window.bounds.size.height - frame.origin.y - keyboardVisibleHeight;
  
  NSNumber *duration = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
  NSNumber *animationCurve = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
  
  [UIView
   animateWithDuration:duration.floatValue
   delay:0.0
   options:animationCurve.integerValue
   animations:^{
     self.view.frame = frame;
     if (otherAnimationsBlock) otherAnimationsBlock();
   } completion:^(BOOL finished) {
     [self.view layoutIfNeeded];
   }];
}

- (void)setAutomaticallyAdjustFrameOnKeyboardChange:(BOOL)autoAdjust
{
  if (autoAdjust) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoAdjustFrameForKeyboardChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoAdjustFrameForKeyboardChange:) name:UIKeyboardWillHideNotification object:nil];
  } else {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  }
}

- (void)autoAdjustFrameForKeyboardChange:(NSNotification *)note
{
  [self updateFrameFromKeyboardNotif:note otherAnimationsBlock:nil];
}

- (void)setAutomaticallyAdjustTableViewFrameOnKeyboardChange:(BOOL)autoAdjust
{
  if (autoAdjust) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoAdjustTableViewForKeyboardChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoAdjustTableViewForKeyboardChange:) name:UIKeyboardWillHideNotification object:nil];
  } else {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  }
}

- (void)autoAdjustTableViewForKeyboardChange:(NSNotification *)note
{
  CGFloat keyboardHeight = [self keyboardVisibleHeightForNotif:note];
  UITableView *tableView = [self valueForKey:@"tableView"];
  UIEdgeInsets contentInset = tableView.contentInset;
  contentInset.bottom = keyboardHeight;
  tableView.contentInset = contentInset;
}


@end
