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

@interface YAVideoCell : UICollectionViewCell<UITextFieldDelegate>

@property (nonatomic, strong) YAVideo *video;

- (void)animateGifView:(BOOL)animate;

//- (void)invalidateVideoPlayer;

@end
