//
//  TileCell.m
//  Pic6
//
//  Created by Raj Vir on 5/22/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "TileCell.h"
#import "AVPlayer+AVPlayer_Async.h"

@implementation TileCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setVideoFrame:(CGRect)frame {
    [self setFrame:frame];
    [self.playerLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.playerContainer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
}

//- (void)showLoader {
//    NSLog(@"setting to red!");
//    self.state = LOADING;
//    for(UIView *v in self.subviews){
//        [v removeFromSuperview];
//    }
//}


- (void)showLoader {
    self.state = LOADING;
    [self.playerContainer removeFromSuperview];
    // Initialization code
    self.boxes = [NSMutableArray array];
    int width = self.frame.size.width / LOADER_WIDTH;
    int height = self.frame.size.height / LOADER_HEIGHT;
    [self.loader removeFromSuperview];
    self.loader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    
    for(int i = 0; i < LOADER_HEIGHT * LOADER_WIDTH; i++){
        UIView *box = [[UIView alloc] initWithFrame:CGRectMake((i%4) * TILE_WIDTH/LOADER_WIDTH, (i/LOADER_HEIGHT) * TILE_HEIGHT/LOADER_HEIGHT, width, height)];
        [self.boxes addObject:box];
        [self.loader addSubview:box];
    }
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                      target:self
                                                    selector:@selector(loaderTick:)
                                                    userInfo:nil
                                                     repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [self addSubview:self.loader];
}

- (void)loaderTick:(NSTimer *) timer {
    for(UIView *box in self.boxes){
        [box setBackgroundColor:[UIColor colorWithRed:((float)arc4random() / ARC4RANDOM_MAX) green:((float)arc4random() / ARC4RANDOM_MAX) blue:((float)arc4random() / ARC4RANDOM_MAX) alpha:0.5]];
    }
}

//LOAD IT UP
- (void)play {
    self.state = PLAYING;
    
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), self.uid];
    NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:moviePath]){
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:movieURL];
        self.player = [AVPlayer playerWithPlayerItem:playerItem];

        self.player = [AVPlayer playerWithURL:movieURL];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];


        [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        // set video sizing
        [self.playerContainer removeFromSuperview];
        self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
        //            [cell.playerContainer setBackgroundColor:[UIColor redColor]];
        self.playerLayer.frame = self.playerContainer.frame;

        // play video in frame
        [self.playerContainer.layer addSublayer: self.playerLayer];
//        [self.loader removeFromSuperview];
        [self addSubview:self.playerContainer];
        
        NSLog(@"%lu", [self.subviews count]);

        [self.player setVolume:0.0];
        [self.player play];

        // set looping
        [self.player setLooping];
    } else {
     NSLog(@"wtf?");
    }
    
}

+ (BOOL)isLoaded:(NSString *)uid {
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), uid];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // init loader
    
    if ([fileManager fileExistsAtPath:moviePath]){
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isLoaded {
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), self.uid];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // init loader
    if ([fileManager fileExistsAtPath:moviePath]){
        return YES;
    } else {
        return NO;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
