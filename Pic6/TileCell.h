//
//  TileCell.h
//  Pic6
//
//  Created by Raj Vir on 5/22/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define FETCHING 0
#define LOADED 1
#define PREPARING 2
#define PLAYING 3

@interface TileCell : UICollectionViewCell
@property int state;
@property (strong, nonatomic) UIView *playerContainer;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;

@property (strong, nonatomic) UIImageView *image;

@property (strong, nonatomic) UIView *loader;

- (void)setVideoFrame:(CGRect)frame;
- (void)initLoaderWithSwatches:(NSArray *)swatches;
@end
