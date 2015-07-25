//
//  YAAnimatedTransitioningController.m
//  Yaga
//
//  Created by valentinkovalski on 1/13/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAAnimatedTransitioningController.h"

#define kDuration 0.3

@implementation YAAnimatedTransitioningController

- (id) init {
    if (self = [super init])  {
        self.initialTransform = CGAffineTransformIdentity;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
        
    if(self.presentingMode){
        [self executePresentationAnimation:transitionContext];
    }
    else{
        [self executeDismissalAnimation:transitionContext];
    }
}

- (void)executePresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIView* inView = [transitionContext containerView];
    
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    [inView addSubview:toViewController.view];
    
    toViewController.view.frame = self.initialFrame;
    toViewController.view.transform = self.initialTransform;
    toViewController.view.alpha = 0.5;
//    [UIView animateWithDuration:kDuration delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:6.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
    [UIView animateWithDuration:kDuration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
        //
//    } completion:^(BOOL finished) {
//        //
//        [transitionContext completeTransition:YES];
//    }];
//    [UIView animateWithDuration:kDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        toViewController.view.alpha = 1;
        toViewController.view.transform = CGAffineTransformIdentity;
        toViewController.view.frame = [UIApplication sharedApplication].keyWindow.bounds;
        
    } completion:^(BOOL finished) {
        
        [transitionContext completeTransition:YES];
    }];
}

- (void)executeDismissalAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    

    //[UIView animateWithDuration:kDuration delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:6.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
    [UIView animateWithDuration:kDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        fromViewController.view.frame = self.initialFrame;
        fromViewController.view.alpha = 0.3;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

@end
