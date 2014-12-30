//
//  YASetNewRootVCSegue.m
//  Yaga
//
//  Created by Iegor on 12/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//
#import "AppDelegate.h"
#import "YASetNewRootVCSegue.h"

@implementation YASetNewRootVCSegue
- (void) perform
{
    UIViewController *dst = (UIViewController *) self.destinationViewController;

    CATransition *animation = [CATransition animation];
    [animation setDuration:0.4];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromTop];
    [animation setTimingFunction:[CAMediaTimingFunction  functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    [[dst.view layer] addAnimation:animation forKey:nil];
    
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.window.rootViewController = dst;
}
@end
