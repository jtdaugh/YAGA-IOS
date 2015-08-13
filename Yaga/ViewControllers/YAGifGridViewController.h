//
//  CollectionViewController.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YASwipingViewController.h"
#import "YAEventManager.h"

@class BLKFlexibleHeightBar;

@interface YAGifGridViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate,
    UIGestureRecognizerDelegate, YASwipingViewControllerDelegate, YAEventCountReceiver>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;

@property (nonatomic) BOOL scrolling;
@property (strong, nonatomic) YAGroup *group;
@property (nonatomic, strong) BLKFlexibleHeightBar *flexibleNavBar;

- (void)reload;

- (void)reloadSortedVideos;
- (void)setupPullToRefresh;
- (void)reloadCollectionView;

- (BLKFlexibleHeightBar *)createNavBar;

@end
