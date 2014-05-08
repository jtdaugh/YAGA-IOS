//
//  UIView+Grid.m
//  Pic6
//
//  Created by Raj Vir on 5/4/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "UIView+Grid.h"

@implementation UIView (Grid)

- (void)setGridPosition:(int)position {
    int x, y;
    x = position%2 * TILE_WIDTH;
    y = position/2 * TILE_HEIGHT;
    [self setFrame:CGRectMake(x, y, TILE_WIDTH, TILE_HEIGHT)];
}

- (void)setCarouselPosition:(int)position {
    int x, origin;
    if(x > 0){
        origin = 320 - (320 - ENLARGED_WIDTH)/2 + 5;
    } else {
        origin = (320 - ENLARGED_WIDTH)/2 - 5;
    }
    x = position * ENLARGED_WIDTH;
//    [self setFrame:CGRectMake(x, 100, CAROUSEL_WIDTH, CAROUSEL_HEIGHT)];
    [self setFrame:CGRectMake(500, 500, CAROUSEL_WIDTH, CAROUSEL_HEIGHT)];
}

@end
