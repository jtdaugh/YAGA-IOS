//
//  YAOnboardingCompleteSegue.m
//  Yaga
//
//  Created by valentinkovalski on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupSelectedSegue.h"

@implementation YAGroupSelectedSegue

- (void)perform {
    [UIView transitionWithView:[UIApplication sharedApplication].keyWindow
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{[UIApplication sharedApplication].keyWindow.rootViewController = self.destinationViewController;
                    }
                    completion:nil];
}

@end
