//
//  CollectionViewController.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//
#import "YAVideoCell.h"
typedef void (^cameraCompletion)(void);

@protocol YACollectionViewControllerDelegate <NSObject>
- (void)showCamera:(BOOL)show showPart:(BOOL)showPart completion:(cameraCompletion)block;
- (void)enableRecording:(BOOL)enable;
@end

@interface YACollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate> {
    CGPoint lastOffset;
    NSTimeInterval lastOffsetCapture;
    BOOL isScrollingFast;
}

@property (strong, nonatomic) UICollectionView *collectionView;
@property (weak, nonatomic) id<YACollectionViewControllerDelegate> delegate;
@property (nonatomic) BOOL scrolling;
- (void)reload;
@end
