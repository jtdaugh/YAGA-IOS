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

@interface YAGifGridViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate,
    UIGestureRecognizerDelegate, YASwipingViewControllerDelegate, YAEventCountReceiver>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (nonatomic) BOOL scrolling;

- (void)reload;

@property (strong, nonatomic) YAGroup *group;

- (void)setupPullToRefresh;
- (void)reloadCollectionView;
@end
