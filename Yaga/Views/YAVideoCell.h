//
//  TiCell.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import <UIKit/UIKit.h>
#import "FLAnimatedImage.h"
#import "AVPlaybackViewController.h"
#import "YAVideo.h"

typedef NS_ENUM(NSUInteger, YAVideoCellState) {
    YAVideoCellStateLoading = 0,
    YAVideoCellStateJPEGPreview,
    YAVideoCellStateGIFPreview,
    YAVideoCellStateVideoPreview,
};

@interface YAVideoCell : UICollectionViewCell<UITextFieldDelegate>
@property (nonatomic, strong) YAVideo *video;
- (void)animateGifView:(BOOL)animate;
//- (void)destroyVideoPlayer;
@end
