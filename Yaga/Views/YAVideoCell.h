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
@property (nonatomic, assign) BOOL shouldPlayGifAutomatically;

- (void)animateGifView:(BOOL)animate;

- (void)setEventCount:(NSUInteger)eventCount;

@end
