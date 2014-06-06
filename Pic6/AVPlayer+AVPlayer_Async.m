//
//  AVPlayer+AVPlayer_Async.m
//  Pic6
//
//  Created by Raj Vir on 6/5/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "AVPlayer+AVPlayer_Async.h"

@implementation AVPlayer (AVPlayer_Async)

static const NSString *ItemStatusContext;
static const NSString *ReplaceItemStatusContext;

- (void)asyncPlay {
    [self.currentItem addObserver:self forKeyPath:@"status"
                                          options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
    NSLog(@"yoo");
    
}

- (void)asyncReplaceWithPlayerItem:(AVPlayerItem *) playerItem {
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&ReplaceItemStatusContext];
    NSLog(@"async replacing beginning");
}

- (void)asyncReplace {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        NSLog(@"yoooo");
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self play];
                       });
        return;
    } else if(context == &ReplaceItemStatusContext) {
        NSLog(@"about to replace");
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self replaceCurrentItemWithPlayerItem:object];
                       });
    }
    
//    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
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
}

@end
