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
#import "YAFlexibleNavbarExtending.h"

@class BLKFlexibleHeightBar;

@interface YAGifGridViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate,
    UIGestureRecognizerDelegate, YASwipingViewControllerDelegate, YAEventCountReceiver, YAFlexibleNavbarExtending>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;

@property (nonatomic) BOOL scrolling;
@property (strong, nonatomic) YAGroup *group;

@property (nonatomic) BOOL pendingMode;

- (void)reload;

- (void)reloadSortedVideos;
- (void)setupPullToRefresh;
- (void)groupInfoPressed;
- (void)manualTriggerPullToRefresh;

- (void)performAdditionalRefreshRequests;

- (NSInteger)gifGridSection;

@property (nonatomic, strong) YAStandardFlexibleHeightBar *flexibleNavBar;
@end
