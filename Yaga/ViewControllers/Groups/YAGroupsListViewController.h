//
//  MyCrewsViewController.h
//  Pic6
//
//  Created by Raj Vir on 10/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YAGroupsListViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

- (instancetype)initWithCollectionViewTopInset:(CGFloat)topInset;
- (void)changeTopInset:(CGFloat)newTopInset;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UITapGestureRecognizer *cameraTapToClose;
@property (nonatomic, strong) UITapGestureRecognizer *collectionTapToClose;

@end
