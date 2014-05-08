//
//  LoaderTileView.m
//  Pic6
//
//  Created by Raj Vir on 5/7/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "LoaderTileView.h"

@implementation LoaderTileView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Initialization code
        self.boxes = [NSMutableArray array];
        int width = frame.size.width / LOADER_WIDTH;
        int height = frame.size.height / LOADER_HEIGHT;
        for(int i = 0; i < LOADER_HEIGHT * LOADER_WIDTH; i++){
            UIView *box = [[UIView alloc] initWithFrame:CGRectMake((i%4) * TILE_WIDTH/LOADER_WIDTH, (i/LOADER_HEIGHT) * TILE_HEIGHT/LOADER_HEIGHT, width, height)];
            [self.boxes addObject:box];
            [self addSubview:box];
        }
        
//        [self setBackgroundColor:PRIMARY_COLOR];
        
        
        [self loaderTick:[NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(loaderTick:)
                                       userInfo:nil
                                        repeats:YES]];
    }
    return self;
}

- (void)loaderTick:(NSTimer *) timer {
    for(UIView *box in self.boxes){
        [box setBackgroundColor:[UIColor colorWithRed:((float)arc4random() / ARC4RANDOM_MAX) green:((float)arc4random() / ARC4RANDOM_MAX) blue:((float)arc4random() / ARC4RANDOM_MAX) alpha:0.5]];
    }
}

// [box setBackgroundColor:[UIColor colorWithRed:((float)arc4random() / ARC4RANDOM_MAX) green:((float)arc4random() / ARC4RANDOM_MAX) blue:((float)arc4random() / ARC4RANDOM_MAX) alpha:0.5]];


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
