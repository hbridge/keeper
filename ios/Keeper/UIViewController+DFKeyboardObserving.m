//
//  UIViewController+DFKeyboardObserving.m
//  Strand
//
//  Created by Henry Bridge on 12/31/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import "UIViewController+DFKeyboardObserving.h"

@implementation UIViewController (DFKeyboardObserving)

- (void)updateFrameFromKeyboardNotif:(NSNotification *)notification
                otherAnimationsBlock:(DFVoidBlock)otherAnimationsBlock
{
  CGRect keyboardStartFrame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
  CGRect keyboardEndFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  CGFloat yDelta = keyboardStartFrame.origin.y - keyboardEndFrame.origin.y;
  CGRect frame = self.view.frame;
  frame.size.height -= yDelta;
  
  NSNumber *duration = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
  NSNumber *animatinoCurve = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
  
  [UIView
   animateWithDuration:duration.floatValue
   delay:0.0
   options:animatinoCurve.integerValue
   animations:^{
     self.view.frame = frame;
     if (otherAnimationsBlock) otherAnimationsBlock();
   } completion:^(BOOL finished) {
     
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


@end
