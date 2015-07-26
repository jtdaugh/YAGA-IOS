//
//  YAPlayerView.m
//  testReuse
//
//  Created by valentinkovalski on 1/13/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import "YAVideoPlayerView.h"

#import "YAViewCountManager.h"
#import "YAWeakTimerTarget.h"

#define NUM_OF_COPIES 100

@interface YAVideoPlayerView ()
@property (strong) AVPlayerItem* playerItem;
@property (nonatomic, strong) NSTimer *viewCountTimer;
@property (nonatomic, strong) id playbackObserver;
@end

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;

#pragma mark -
@implementation YAVideoPlayerView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return self;
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (void)updatePlayerLayer {
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    [playerLayer setPlayer:self.player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void)setReadyToPlay:(BOOL)readyToPlay {
    _readyToPlay = readyToPlay;
    
    if(self.readyToPlay && self.playWhenReady) {
        [self play];
    }
}

- (void)setPlayWhenReady:(BOOL)playWhenReady {
    _playWhenReady = playWhenReady;
    
    if(self.readyToPlay && playWhenReady)
        [self play];
}

#pragma mark Asset URL

- (AVAsset*)makeAssetCompositionFromAsset:(AVAsset*)sourceAsset {
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    
    // calculate time
    CMTimeRange editRange = CMTimeRangeMake(CMTimeMake(0, 600), CMTimeMake(sourceAsset.duration.value, sourceAsset.duration.timescale));
    
    NSError *editError;
    
    // and add into your composition
    BOOL result = [composition insertTimeRange:editRange ofAsset:sourceAsset atTime:composition.duration error:&editError];
    
    if (result) {
        for (int i = 0; i < [self numberOfCopies]; i++) {
            [composition insertTimeRange:editRange ofAsset:sourceAsset atTime:composition.duration error:&editError];
        }
    }
    
    AVAssetTrack *assetVideoTrack = [sourceAsset tracksWithMediaType:AVMediaTypeVideo].lastObject;
    AVMutableCompositionTrack *compositionVideoTrack = [composition tracksWithMediaType:AVMediaTypeVideo].lastObject;
    [compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    
    
    return composition;
}

- (void)setURL:(NSURL*)newURL
{
    if ([self.URL.absoluteString isEqualToString:newURL.absoluteString])
        return;
    
    //DLog(@"%@ preparing to play", newURL.lastPathComponent);
    
    _URL = [newURL copy];
    
    if(self.player) {
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    
    self.readyToPlay = NO;
    self.playWhenReady = NO;
    
    if(!self.URL)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset key "playable".
         */
        AVAsset *originalAsset = [AVURLAsset URLAssetWithURL:self.URL options:nil];
        
        AVAsset *asset;
        if(self.smoothLoopingComposition){
            asset = [self makeAssetCompositionFromAsset:originalAsset];
        } else {
            asset = originalAsset;
        }
        
        NSArray *requestedKeys = @[@"playable"];
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
         ^{
             dispatch_async( dispatch_get_main_queue(),
                            ^{
                                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                                [self prepareToPlayAsset:asset withKeys:requestedKeys];
                            });
         }];
        
    });
}

#pragma mark
- (void)dealloc
{
    
    [self.player removeTimeObserver:self.playbackObserver];
    self.playbackObserver = nil;
    
    [[YAViewCountManager sharedManager] stoppedWatchingVideo];
    [self.player removeObserver:self forKeyPath:@"currentItem"];
    [self.player removeObserver:self forKeyPath:@"rate"];
    if(!self.dontHandleLooping){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    }
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    
    [self.player pause];
    self.playerItem = nil;
    self.player = nil;
    
    DLog(@"YAVideoPlayerView deallocated");
}

- (BOOL)isPlaying
{
    return [self.player rate] != 0.f;
}


#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark Prepare to play asset, URL

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVAsset *)asset withKeys:(NSArray *)requestedKeys
{
    self.readyToPlay = NO;
    
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            DLog(@"assetFailedToPrepareForPlayback");
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Display the error to the user. */
        DLog(@"assetFailedToPrepareForPlayback");
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem && !self.dontHandleLooping)
    {
        /* Remove existing player item key value observers and notifications. */
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        //        [[NSNotificationCenter defaultCenter] removeObserver:self
        //                                                        name:AVPlayerItemDidPlayToEndTimeNotification
        //                                                      object:self.playerItem];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            /* Observe the player item "status" key to determine when it is ready to play. */
            [self.playerItem addObserver:self
                              forKeyPath:@"status"
                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
            
            if(!self.dontHandleLooping){
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:self.playerItem];
            }
            
            
            /* Create new player, if we don't already have one. */
            if (!self.player)
            {
                /* Get a new AVPlayer initialized to play the specified player item. */
                [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
                self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                
                /* Observe the AVPlayer "currentItem" property to find out when any
                 AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
                 occur.*/
                [self.player addObserver:self
                              forKeyPath:@"currentItem"
                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
                
                /* Observe the AVPlayer "rate" property to update the scrubber control. */
                [self.player addObserver:self
                              forKeyPath:@"rate"
                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
            }
            
            /* Make our new AVPlayerItem the AVPlayer's current item. */
            if (self.player.currentItem != self.playerItem)
            {
                /* Replace the player item with a new player item. The item replacement occurs
                 asynchronously; observe the currentItem property to find out when the
                 replacement will/did occur
                 
                 If needed, configure player item here (example: adding outputs, setting text style rules,
                 selecting media options) before associating it with a player
                 */
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
            }
        });
    });
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext)
    {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown:
            {
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                self.readyToPlay = YES;
            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                DLog(@"assetFailedToPrepareForPlayback %@", playerItem.error);
            }
                break;
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == AVPlayerDemoPlaybackViewControllerRateObservationContext)
    {
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [self updatePlayerLayer];
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

- (void)play {
    float singlePlayTime = CMTimeGetSeconds(self.playerItem.asset.duration) / (float) [self numberOfCopies];
    [[YAViewCountManager sharedManager] didBeginWatchingVideoWithInterval:singlePlayTime];
    
    [self.player play];
    
    //hide fullscreen jpg preview
    if(self.subviews.count && [self.subviews[0] isKindOfClass:[UIImageView class]]) {
        UIImageView *jpgView = self.subviews[0];
        //        [jpgView removeFromSuperview];
        [self sendSubviewToBack:jpgView];
    }
    
    //add playback observer
    [self.player removeTimeObserver:self.playbackObserver];
    
    CMTime interval = CMTimeMake(33, 1000);
    __weak typeof(self) weakSelf = self;
    
    self.playbackObserver = [self.player addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat endTime = CMTimeGetSeconds(weakSelf.player.currentItem.asset.duration);
        
        if (endTime != 0) {
            CGFloat currentTime = CMTimeGetSeconds(weakSelf.player.currentTime);
            CGFloat normalizedTime;
            if(self.dontHandleLooping){
                normalizedTime = currentTime;
            } else {
                normalizedTime = fmodf(currentTime, endTime/[weakSelf numberOfCopies]);
            }
            [weakSelf playbackProgressChanged:normalizedTime duration:endTime/[weakSelf numberOfCopies]];
        }
    }];
}

- (CGFloat) numberOfCopies {
    if(self.smoothLoopingComposition){
        return NUM_OF_COPIES;
    } else {
        return 1;
    }
}

- (void)pause {
    [self.player pause];
}

- (void)playbackProgressChanged:(CGFloat)progress duration:(CGFloat)duration {
    if([self.delegate respondsToSelector:@selector(playbackProgressChanged:duration:)]) {
        [self.delegate playbackProgressChanged:progress duration:duration];
    }
}


@end

//