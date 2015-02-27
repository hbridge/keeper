//
//  UIAlertView+DFHelpers.h
//  Strand
//
//  Created by Henry Bridge on 7/14/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (DFHelpers)

+ (void)showSimpleAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (void)showSimpleAlertWithTitle:(NSString *)title
                   formatMessage:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);

@end
