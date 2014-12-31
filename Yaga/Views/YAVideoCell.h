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
@class YAVideoCell;
@protocol YAVideoCellDelegate <NSObject>
@optional
- (void)uploadMyVideo:(YAVideo*)video forSender:(YAVideoCell*)me;
@end

@interface YAVideoCell : UICollectionViewCell<UITextFieldDelegate>
@property (nonatomic, strong) YAVideo *video;
@property (nonatomic, weak) id<YAVideoCellDelegate> delegate;
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) AVPlaybackViewController *playerVC;
@end
