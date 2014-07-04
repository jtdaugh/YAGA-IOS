//
//  TileCell.h
//  Pic6
//
//  Created by Raj Vir on 5/22/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define LOADING 0
#define PLAYING 1

@interface TileCell : UICollectionViewCell
@property int state;
@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) UIView *playerContainer;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;

@property (strong, nonatomic) UIImageView *image;

@property (strong, nonatomic) UIView *loader;

@property (strong, nonatomic) NSMutableArray *boxes;

- (void)setVideoFrame:(CGRect)frame;
- (void)showLoader;
- (void)play;
//- (void)initLoaderWithSwatches:(NSArray *)swatches;
- (BOOL)isLoaded;
+ (BOOL)isLoaded:(NSString *)uid;
@end
