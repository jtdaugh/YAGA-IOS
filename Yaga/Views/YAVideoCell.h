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

@interface YAVideoCell : UICollectionViewCell
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) AVPlaybackViewController *playerVC;
@end
