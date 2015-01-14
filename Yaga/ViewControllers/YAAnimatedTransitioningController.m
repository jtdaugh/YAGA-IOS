//
//  YAAnimatedTransitioningController.m
//  Yaga
//
//  Created by valentinkovalski on 1/13/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAAnimatedTransitioningController.h"

#define kDuration 0.1

@implementation YAAnimatedTransitioningController

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
    toViewController.view.alpha = 0.5;
//    [UIView animateWithDuration:kDuration delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:6.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
    [UIView animateWithDuration:kDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        toViewController.view.alpha = 1;
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
