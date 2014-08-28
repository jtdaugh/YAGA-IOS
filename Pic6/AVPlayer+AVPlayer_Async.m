//
//  AVPlayer+AVPlayer_Async.m
//  Pic6
//
//  Created by Raj Vir on 6/5/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "AVPlayer+AVPlayer_Async.h"

@implementation AVPlayer (AVPlayer_Async)

- (void)asyncPlay {
    [self addObserver:self forKeyPath:@"status"
                                          options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {

    if(object == self && [keyPath isEqualToString:@"status"]){
        if(self.status == AVPlayerStatusReadyToPlay){
            [self play];
            [self removeObserver:self forKeyPath:@"status"];
        }
    }
}

- (void)setLooping {
    // set looping
    
    [self setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self currentItem]];
    
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    [self setVolume:0.0];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
