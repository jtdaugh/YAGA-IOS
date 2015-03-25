//
//  YACollectionSwipeViewController.m
//  Yaga
//
//  Created by Iegor on 3/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YAUser.h"
#import "YACollectionSwipeViewController.h"
@interface YACollectionSwipeViewController ()
@property (nonatomic, strong) NSMutableArray *collectionViewControllers;
@end

@implementation YACollectionSwipeViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.collectionViewControllers = [NSMutableArray new];
        for (int i = 0; i <=2; i++){
            YACollectionViewController *ctr = [YACollectionViewController new];
            [self.collectionViewControllers addObject:ctr];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    self.swipeView = [[SwipeView alloc] initWithFrame:self.view.bounds];
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
    self.swipeView.pagingEnabled = YES;
    self.swipeView.itemsPerPage = 1;
    [self.view addSubview:self.swipeView];
}

- (YACollectionViewController*)currentCollectionView
{
    return self.collectionViewControllers[self.swipeView.currentPage];
}

#pragma mark SwipeViewDataSource/Delegate

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return 3;
}
- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    YACollectionViewController *ctr = self.collectionViewControllers[index];
    ctr.controllersGroup = [[YAUser currentUser] currentGroup];
    ctr.delegate = self.collectionDelegate;
    ctr.view.frame = self.swipeView.bounds;
    return ctr.view;
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    YACollectionViewController *ctr = self.currentCollectionView;
}

@end
