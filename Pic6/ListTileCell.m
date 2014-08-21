//
//  ListTileCell.m
//  Pic6
//
//  Created by Raj Vir on 8/19/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "ListTileCell.h"

@implementation ListTileCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat width = self.frame.size.width;
        CGFloat height = 36;
        CGFloat y = self.frame.size.height - height;
        
        self.groupTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, y, width, height)];
        [self.groupTitle setTextColor:[UIColor whiteColor]];
        [self addSubview:self.groupTitle];
        [self bringSubviewToFront:self.groupTitle];
        
        [self.groupTitle setTextAlignment:NSTextAlignmentCenter];
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
