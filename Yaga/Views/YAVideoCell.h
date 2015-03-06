//
//  TiCell.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import <UIKit/UIKit.h>
#import "FLAnimatedImage.h"
#import "YAVideo.h"

typedef NS_ENUM(NSUInteger, YAVideoCellState) {
    YAVideoCellStateLoading = 0,
    YAVideoCellStateJPEGPreview,
    YAVideoCellStateGIFPreview,
    YAVideoCellStateVideoPreview,
};

@interface YAVideoCell : UICollectionViewCell<UITextFieldDelegate>

@property (nonatomic, strong) YAVideo *video;
@property (nonatomic, strong) UILabel *toolTipLabel;

- (void)animateGifView:(BOOL)animate;

//- (void)invalidateVideoPlayer;

@end
