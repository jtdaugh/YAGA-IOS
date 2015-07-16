//
//  ShareViewController.m
//  YAVideoShareExtension
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAShareVideoViewController.h"
#import "YAVideoPlayerView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define NUM_OF_COPIES 100

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;

@interface YAShareVideoViewController ()

@property (nonatomic, strong) YAVideoPlayerView *playerView;

@property (strong) AVPlayerItem* playerItem;
@property (nonatomic, strong) AVPlayer* player;

@end

@implementation YAShareVideoViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _playerView = [YAVideoPlayerView new];
    [self.view addSubview:self.playerView];
    
    [self loadExtensionItem];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Extensions

- (void)loadExtensionItem {
    NSExtensionItem *item = self.extensionContext.inputItems[0];
    NSItemProvider *itemProvider = item.attachments[0];
    
    if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSURL *movieURL, NSError *error) {
            
            if (movieURL) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    /*
                     Create an asset for inspection of a resource referenced by a given URL.
                     Load the values for the asset key "playable".
                     */
                    AVAsset *asset = [self makeAssetCompositionFromAsset:[AVURLAsset URLAssetWithURL:movieURL options:nil]];
                    
                    NSArray *requestedKeys = @[@"playable"];
                    
                    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
                    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
                     ^{
                         dispatch_async( dispatch_get_main_queue(), ^{
                             [self prepareToPlayAsset:asset withKeys:requestedKeys];
                            });
                     }];
                    
                });
            }
        }];
    }
}

#pragma mark - AVAsset

/*
 Shared code with \c YAVideoPlayerView
 */
- (void)prepareToPlayAsset:(AVAsset *)asset withKeys:(NSArray *)requestedKeys
{
//    self.readyToPlay = NO;
    
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
    if (self.playerItem)
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
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:self.playerItem];
            
            
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

- (AVAsset*)makeAssetCompositionFromAsset:(AVAsset*)sourceAsset {
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    
    // calculate time
    CMTimeRange editRange = CMTimeRangeMake(CMTimeMake(0, 600), CMTimeMake(sourceAsset.duration.value, sourceAsset.duration.timescale));
    
    NSError *editError;
    
    // and add into your composition
    BOOL result = [composition insertTimeRange:editRange ofAsset:sourceAsset atTime:composition.duration error:&editError];
    
    if (result) {
        for (int i = 0; i < NUM_OF_COPIES; i++) {
            [composition insertTimeRange:editRange ofAsset:sourceAsset atTime:composition.duration error:&editError];
        }
    }
    
    AVAssetTrack *assetVideoTrack = [sourceAsset tracksWithMediaType:AVMediaTypeVideo].lastObject;
    AVMutableCompositionTrack *compositionVideoTrack = [composition tracksWithMediaType:AVMediaTypeVideo].lastObject;
    [compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    
    
    return composition;
}

#pragma mark - Video

- (void)prepareVideoForPlaying:(NSString *)filename {
    NSURL *movUrl = [YAShareVideoViewController urlFromFileName:filename];
    
    if (filename.length) {
        self.playerView.URL = movUrl;
    } else {
        self.playerView.URL = nil;
    }
    
    self.playerView.frame = self.view.bounds;
}

+ (NSURL *)urlFromFileName:(NSString *)fileName {
    if(!fileName.length)
        return nil;
    
    NSString *path = [[YAShareVideoViewController cachesDirectory] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}

+ (NSString *)cachesDirectory {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return cachePaths[0];
}

#pragma mark - Notification handlers

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    
}

@end
