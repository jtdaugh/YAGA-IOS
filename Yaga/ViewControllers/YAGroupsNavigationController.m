//
//  YAGroupsNavigationController.m
//  Yaga
//
//  Created by Jesse on 6/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGroupsNavigationController.h"
#import "YAAnimatedTransitioningController.h"
#import "YAGifGridViewController.h"
#import "YAGroupsListViewController.h"
#import "YACameraViewController.h"
#import "SloppySwiper.h"
#import "YAGroupOptionsViewController.h"

#import "YAUser.h"

@interface YAGroupsNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, getter = isDuringPushAnimation) BOOL duringPushAnimation;

@property (nonatomic, strong) SloppySwiper *swiper;

@property (weak, nonatomic) id<UINavigationControllerDelegate> realDelegate;
@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;
@property (nonatomic, strong) UIButton *cameraButton;

@property (nonatomic, strong) UIVisualEffectView *cameraButtonBlur;

@property (nonatomic, strong) UIImageView *overlay;
@end

@implementation YAGroupsNavigationController

#pragma mark - NSObject

- (void)dealloc
{
    self.delegate = nil;
    self.interactivePopGestureRecognizer.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_GROUP_OPTIONS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNavigationBarHidden:NO];
    
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setTitleTextAttributes:@{
                                                 NSForegroundColorAttributeName: SECONDARY_COLOR
                                                 }];
    
    [self.navigationBar setShadowImage:[UIImage new]];
    [self.navigationBar setBarTintColor:[UIColor whiteColor]];
    [self.navigationBar setTintColor:SECONDARY_COLOR];
    [self.navigationBar setBackgroundImage:[UIImage new]
                            forBarPosition:UIBarPositionAny
                                barMetrics:UIBarMetricsDefault];
    
    self.navigationBar.layer.shadowColor = [SECONDARY_COLOR CGColor];
    self.navigationBar.layer.shadowOpacity = 0.5;
    self.navigationBar.layer.shadowRadius = 1;
    self.navigationBar.layer.shadowOffset = CGSizeMake(0, 0.5);
    self.navigationBar.layer.masksToBounds = NO;
    
    self.animationController = [YAAnimatedTransitioningController new];

    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    if (!self.delegate) {
        self.delegate = self;
    }

    self.swiper = [[SloppySwiper alloc] initWithNavigationController:self];
    self.delegate = self.swiper;

    self.interactivePopGestureRecognizer.delegate = self;

    [self addCameraButton];
    
    if (self.forceCamera) {
        UIImageView *overlay = [[UIImageView alloc] initWithFrame:self.view.bounds];
        overlay.backgroundColor = [UIColor blackColor];
        [overlay setImage:[UIImage imageNamed:@"LaunchImage"]];
        overlay.contentMode = UIViewContentModeScaleAspectFill;
        [self.view addSubview:overlay];
        self.overlay = overlay;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openGroupOptions)
                                                 name:OPEN_GROUP_OPTIONS_NOTIFICATION
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)addCameraButton {
    
    self.cameraButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - CAMERA_BUTTON_SIZE)/2,
                                                                   self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - (CAMERA_BUTTON_SIZE/2),
                                                                   CAMERA_BUTTON_SIZE, CAMERA_BUTTON_SIZE)];
    self.cameraButton.backgroundColor = [UIColor clearColor];
    [self.cameraButton setImage:[[UIImage imageNamed:@"Camera"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.cameraButton.imageView.tintColor = [UIColor whiteColor];
    self.cameraButton.imageEdgeInsets = UIEdgeInsetsMake(-55, 0, 0, 0);
    self.cameraButton.layer.cornerRadius = CAMERA_BUTTON_SIZE/2;
    self.cameraButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.cameraButton.layer.borderWidth = 2.f;
    self.cameraButton.layer.masksToBounds = YES;
    [self.cameraButton addTarget:self action:@selector(presentCamera) forControlEvents:UIControlEventTouchUpInside];
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.cameraButtonBlur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.cameraButtonBlur.frame = self.cameraButton.frame;
    self.cameraButtonBlur.layer.cornerRadius = CAMERA_BUTTON_SIZE/2;
    self.cameraButtonBlur.layer.masksToBounds = YES;
    
    [self.view addSubview:self.cameraButtonBlur];
    [self.view addSubview:self.cameraButton];
    [self showCameraButton:NO];
    
}

- (void)didEnterBackground {
    if (![self isEqual:[UIApplication sharedApplication].keyWindow.rootViewController]) {
        // Only the root should be doing this
        return;
    }
    id visibleVC;
    if (self.presentedViewController) {
        if (self.presentedViewController.presentedViewController) {
            visibleVC = self.presentedViewController.presentedViewController;
        } else {
            visibleVC = self.presentedViewController;
        }
    } else {
        visibleVC = self.visibleViewController;
    }
    SEL presentCameraSelector = @selector(blockCameraPresentationOnBackground);
    BOOL presentCamera = YES;
    if ([visibleVC respondsToSelector:presentCameraSelector]) {
        presentCamera = ![visibleVC performSelector:presentCameraSelector];
    }
    if (presentCamera) {
        [self dismissAnyNecessaryViewControllersAndShowCamera];
    }
    
    // Force these updates to happen before app is opened again
    [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.1]];
}

- (void)dismissAnyNecessaryViewControllersAndShowCamera {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        if ([self.viewControllers count] > 2) {
            self.viewControllers = [self.viewControllers subarrayWithRange:NSMakeRange(0, 2)];
        }
    }
    YACameraViewController *camVC = [YACameraViewController new];
    camVC.transitioningDelegate = self; //(YAGroupsNavigationController *)self.navigationController;
    camVC.modalPresentationStyle = UIModalPresentationCustom;
    
    camVC.showsStatusBarOnDismiss = YES;
    
    CGRect initialFrame = [UIApplication sharedApplication].keyWindow.bounds;
    
    CGAffineTransform initialTransform = CGAffineTransformMakeTranslation(0, VIEW_HEIGHT * .6); //(0.2, 0.2);
    initialTransform = CGAffineTransformScale(initialTransform, 0.3, 0.3);
    
    [self setInitialAnimationFrame: initialFrame];
    [self setInitialAnimationTransform:initialTransform];
    //    self.animationController.initialTransform = initialTransform;

    camVC.shownViaBackgrounding = YES;
    [self presentViewController:camVC animated:NO completion:nil];

}


- (void)presentCamera {
    YACameraViewController *camVC = [YACameraViewController new];
    camVC.transitioningDelegate = self; //(YAGroupsNavigationController *)self.navigationController;
    camVC.modalPresentationStyle = UIModalPresentationCustom;
    
    camVC.showsStatusBarOnDismiss = YES;

    CGRect initialFrame = [UIApplication sharedApplication].keyWindow.bounds;
    
    CGAffineTransform initialTransform = CGAffineTransformMakeTranslation(0, VIEW_HEIGHT * .6); //(0.2, 0.2);
    initialTransform = CGAffineTransformScale(initialTransform, 0.3, 0.3);
//    initialFrame.origin.y += self.view.frame.origin.y;
//    initialFrame.origin.x = 0;
    
    [self setInitialAnimationFrame: initialFrame];
    [self setInitialAnimationTransform:initialTransform];
//    self.animationController.initialTransform = initialTransform;
    [self presentViewController:camVC animated:YES completion:nil];
}

- (void)openGroupOptions {
    if(![YAUser currentUser].currentGroup)
        return;
    
    if([self.topViewController isKindOfClass:[YAGroupOptionsViewController class]]) {
        [self popViewControllerAnimated:NO];
    }
    
    YAGroupOptionsViewController *vc = [[YAGroupOptionsViewController alloc] init];
    vc.group = [YAUser currentUser].currentGroup;
    [self pushViewController:vc animated:YES];
}

- (void)showCameraButton:(BOOL)show {
    self.cameraButton.hidden = self.cameraButtonBlur.hidden = !show;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.forceCamera) {
        self.forceCamera = NO;
        YACameraViewController *camVC = [YACameraViewController new];
        camVC.transitioningDelegate = (YAGroupsNavigationController *)self.navigationController;
        camVC.modalPresentationStyle = UIModalPresentationCustom;
        camVC.showsStatusBarOnDismiss = YES;

        [self presentViewController:camVC animated:NO completion:^{
            [self.overlay removeFromSuperview];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
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