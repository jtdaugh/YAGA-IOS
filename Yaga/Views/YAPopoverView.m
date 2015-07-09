//
//  YAPopoverView.m
//  Yaga
//
//  Created by Raj Vir on 7/7/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAPopoverView.h"

@interface YAPopoverView ()

@property (strong, nonatomic) UIView *tapOutView;
@property (strong, nonatomic) UIView *contentArea;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UITextView *bodyTextView;
@property (strong, nonatomic) UIButton *dismissButton;


@end


@implementation YAPopoverView

- (id)initWithTitle:(NSString *)title bodyText:(NSString *)bodyText dismissText:(NSString *)dismissText addToView:(UIView *)view {
    
    self = [super initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    self.alpha = 0.0;
    self.tapOutView = [[UIView alloc] initWithFrame:self.frame];
    
    [self setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
    
    UITapGestureRecognizer *dismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [self.tapOutView addGestureRecognizer:dismiss];
    
    [self addSubview:self.tapOutView];
    
    CGFloat x = .8, y = .6;
    
    CGFloat fullWidth = self.frame.size.width;
    CGFloat fullHeight = self.frame.size.height;
    
    CGFloat width = MAX(x*self.frame.size.width, 280);
    CGFloat height = y*self.frame.size.height;
    
    self.contentArea = [[UIView alloc] initWithFrame:CGRectMake((fullWidth-width)/2, (fullHeight - height)/2, width, height)];
    [self.contentArea setBackgroundColor:[UIColor whiteColor]];
    
    self.contentArea.layer.masksToBounds = YES;
    self.contentArea.layer.cornerRadius = 16.0f;
    
    [self addSubview:self.contentArea];
    
    CGFloat padding = 12;
    CGFloat accessoryHeight = 54;
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, padding, self.contentArea.frame.size.width - padding * 2, accessoryHeight)];
    [self.titleLabel setText:title];
    [self.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:36]];
    [self.titleLabel setTextColor:[UIColor blackColor]];
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.contentArea addSubview:self.titleLabel];
    
    self.dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.contentArea.frame.size.height - accessoryHeight, self.contentArea.frame.size.width, accessoryHeight)];
    [self.dismissButton setBackgroundColor:PRIMARY_COLOR];
    [self.dismissButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:28]];
    [self.dismissButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.dismissButton setTitle:dismissText forState:UIControlStateNormal];
    self.dismissButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.contentArea addSubview:self.dismissButton];
    
    self.bodyTextView = [[UITextView alloc] initWithFrame:CGRectMake(padding, accessoryHeight + padding, self.contentArea.frame.size.width - padding*2, self.contentArea.frame.size.height - accessoryHeight*2 - padding)];
//    [self.bodyTextView setContentInset:UIEdgeInsetsMake(padding, padding, padding, padding)];
    [self.bodyTextView setTextAlignment:NSTextAlignmentCenter];
    [self.bodyTextView setFont:[UIFont fontWithName:BIG_FONT size:16]];
    [self.bodyTextView setText:bodyText];
    [self.contentArea addSubview:self.bodyTextView];
//    [self.bodyTextView setBackgroundColor:[UIColor greenColor]];
    
    [view addSubview:self];
    
    return self;
}

- (void)show {
    self.contentArea.transform = CGAffineTransformMakeTranslation(-20, -self.frame.size.height);
    self.contentArea.transform = CGAffineTransformRotate(self.contentArea.transform, M_PI/6);
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        //
        self.alpha = 1.0;
        self.contentArea.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)dismiss {
    // animate out?
    CGAffineTransform t = CGAffineTransformMakeTranslation(20, self.frame.size.height);
    t = CGAffineTransformRotate(t, -M_PI/6);
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        //
        self.alpha = 0.0;
        self.contentArea.transform = t;

    } completion:^(BOOL finished) {
        //
        [self removeFromSuperview];
    }];
    
}

//- (id) initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//
//    NSLog(@"inited");
//    
//    return self;
//}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
