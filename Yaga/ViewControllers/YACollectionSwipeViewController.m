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
        NSUInteger count = [[YAGroup allObjects] count];
        self.collectionViewControllers = [NSMutableArray new];
        for (int i = 0; i <=count; i++){
            YACollectionViewController *ctr = [YACollectionViewController new];
            [self.collectionViewControllers addObject:ctr];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    self.swipeView = [[SwipeView alloc] initWithFrame:self.view.frame];
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
    self.swipeView.pagingEnabled = YES;
    self.swipeView.wrapEnabled = YES;
    self.swipeView.itemsPerPage = 1;
    self.swipeView.defersItemViewLoading = YES;
    [self.swipeView reloadData];
    [self.view addSubview:self.swipeView];
}

- (YACollectionViewController*)currentCollectionView
{
    return self.collectionViewControllers[self.swipeView.currentPage];
}

- (void)scrollToCurrentGroup
{
    YAGroup *currentGroup = [[YAUser currentUser] currentGroup];
    NSUInteger index = [[YAGroup allObjects] indexOfObject:currentGroup];
    [self.swipeView scrollToItemAtIndex:index duration:0.2f];
}

#pragma mark SwipeViewDataSource/Delegate

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return [[YAGroup allObjects] count];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    YACollectionViewController *ctr = self.collectionViewControllers[index];
    ctr.controllersGroup = [[YAGroup allObjects] objectAtIndex:index];
    ctr.delegate = self.collectionDelegate;
    return ctr.view;
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView {
    return CGSizeMake(swipeView.frame.size.width, swipeView.frame.size.height);
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    YAGroup *group = [[YAGroup allObjects] objectAtIndex:self.swipeView.currentPage];
    [[YAUser currentUser] setCurrentGroup:group];
    YACollectionViewController *ctr = self.currentCollectionView;
    NSLog(@"%@", NSStringFromCGPoint(ctr.collectionView.contentOffset));
    [ctr.delegate adjustCollectionView];
//    [UIView animateWithDuration:0.5f animations:^{
//        ctr.collectionView.contentOffset = CGPointZero;
//    }];

}

@end
