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
@property (nonatomic, strong) UIImageView *overlay;
@property (nonatomic) BOOL forceCamera;
@end

@implementation YAGroupsNavigationController

#pragma mark - NSObject

- (void)dealloc
{
    self.delegate = nil;
    self.interactivePopGestureRecognizer.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_GROUP_OPTIONS_NOTIFICATION object:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNavigationBarHidden:NO];
    
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setTitleTextAttributes:@{
                                                 NSForegroundColorAttributeName: SECONDARY_COLOR,
                                                 NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:20]
                                                 }];
    
    [self.navigationBar setShadowImage:[UIImage new]];
    [self.navigationBar setBarTintColor:[UIColor whiteColor]];
    [self.navigationBar setTintColor:SECONDARY_COLOR];
    [self.navigationBar setBackgroundImage:[UIImage new]
                            forBarPosition:UIBarPositionAny
                                barMetrics:UIBarMetricsDefault];
    
    self.animationController = [YAAnimatedTransitioningController new];

    [self.view setBackgroundColor:[UIColor colorWithWhite:0.97 alpha:1]];
    
    if (!self.delegate) {
        self.delegate = self;
    }

    self.swiper = [[SloppySwiper alloc] initWithNavigationController:self];
    self.delegate = self.swiper;

    self.interactivePopGestureRecognizer.delegate = self;

    self.cameraButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - CAMERA_BUTTON_SIZE)/2,
                                                                   self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - (CAMERA_BUTTON_SIZE/2),
                                                                   CAMERA_BUTTON_SIZE, CAMERA_BUTTON_SIZE)];
    self.cameraButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
    [self.cameraButton setImage:[[UIImage imageNamed:@"Camera"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.cameraButton.imageView.tintColor = PRIMARY_COLOR;
    self.cameraButton.imageEdgeInsets = UIEdgeInsetsMake(-55, 0, 0, 0);
    self.cameraButton.layer.cornerRadius = CAMERA_BUTTON_SIZE/2;
    self.cameraButton.layer.borderColor = [PRIMARY_COLOR CGColor];
    self.cameraButton.layer.borderWidth = 2.f;
    self.cameraButton.layer.masksToBounds = YES;
    [self.cameraButton addTarget:self action:@selector(presentCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cameraButton];
    
    UIImageView *overlay = [[UIImageView alloc] initWithFrame:self.view.bounds];
    overlay.backgroundColor = [UIColor blackColor];
    [overlay setImage:[UIImage imageNamed:@"LaunchImage"]];
    overlay.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:overlay];
    self.overlay = overlay;

    self.forceCamera = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openGroupOptions)
                                                 name:OPEN_GROUP_OPTIONS_NOTIFICATION
                                               object:nil];
}

- (void)presentCamera {
    YACameraViewController *camVC = [YACameraViewController new];
    camVC.transitioningDelegate = self; //(YAGroupsNavigationController *)self.navigationController;
    camVC.modalPresentationStyle = UIModalPresentationCustom;
    
    CGRect initialFrame = [UIApplication sharedApplication].keyWindow.bounds;
    
    CGAffineTransform initialTransform = CGAffineTransformMakeTranslation(0, VIEW_HEIGHT * .8); //(0.2, 0.2);
    initialTransform = CGAffineTransformScale(initialTransform, .2, .2);
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
    self.cameraButton.hidden = !show;
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