//
//  YACenterImageButton.m
//  Yaga
//
//  Created by Raj Vir on 6/3/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACenterImageButton.h"

@implementation YACenterImageButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.imageView.frame;
    frame = CGRectMake(truncf((self.bounds.size.width - frame.size.width) / 2), 12.0f, frame.size.width, frame.size.height);
    self.imageView.frame = frame;
    
    frame = self.titleLabel.frame;
    frame = CGRectMake(truncf((self.bounds.size.width - frame.size.width) / 2), self.bounds.size.height - frame.size.height - 12.0, frame.size.width, frame.size.height);
    self.titleLabel.frame = frame;
}

@end
