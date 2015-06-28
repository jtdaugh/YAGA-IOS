//
//  YAWeakTimer.m
//  Yaga
//
//  Created by Jesse on 6/15/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAWeakTimerTarget.h"

@implementation YAWeakTimerTarget

- (void) fire
{
    if(self.target)
    {
        [self.target performSelector:self.selector withObject:nil];
    }
    else
    {
        [self.timer invalidate];
    }
}

+ (NSTimer *) scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo
{
    YAWeakTimerTarget* timerTarget = [[YAWeakTimerTarget alloc] init];
    timerTarget.target = aTarget;
    timerTarget.selector = aSelector;
    timerTarget.timer = [NSTimer scheduledTimerWithTimeInterval:ti target:timerTarget selector:@selector(fire) userInfo:userInfo repeats:yesOrNo];
    return timerTarget.timer;
}

@end
