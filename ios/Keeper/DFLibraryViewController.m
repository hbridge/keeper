//
//  DFLibraryViewController.m
//  Keeper
//
//  Created by Henry Bridge on 2/19/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFLibraryViewController.h"

@interface DFLibraryViewController ()

@end

@implementation DFLibraryViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self configureNav];
}

- (void)configureNav
{
  self.navigationItem.title = @"Library";
  self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc]
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                               target:self
                                               action:@selector(addButtonPressed:)]];
}

- (void)addButtonPressed:(id)sender
{
  
}

@end
