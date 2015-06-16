//
//  YAWeakTimer.h
//  Yaga
//
//  Created by Jesse on 6/15/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface YAWeakTimerTarget : NSObject

@property (weak) id target;
@property SEL selector;
@property (nonatomic, strong) NSTimer *timer;

- (void) fire;

+ (NSTimer *) scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo;

@end
