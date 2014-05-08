//
//  Tile.h
//  Pic6
//
//  Created by Raj Vir on 5/6/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Firebase/Firebase.h>
#import "LoaderTileView.h"

@interface Tile : NSObject
@property (strong, nonatomic) FDataSnapshot *data;
@property (strong, nonatomic) UIView *playerContainer;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;

@property (strong, nonatomic) UIView *view;

@property (strong, nonatomic) LoaderTileView *loader;

@property BOOL enlarged;

- (void)setVideoFrame:(CGRect)frame;

@end
