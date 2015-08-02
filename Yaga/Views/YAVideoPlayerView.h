//
//  YAPlayerView.h
//  testReuse
//
//  Created by valentinkovalski on 1/13/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol YAVideoPlayerViewDelegate <NSObject>
- (void)playbackProgressChanged:(CGFloat)progress duration:(CGFloat)duration;
@end

@interface YAVideoPlayerView : UIView {
    NSURL *_URL;
}

@property (nonatomic, strong) AVPlayer* player;

@property (nonatomic, copy) NSURL* URL;
@property (nonatomic) CMTime initialSeekTime;

@property (nonatomic, assign) BOOL playWhenReady;
@property (nonatomic, assign) BOOL readyToPlay;
@property (nonatomic, assign) BOOL smoothLoopingComposition;
@property (nonatomic, assign) BOOL dontHandleLooping;

@property (nonatomic, weak) id<YAVideoPlayerViewDelegate> delegate;

- (BOOL)isPlaying;
- (void)play;
- (void)pause;
@end
