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
#import "YAGridViewController.h"

@interface YACollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate,
    UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate, YASwipingViewControllerDelegate, YAEventCountReceiver> {
    CGPoint lastOffset;
    NSTimeInterval lastOffsetCapture;
}

@property (strong, nonatomic) UICollectionView *collectionView;
@property (weak, nonatomic) id<YAGridViewControllerDelegate> delegate;
@property (nonatomic) BOOL scrolling;
- (void)reload;

@end
