//
//  YAPlayerView.h
//  testReuse
//
//  Created by valentinkovalski on 1/13/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface YAVideoPlayerView : UIView {
    NSURL *_URL;
}

@property (nonatomic, strong) AVPlayer* player;

@property (nonatomic, copy) NSURL* URL;

@property (nonatomic, assign) BOOL playWhenReady;
@property (nonatomic, assign) BOOL readyToPlay;

- (BOOL)isPlaying;
- (void)play;
- (void)pause;
@end
