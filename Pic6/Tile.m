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

@end
