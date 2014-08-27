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
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:blurEffectView];
        
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
        UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
        vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = NO;
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont fontWithName:@"Avenir-Book" size:22.0f];
        titleLabel.textColor = [UIColor whiteColor];
        [titleLabel sizeToFit];
        [[vibrancyEffectView contentView] addSubview:titleLabel];
        self.titleLabel = titleLabel;
        
        UIPageControl *pageControl = [[UIPageControl alloc] init];
        pageControl.translatesAutoresizingMaskIntoConstraints = NO;
        pageControl.userInteractionEnabled = NO;
        [[vibrancyEffectView contentView] addSubview:pageControl];
        self.pageControl = pageControl;
        
        [[blurEffectView contentView] addSubview:vibrancyEffectView];
        
        self.blurEffectView = blurEffectView;
        self.vibrancyEffectView = vibrancyEffectView;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(blurEffectView, vibrancyEffectView, pageControl, titleLabel);
        self.heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
        [self addConstraint:self.heightConstraint];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[blurEffectView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[blurEffectView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[vibrancyEffectView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[vibrancyEffectView]|" options:0 metrics:nil views:views]];
        [[vibrancyEffectView contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageControl]|" options:0 metrics:nil views:views]];
        [[vibrancyEffectView contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[titleLabel]|" options:0 metrics:nil views:views]];
        [[vibrancyEffectView contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[titleLabel][pageControl(15)]|" options:0 metrics:nil views:views]];
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

- (void)setGroupTitle:(NSString *)groupTitle {
    _groupTitle = groupTitle;
    self.titleLabel.text = groupTitle;
    
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.5f animations:^{
        self.heightConstraint.constant = 40;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hide) withObject:nil afterDelay:1.0f];
    }];
    
    NSLog(@"yo");
}

- (void)hide {
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.5f animations:^{
        self.heightConstraint.constant = 0;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self layoutIfNeeded];
        [UIView animateWithDuration:0.2f animations:^{
            self.heightConstraint.constant = 15;
            [self layoutIfNeeded];
        } completion:nil];
    }];
}
@end
