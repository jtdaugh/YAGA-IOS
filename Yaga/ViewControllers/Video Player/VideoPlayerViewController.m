//This file is part of MyVideoPlayer.
//
//MyVideoPlayer is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//MyVideoPlayer is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with MyVideoPlayer.  If not, see <http://www.gnu.org/licenses/>.

#import "VideoPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoPlayerView.h"

@interface VideoPlayerViewController ()

@end

static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;

@implementation VideoPlayerViewController

@synthesize URL = _URL;
@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize playerView = _playerView;

#pragma mark - UIView lifecycle

- (void)loadView {
    VideoPlayerView *playerView = [[VideoPlayerView alloc] init];
    self.view = playerView;
    
    self.playerView = playerView;
}

#pragma mark - Private methods

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            NSLog(@"failed %@", self.URL.absoluteString.lastPathComponent);
            return;
        }
    }
    
    if (!asset.playable) {
        return;
    }
    
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }

    AVMutableComposition *comp = [[AVMutableComposition alloc] init];
    for(int i = 0; i < 100; i++) {
        [comp insertTimeRange:CMTimeRangeMake(CMTimeMake(0, 1), CMTimeMake(asset.duration.value, asset.duration.timescale)) ofAsset:asset atTime:comp.duration error:nil];
    }
    
    //self.playerItem = [AVPlayerItem playerItemWithAsset:comp];

    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    
    if (![self player]) {
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
    }
    
    if (self.player.currentItem != self.playerItem) {
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
    }
}


#pragma mark - Key Valye Observing

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    
    if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            _readyToPlay = YES;
            self.player.volume = 0;
            
            NSLog(@"%@ ready to play", self.URL.absoluteString.lastPathComponent);
            
             [self.player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopped:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        }
    } else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        if (newPlayerItem) {
            [self.playerView setPlayer:self.player];
            [self.playerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
        }
    } else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}


#pragma mark - Public methods

- (void)setURL:(NSURL*)URL {
    _URL = [URL copy];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_URL options:nil];
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                            [self prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
}

- (NSURL*)URL {
    return _URL;
}

- (void)dealloc {
    [self.player removeObserver:self forKeyPath:kCurrentItemKey];
    [self.player.currentItem removeObserver:self forKeyPath:kStatusKey];
    [self.player pause];
}

- (void)stopped:(NSNotification*)notif {
    self.pendingReplay = YES;
    
    AVPlayerItem *p = [notif object];
    [p seekToTime:kCMTimeZero];
}

- (void)play:(BOOL)value {
    if(value && self.readyToPlay && !self.playing) {
        [self.player play];
        NSLog(@"playing - %@", [self.URL.absoluteString lastPathComponent]);
        _playing = YES;
    }
    else if(!value && self.playing) {
        [self.player pause];
        _playing = NO;
        NSLog(@"pausing - %@", [self.URL.absoluteString lastPathComponent]);
    }
    else {
        
    }
}
@end
