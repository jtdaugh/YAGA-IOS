//
//  CollectionViewController.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//
#import "YAVideoCell.h"
#import "YASwipingViewController.h"
#import "YAEventManager.h"
#import "UIScrollView+SVInfiniteScrolling.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "YAGroup.h"
#import "YAUser.h"

@interface YAGifGridViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate,
    UIGestureRecognizerDelegate, YASwipingViewControllerDelegate, YAEventCountReceiver>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (nonatomic) BOOL scrolling;

- (void)reload;

@property (strong, nonatomic) YAGroup *group;

- (void)reloadSortedVideos;
- (void)setupPullToRefresh;

@end
