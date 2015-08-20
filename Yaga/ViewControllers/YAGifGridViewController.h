//
//  CollectionViewController.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YASwipingViewController.h"
#import "YAEventManager.h"
#import "UIScrollView+SVInfiniteScrolling.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "YAGroup.h"
#import "YAUser.h"

@class BLKFlexibleHeightBar;

@interface YAGifGridViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate,
    UIGestureRecognizerDelegate, YASwipingViewControllerDelegate, YAEventCountReceiver>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;

@property (nonatomic) BOOL scrolling;
@property (strong, nonatomic) YAGroup *group;
@property (nonatomic, strong) BLKFlexibleHeightBar *flexibleNavBar;

@property (nonatomic) BOOL pendingMode;

- (void)reload;

- (void)reloadSortedVideos;
- (void)setupPullToRefresh;
- (void)groupInfoPressed;
- (void)manualTriggerPullToRefresh;

- (NSInteger)gifGridSection;

- (BLKFlexibleHeightBar *)createNavBar;

@end
