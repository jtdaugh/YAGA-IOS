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
    int origin;
    if(offset > 0){
        origin = VIEW_WIDTH/2 + ENLARGED_WIDTH/2 + 5;
        [self setVideoFrame:CGRectMake(origin + (offset-1)*ENLARGED_WIDTH, TILE_HEIGHT + (VIEW_WIDTH-ENLARGED_WIDTH)/2, ENLARGED_WIDTH, ENLARGED_HEIGHT)];
    } else if(offset < 0){
        origin = VIEW_WIDTH/2 - ENLARGED_WIDTH/2 - 5 - ENLARGED_WIDTH;
        [self setVideoFrame:CGRectMake(origin + (offset+1)*ENLARGED_WIDTH, TILE_HEIGHT + (VIEW_WIDTH-ENLARGED_WIDTH)/2, ENLARGED_WIDTH, ENLARGED_HEIGHT)];
    } else {
        [self setVideoFrame:CGRectMake((VIEW_WIDTH-ENLARGED_WIDTH)/2, TILE_HEIGHT + (VIEW_WIDTH-ENLARGED_WIDTH)/2, ENLARGED_WIDTH, ENLARGED_HEIGHT)];
    }
//    offset = position * (ENLARGED_WIDTH + 10);
    //    [self setFrame:CGRectMake(500, 500, CAROUSEL_WIDTH, CAROUSEL_HEIGHT)];
}

@end
