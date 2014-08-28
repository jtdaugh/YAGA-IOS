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
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIVisualEffectView *blurEffectView;
@property (nonatomic, strong) UIVisualEffectView *vibrancyEffectView;

@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

@end

@implementation CliquePageControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UIPageControl *pageControl = [[UIPageControl alloc] init];
        pageControl.translatesAutoresizingMaskIntoConstraints = NO;
        pageControl.userInteractionEnabled = NO;
        [self addSubview:pageControl];
        self.pageControl = pageControl;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(pageControl);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageControl]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[pageControl(15)]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setCurrentPage:(NSInteger)currentPage {
    _currentPage = currentPage;
    self.pageControl.currentPage = currentPage;
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
    _numberOfPages = numberOfPages;
    self.pageControl.numberOfPages = numberOfPages;
}

@end
