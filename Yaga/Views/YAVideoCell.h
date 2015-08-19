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

@protocol YAOpenGroupFromVideoCell <NSObject>

- (void)openGroupForVideo:(YAVideo *)video;

@end

@interface YAVideoCell : UICollectionViewCell<UITextFieldDelegate>

@property (nonatomic, strong) YAVideo *video;

@property (nonatomic, weak) id<YAOpenGroupFromVideoCell> groupOpener;
@property (nonatomic) BOOL showsGroupLabel;
@property (nonatomic) CGFloat groupLabelHeightProportion;

@property (nonatomic) BOOL showVideoStatus;

- (void)animateGifView:(BOOL)animate;

- (void)renderLightweightContent;
- (void)renderHeavyWeightContent;

- (void)setEventCount:(NSUInteger)eventCount;

@end
