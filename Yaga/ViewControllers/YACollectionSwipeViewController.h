//
//  YACollectionSwipeViewController.h
//  Yaga
//
//  Created by Iegor on 3/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YACollectionViewController.h"
#import "YASwipingViewController.h"

@interface YACollectionSwipeViewController : YASwipingViewController
@property (weak, nonatomic) id<YACollectionViewControllerDelegate> delegate;
@property (nonatomic, readonly) YACollectionViewController *currentCollectionView;
@end
