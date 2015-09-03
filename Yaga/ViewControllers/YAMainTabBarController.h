//
//  YAMainViewController.h
//  
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import <UIKit/UIKit.h>

@class YAGroup;

@interface YAMainTabBarController : UITabBarController <UIViewControllerTransitioningDelegate>

- (void)presentCreateGroup;
- (void)presentFindGroups;

- (void)pushGifGridForGroup:(YAGroup *)group toPendingTab:(BOOL)pending;

- (void)setInitialAnimationFrame:(CGRect)frame;
- (void)setInitialAnimationTransform:(CGAffineTransform)transform;

- (void)returnToStreamViewController;

@property (nonatomic) BOOL overrideForceCamera;

@end
