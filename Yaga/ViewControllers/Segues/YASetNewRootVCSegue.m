//
//  YASetNewRootVCSegue.m
//  Yaga
//
//  Created by Iegor on 12/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//
#import "YASetNewRootVCSegue.h"

@implementation YASetNewRootVCSegue
- (void) perform
{
    UIViewController *dst = (UIViewController *) self.destinationViewController;
    [UIView transitionFromView:[UIApplication sharedApplication].keyWindow.rootViewController.view
                        toView:dst.view
                      duration:0.4f
                       options:UIViewAnimationOptionTransitionCurlUp | UIViewAnimationOptionCurveEaseInOut
                    completion:^(BOOL finished){
                        [UIApplication sharedApplication].keyWindow.rootViewController = dst;
                    }];
}
@end
