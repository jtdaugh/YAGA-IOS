//
//  TiCell.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YAVideoCell.h"

@implementation YAVideoCell

- (void)setVideoPlayer:(UIViewController *)videoPlayer {
    _videoPlayer = videoPlayer;
    [self addSubview:videoPlayer.view];
    videoPlayer.view.frame = self.bounds;
    videoPlayer.view.autoresizingMask  = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)dealloc {
    
}

@end
