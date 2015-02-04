//
//  YAPullToRefreshLoadingView.m
//  Yaga
//
//  Created by valentinkovalski on 2/3/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAPullToRefreshLoadingView.h"
#import "YAActivityView.h"

@interface YAPullToRefreshLoadingView ()
@property (nonatomic, strong) YAActivityView *activityView;
@end


@implementation YAPullToRefreshLoadingView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if(self) {
//        self.backgroundColor = [UIColor yellowColor];
        self.activityView = [[YAActivityView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH/10, VIEW_WIDTH/10)];
        [self addSubview:self.activityView];
        
        CGRect rect = self.bounds;
        rect.size.height -= 10;
        [self animateUsingPath:[self pathForFrame:rect]];
    }
    return self;
}

- (UIBezierPath*)pathForFrame:(CGRect)frame {
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    
    [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.00235 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.89130 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.26752 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.16440 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10870 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.26752 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.42958 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.26752 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.35101 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10870 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.61512 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.61036 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10481 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.61512 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.78638 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.61512 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.76736 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.05435 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.98758 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.78638 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76087 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 1.00195 * CGRectGetWidth(frame), CGRectGetMinY(frame) + -0.23913 * CGRectGetHeight(frame))];

    
    bezierPath.lineWidth = 1;
    
    return bezierPath;
}

- (void)drawPath:(UIBezierPath*)path {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path          = path.CGPath;
    layer.strokeColor   = [UIColor redColor].CGColor;
    layer.lineWidth     = 1.0;
    layer.fillColor     = nil;
    
    [self.layer addSublayer:layer];
}

- (void)animateUsingPath:(UIBezierPath*)path {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.path = path.CGPath;
    animation.fillMode              = kCAFillModeBoth;
    animation.removedOnCompletion   = NO;
    animation.duration              = 1.0;
    animation.timingFunction        = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.repeatCount = MAXFLOAT;
    animation.autoreverses = YES;
    [self.activityView.layer addAnimation:animation forKey:@"animation.trash"];
    
    //[self drawPath:path];
}



@end
