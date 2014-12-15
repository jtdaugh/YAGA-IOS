//
//  TileCell.m
//  Pic6
//
//  Created by Raj Vir on 5/22/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "TileCell.h"
#import "UIColor+Expanded.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "NSMutableArray+Shuffle.h"

@implementation TileCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [self addSubview:self.container];
        
        self.boxes = [NSMutableArray array];
        int width = self.frame.size.width / LOADER_WIDTH;
        int height = self.frame.size.height / LOADER_HEIGHT;
        [self.loader removeFromSuperview];
        
        self.loader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.container.frame.size.width, self.container.frame.size.height)];
        
        for(int i = 0; i < LOADER_HEIGHT * LOADER_WIDTH; i++){
            UIView *box = [[UIView alloc] initWithFrame:CGRectMake((i%4) * self.loader.frame.size.width/LOADER_WIDTH, (i/LOADER_HEIGHT) * self.loader.frame.size.height/LOADER_HEIGHT, width, height)];
            [self.boxes addObject:box];
            [self.loader addSubview:box];
        }
        
        //        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1
        //                                                          target:self
        //                                                        selector:@selector(loaderTick:)
        //                                                        userInfo:nil
        //                                                         repeats:YES];
        //
        //        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        //        [self loaderTick:nil];
        [self.container addSubview:self.loader];
        
        self.image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [self.image setContentMode:UIViewContentModeScaleAspectFill];
        [self.image setClipsToBounds:YES];
        [self.container addSubview:self.image];
        
//        [self setBackgroundColor:[UIColor redColor]];
        
    }
    return self;
}

- (void)setVideoFrame:(CGRect)frame {
    [self setFrame:frame];
    [self.image setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.playerLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.playerContainer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
}

- (void)showLoader {
    
    NSLog(@"showing loader! %@", self.uid);
    
    self.state = [NSNumber numberWithInt:LOADING];
    [self.image removeFromSuperview];
    [self.playerContainer removeFromSuperview];
    // Initialization code
}

- (void)loaderTick:(NSTimer *) timer {
    NSMutableArray *colors = [self.colors mutableCopy];
    [colors shuffle];
    
    for(UIView *box in self.boxes){
        if([colors count] > 0){
            NSString *next = [colors lastObject];
            UIColor *color = [UIColor colorWithHexString:next];
            //            NSLog(@"next: %@", next);
            
            //            UIColor *randomColor = [UIColor randomColor];
            //            UIColor *randomColor = [UIColor randomLightColor:0.3];
            [box setBackgroundColor:color];
            
            //            [box setBackgroundColor:[UIColor whiteColor]];
            [colors removeLastObject];
        } else {
            CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
            CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
            CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
            UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:arc4random() % 128 / 256.0 + 0.5];
            [box setBackgroundColor:color];
        }
    }
    
}

- (void)showImage {
    self.state = [NSNumber numberWithInt:LOADED];
    
    [self.playerContainer removeFromSuperview];
    [self.image removeFromSuperview];
    
    [self.image setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    
    NSString *imagePath = [[NSString alloc] initWithFormat:@"%@%@.jpg", NSTemporaryDirectory(), self.uid];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.image setImage:[UIImage imageWithData:imageData]];
            [self.container addSubview:self.image];
            [self.container bringSubviewToFront:self.image];
        });
    });
    
    
    if ([fileManager fileExistsAtPath:imagePath]){
    } else {
        NSLog(@"wtf? image");
    }
}

//LOAD IT UP
- (void)play:(void (^)())block {
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
            self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
            
            //            [cell.playerContainer setBackgroundColor:[UIColor redColor]];
            self.playerLayer.frame = self.playerContainer.frame;
            
            // play video in frame
            [self.playerContainer.layer addSublayer: self.playerLayer];
            //        [self.loader removeFromSuperview];
            //            [self addSubview:self.playerContainer];
            [self.container addSubview:self.playerContainer];
            [self.container bringSubviewToFront:self.playerContainer];
            //            [self.container insertSubview:self.playerContainer aboveSubview:self.image];
            
            
            [self.player setVolume:0.0];
            if(block){
                block();
            }
            [self.player asyncPlay];
            
            [self.player setLooping];
        });
    });
}

- (void)playLocal:(NSString *)path {
    self.state = [NSNumber numberWithInt:PLAYING];
    @autoreleasepool {
        
        NSString *moviePath = path;
        //    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), self.uid];
        NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if ([fileManager fileExistsAtPath:moviePath]){
            
            self.player = [AVPlayer playerWithURL:movieURL];
            self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
            
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
            
            // set video sizing
            [self.playerContainer removeFromSuperview];
            self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
            //            [cell.playerContainer setBackgroundColor:[UIColor redColor]];
            self.playerLayer.frame = self.playerContainer.frame;
            
            // play video in frame
            [self.playerContainer.layer addSublayer: self.playerLayer];
            //        [self.loader removeFromSuperview];
            [self.container addSubview:self.playerContainer];
            
            [self.player setVolume:0.0];
            [self.player asyncPlay];
            
            [self.player setLooping];
            // set looping
        } else {
            NSLog(@"wtf?");
        }
        
    }
}

+ (BOOL)isLoaded:(NSString *)uid {
    // make this less laggy; use a dictionary
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
        [self.player removeObservers];
    }
}

- (void)showIndicator {
    CGFloat height = 12;
    if(!self.indicator){
        self.indicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, height)];
        [self.indicator setBackgroundColor:SECONDARY_COLOR];
        [self.indicator setAlpha:0.7];
    }
    
    [self addSubview:self.indicator];
    [self.indicator setFrame:CGRectMake(0, 0, 0, height)];
    
    CGFloat duration = CMTimeGetSeconds(self.player.currentItem.asset.duration);
    
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        //
        [self.indicator setFrame:CGRectMake(0, 0, self.frame.size.width, height)];
    } completion:^(BOOL finished) {
        //
        if(finished){
            [self.indicator removeFromSuperview];
        }
    }];
}

- (void) setSelected:(BOOL)selected {
    if(selected){
        NSLog(@"playing");
        CGFloat scrollOffset = ((UICollectionView *)[self superview]).contentOffset.x;
        
        if(self.frame.origin.x - scrollOffset == 0){
            [self.player setVolume:1.0];
        }
    } else {
        NSLog(@"muting");
        [self.player setVolume:0.0];
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
