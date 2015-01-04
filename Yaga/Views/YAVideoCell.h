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

@interface YAVideoCell : UICollectionViewCell<UITextFieldDelegate>
@property (nonatomic, strong) YAVideo *video;
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) AVPlaybackViewController *playerVC;
- (void)showLoading:(BOOL)show;
@end
