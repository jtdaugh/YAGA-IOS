//
//  YAMainViewController.h
//  
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import <UIKit/UIKit.h>

@interface YAMainTabBarController : UITabBarController <UIViewControllerTransitioningDelegate>

- (void)presentCreateGroup;
- (void)setInitialAnimationFrame:(CGRect)frame;
- (void)setInitialAnimationTransform:(CGAffineTransform)transform;

@property (nonatomic) BOOL overrideForceCamera;

@end
