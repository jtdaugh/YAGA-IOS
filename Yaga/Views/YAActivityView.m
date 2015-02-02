//
//  YAActivityView.m
//  Yaga
//
//  Created by valentinkovalski on 1/8/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAActivityView.h"

@interface YAActivityView ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSString *currentAnimationKey;
@end


#define rotateRightKey @"rotationRight"
#define rotateLeftKey @"rotationLeft"

@implementation YAActivityView

#pragma mark - public
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView.image = [UIImage imageNamed:@"Monkey_Grey"];
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)startAnimating {
    [self stopAnimating];
    
    [self rotateRight];
}

- (void)stopAnimating {
    [self.layer removeAnimationForKey:rotateRightKey];
    [self.layer removeAnimationForKey:rotateLeftKey];
}

- (BOOL)isAnimating {
    return self.layer.animationKeys.count != 0;
}

#pragma mark - private
- (void)rotateRight {
    [self stopAnimating];
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = 0.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 2;
    rotationAnimation.delegate = self;
    [self.layer addAnimation:rotationAnimation forKey:rotateRightKey];
}

- (void)rotateLeft {
    [self stopAnimating];
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: -M_PI * 2.0];
    rotationAnimation.duration = 1.0;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1;
    rotationAnimation.delegate = self;
    [self.layer addAnimation:rotationAnimation forKey:rotateLeftKey];
}

#pragma mark - delegate
- (void)animationDidStart:(CAAnimation *)anim {
    self.currentAnimationKey = (anim == [self.layer animationForKey:rotateRightKey]) ? rotateRightKey : rotateLeftKey;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished {
    if(!finished)
        return;
    
    if([self.currentAnimationKey isEqualToString:rotateRightKey]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self rotateLeft];
        });
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self rotateRight];
        });
    }
}

#pragma mark - other
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    if(self.animateAtOnce)
        [self startAnimating];
}
@end
