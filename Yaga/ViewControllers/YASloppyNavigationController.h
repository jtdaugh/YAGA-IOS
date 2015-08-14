//
//  YAGroupsNavigationController.h
//  Yaga
//
//  Created by Jesse on 6/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YASloppyNavigationController : UINavigationController <UIViewControllerTransitioningDelegate>

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated __attribute__((objc_requires_super));

- (void)setInitialAnimationFrame:(CGRect)frame;
- (void)setInitialAnimationTransform:(CGAffineTransform)transform;

@end