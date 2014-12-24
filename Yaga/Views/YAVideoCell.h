//
//  TiCell.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import <UIKit/UIKit.h>
#import "FLAnimatedImage.h"
#import "VideoPlayerView.h"

@interface YAVideoCell : UICollectionViewCell
@property (nonatomic, strong) FLAnimatedImageView *gifView;
@property (nonatomic, strong) FLAnimatedImage *gifImage;
@property (nonatomic, strong) VideoPlayerView *playerView;
@end
