//
//  YAGroupsNavigationController.m
//  Yaga
//
//  Created by Jesse on 6/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YASloppyNavigationController.h"
#import "YAAnimatedTransitioningController.h"
#import "YAGroupsListViewController.h"
#import "YACameraViewController.h"
#import "SloppySwiper.h"
#import "YAGroupOptionsViewController.h"
#import "YAEditVideoViewController.h"
#import "UIImage+Color.h"

#import "YAUser.h"

@interface YASloppyNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, getter = isDuringPushAnimation) BOOL duringPushAnimation;

@property (weak, nonatomic) id<UINavigationControllerDelegate> realDelegate;
@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;

@end

@implementation YASloppyNavigationController

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
    [self setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setTitleTextAttributes:@{
                                                 NSForegroundColorAttributeName: [UIColor whiteColor]
                                                 }];
    
    [self.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self.navigationBar setBackgroundColor:PRIMARY_COLOR];
    [self.navigationBar setBarTintColor:PRIMARY_COLOR];
        
//    self.navigationBar.layer.shadowColor = [SECONDARY_COLOR CGColor];
//    self.navigationBar.layer.shadowOpacity = 0.5;
//    self.navigationBar.layer.shadowRadius = 1;
//    self.navigationBar.layer.shadowOffset = CGSizeMake(0, 0.5);
//    self.navigationBar.layer.masksToBounds = NO;
    
    self.animationController = [YAAnimatedTransitioningController new];

    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    if (!self.delegate) {
        self.delegate = self;
    }

    self.swiper = [[SloppySwiper alloc] initWithNavigationController:self];
    self.delegate = self.swiper;

    self.interactivePopGestureRecognizer.delegate = self;
}

//// Any view controller that wants to maintain presence when the app enters background
//// must implement -blockCameraPresentationOnBackground and return YES.
//- (void)didEnterBackground {
//    if (![self isEqual:[UIApplication sharedApplication].keyWindow.rootViewController]) {
//        // Only the root should be doing this
//        return;
//    }
//    id visibleVC;
//    if (self.presentedViewController) {
//        if (self.presentedViewController.presentedViewController) {
//            visibleVC = self.presentedViewController.presentedViewController;
//        } else {
//            visibleVC = self.presentedViewController;
//        }
//    } else {
//        visibleVC = self.visibleViewController;
//    }
//    SEL presentCameraSelector = @selector(blockCameraPresentationOnBackground);
//    BOOL presentCamera = YES;
//    if ([visibleVC respondsToSelector:presentCameraSelector]) {
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//        presentCamera = ![visibleVC performSelector:presentCameraSelector];
//#pragma clang diagnostic pop
//    }
//    if (presentCamera) {
//        [self dismissAnyNecessaryViewControllersAndShowCamera];
//    }
//    
//    // Force these updates to happen before app is opened again
//    [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.1]];
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
        if ([self.topViewController isKindOfClass:[YAEditVideoViewController class]]) {
            // So the pop gesture wont interfere with the trim controls EditVideoVC
            CGPoint loc = [gestureRecognizer locationInView:self.topViewController.view];
            return loc.y < (VIEW_HEIGHT * 0.75);
        }
        
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

- (void)setInitialAnimationFrame:(CGRect)frame {
    self.animationController.initialFrame = frame;
}

- (void)setInitialAnimationTransform:(CGAffineTransform)transform {
    self.animationController.initialTransform = transform;
}

#pragma mark - Custom transitions
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.animationController.presentingMode = YES;
    
    return self.animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.animationController.presentingMode = NO;
    
    return self.animationController;
}


@end