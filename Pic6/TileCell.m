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
        [self loaderTick:nil];
        [self addSubview:self.loader];
        
        self.image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [self.image setContentMode:UIViewContentModeScaleAspectFill];
        [self.image setClipsToBounds:YES];
        [self addSubview:self.image];
    }
    return self;
}

- (void)setVideoFrame:(CGRect)frame {
    [self setFrame:frame];
    [self.playerLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.playerContainer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
}

- (void)showLoader {
    self.state = [NSNumber numberWithInt:LOADING];
    [self.image removeFromSuperview];
    [self.playerContainer removeFromSuperview];
    // Initialization code
}

- (void)loaderTick:(NSTimer *) timer {
    for(UIView *box in self.boxes){
        [box setBackgroundColor:[UIColor colorWithRed:((float)arc4random() / ARC4RANDOM_MAX) green:((float)arc4random() / ARC4RANDOM_MAX) blue:((float)arc4random() / ARC4RANDOM_MAX) alpha:0.5]];
    }
}

- (void)showImage {
    self.state = [NSNumber numberWithInt:LOADED];
    
    [self.playerContainer removeFromSuperview];
    [self.image removeFromSuperview];
    
    NSString *imagePath = [[NSString alloc] initWithFormat:@"%@%@.jpg", NSTemporaryDirectory(), self.uid];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.image setImage:[UIImage imageWithData:imageData]];
            [self addSubview:self.image];
        });
    });
    
    
    if ([fileManager fileExistsAtPath:imagePath]){
    } else {
        NSLog(@"wtf? image");
    }
}

//LOAD IT UP
- (void)play {
    self.state = [NSNumber numberWithInt:PLAYING];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), self.uid];
        NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:movieURL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.player = [AVPlayer playerWithPlayerItem:playerItem];
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
            [self bringSubviewToFront:self.playerContainer];
            
            [self.player setVolume:0.0];
            [self.player asyncPlay];
            
            [self.player setLooping];
        });
    });
}

- (void)playLocal:(NSString *)path {
    self.state = [NSNumber numberWithInt:PLAYING];
    
    NSString *moviePath = path;
//    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), self.uid];
    NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:moviePath]){
        
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
        
        [self.player setVolume:0.0];
        [self.player asyncPlay];
        
        [self.player setLooping];
        // set looping
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

- (void)prepareForReuse {
    if(self.player){
        NSLog(@"preparing for reuse!");
        [self.player removeObservers];
    }
}

//- (void)dealloc {
//    if(self.player){
//        NSLog(@"dealloc!");
////        [self.player removeObservers];        
//    }
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
