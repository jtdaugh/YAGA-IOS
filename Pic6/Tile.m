//
//  Tile.m
//  Pic6
//
//  Created by Raj Vir on 5/6/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "Tile.h"

@implementation Tile

- (void)setVideoFrame:(CGRect)frame {
    [self.view setFrame:frame];
    [self.playerLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.playerContainer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
}

- (void)setCarouselPosition:(int)currentPosition withIndex:(int)index {
    int offset = index - currentPosition;
    if(offset != 0){
        int origin, m;
        if(offset>0){
            origin = VIEW_WIDTH/2 + ENLARGED_WIDTH/2 + 5;
            m = -1;
        } else if(offset < 0){
            origin = VIEW_WIDTH/2 - ENLARGED_WIDTH/2 - 5 - CAROUSEL_WIDTH;
            m = 1;
        }
        [self setVideoFrame:CGRectMake(origin + (offset+m)*ENLARGED_WIDTH, TILE_HEIGHT + (VIEW_WIDTH-ENLARGED_WIDTH)/2 + (ENLARGED_WIDTH - CAROUSEL_WIDTH)/2, CAROUSEL_WIDTH, CAROUSEL_HEIGHT)];
        [self.player setVolume:0.0];
    } else {
        [self.player setVolume:1.0];
        [self setVideoFrame:CGRectMake((VIEW_WIDTH-ENLARGED_WIDTH)/2, TILE_HEIGHT + (VIEW_WIDTH-ENLARGED_WIDTH)/2, ENLARGED_WIDTH, ENLARGED_HEIGHT)];
    }
    
//    offset = position * (ENLARGED_WIDTH + 10);
    //    [self setFrame:CGRectMake(500, 500, CAROUSEL_WIDTH, CAROUSEL_HEIGHT)];
}

- (void)setCarouselPosition:(int)position {
//    int gutter = (VIEW_WIDTH - ENLARGED_WIDTH - CAROUSEL_MARGIN*2);
    [self setVideoFrame:CGRectMake(CAROUSEL_MARGIN + (ENLARGED_WIDTH+CAROUSEL_MARGIN)*position, 0, ENLARGED_WIDTH, ENLARGED_HEIGHT)];
}

- (void)setGridPosition:(int)position {
    int x, y;
    x = position%2 * TILE_WIDTH;
    y = position/2 * TILE_HEIGHT;
    [self setVideoFrame:CGRectMake(x, y, TILE_WIDTH, TILE_HEIGHT)];
}


@end
