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
@end
