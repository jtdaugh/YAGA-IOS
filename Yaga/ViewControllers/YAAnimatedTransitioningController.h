//
//  YAAnimatedTransitioningController.h
//  Yaga
//
//  Created by valentinkovalski on 1/13/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YAAnimatedTransitioningController : NSObject<UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL presentingMode;
@property (nonatomic, assign) CGRect initialFrame;
@end
