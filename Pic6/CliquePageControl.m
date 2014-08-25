//
//  CliquePageControl.m
//  Pic6
//
//  Created by Veeral Patel on 8/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CliquePageControl.h"

@interface CliquePageControl ()

@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation CliquePageControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blueColor];
        
        UIPageControl *pageControl = [[UIPageControl alloc] init];
        pageControl.translatesAutoresizingMaskIntoConstraints = NO;
        pageControl.userInteractionEnabled = NO;
        self.pageControl = pageControl;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(pageControl);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageControl]|" options:0 metrics:nil views:views]];
        
    }
    return self;
}

@end
