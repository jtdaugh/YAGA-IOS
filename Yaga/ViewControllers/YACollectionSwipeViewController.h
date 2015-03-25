//
//  YACollectionSwipeViewController.h
//  Yaga
//
//  Created by Iegor on 3/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import <SwipeView/SwipeView.h>
#import "YACollectionViewController.h"
#import "YASwipingViewController.h"

@interface YACollectionSwipeViewController : UIViewController <SwipeViewDataSource, SwipeViewDelegate>
@property (nonatomic, strong) SwipeView *swipeView;
@property (nonatomic, weak) id<YACollectionViewControllerDelegate> collectionDelegate;
- (YACollectionViewController*)currentCollectionView;
@end
