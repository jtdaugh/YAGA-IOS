//
//  YAGroupsNavigationController.m
//  Yaga
//
//  Created by Jesse on 6/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGroupsNavigationController.h"

@interface YAGroupsNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, getter = isDuringPushAnimation) BOOL duringPushAnimation;

@property (weak, nonatomic) id<UINavigationControllerDelegate> realDelegate;

@end

@implementation YAGroupsNavigationController

#pragma mark - NSObject

- (void)dealloc
{
    self.delegate = nil;
    self.interactivePopGestureRecognizer.delegate = nil;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNavigationBarHidden:NO];
    
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationBar setTitleTextAttributes:@{
                                                 NSForegroundColorAttributeName: [UIColor whiteColor],
                                                 NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:20]
                                                 }];
    
    [self.navigationBar setShadowImage:[UIImage new]];
    [self.navigationBar setBarTintColor:PRIMARY_COLOR];
    [self.navigationBar setBackgroundImage:[UIImage new]
                            forBarPosition:UIBarPositionAny
                                barMetrics:UIBarMetricsDefault];
    //    [self.navigationBar setBackgroundColor:[UIColor blackColor]];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-1000, -1000) forBarMetrics:UIBarMetricsDefault];

    if (!self.delegate) {
        self.delegate = self;
    }
    
    self.interactivePopGestureRecognizer.delegate = self;
}

#pragma mark - UINavigationController

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate
{
    [super setDelegate:delegate ? self : nil];
    self.realDelegate = delegate != self ? delegate : nil;
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated __attribute__((objc_requires_super))
{
    self.duringPushAnimation = YES;
    [super pushViewController:viewController animated:animated];
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    self.duringPushAnimation = NO;
    
    if ([self.realDelegate respondsToSelector:_cmd]) {
        [self.realDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController*)fromVC toViewController:(UIViewController*)toVC
{
    if ([self.realDelegate respondsToSelector:_cmd]) {
        return [self.realDelegate navigationController:navigationController animationControllerForOperation:operation fromViewController:fromVC toViewController:toVC];
    }
    return nil;
}

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController*)navigationController interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>)animationController
{
    if ([self.realDelegate respondsToSelector:_cmd]) {
        return [self.realDelegate navigationController:navigationController interactionControllerForAnimationController:animationController];
    }
    return nil;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        // Disable pop gesture in two situations:
        // 1) when the pop animation is in progress
        // 2) when user swipes quickly a couple of times and animations don't have time to be performed
        return [self.viewControllers count] > 1 && !self.isDuringPushAnimation;
    } else {
        // default value
        return YES;
    }
}

#pragma mark - Delegate Forwarder

- (BOOL)respondsToSelector:(SEL)s
{
    return [super respondsToSelector:s] || [self.realDelegate respondsToSelector:s];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)s
{
    return [super methodSignatureForSelector:s] ?: [(id)self.realDelegate methodSignatureForSelector:s];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    id delegate = self.realDelegate;
    if ([delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:delegate];
    }
}

@end