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

typedef void (^cameraCompletion)(void);

@protocol YACollectionViewControllerDelegate <NSObject>
- (void)showCamera:(BOOL)show showPart:(BOOL)showPart animated:(BOOL)animated completion:(cameraCompletion)completion;
- (void)enableRecording:(BOOL)enable;
- (void)collectionViewDidScroll;
@end

@interface YACollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate,
    UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate, YASwipingViewControllerDelegate, YAEventCountReceiver> {
    CGPoint lastOffset;
    NSTimeInterval lastOffsetCapture;
}

@property (strong, nonatomic) UICollectionView *collectionView;
@property (weak, nonatomic) id<YACollectionViewControllerDelegate> delegate;
@property (nonatomic) BOOL scrolling;
- (void)reload;
@end
