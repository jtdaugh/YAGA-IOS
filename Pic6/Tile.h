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

@interface Tile : NSObject
@property (strong, nonatomic) FDataSnapshot *metadata;
@property (strong, nonatomic) UIView *container;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;
@end
