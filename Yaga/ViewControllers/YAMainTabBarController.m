//
//  YAMainViewController.m
//  
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAMainTabBarController.h"
#import "YAUtils.h"
#import "YASloppyNavigationController.h"
#import "YACameraViewController.h"
#import "YAAnimatedTransitioningController.h"
#import "YACameraManager.h"
#import "UIImage+Color.h"
#import "NameGroupViewController.h"
#import "YACreateGroupNavigationController.h"
#import "YALatestStreamViewController.h"
#import "YAFindGroupsViewConrtoller.h"
#import "YAGroupsListViewController.h"
#import "YAMyStreamViewController.h"
#import "YAGroupOptionsViewController.h"
#import "YAGroupGridViewController.h"
#import "YABubbleView.h"
#import "YAUserPermissions.h"
#import "YAPopoverView.h"

@interface YAMainTabBarController () <UITabBarControllerDelegate>

@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;

@property (nonatomic, weak) UIViewController *cameraTabViewController;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic) BOOL onboardingFinished;

@property (nonatomic) BOOL forceCamera;
@property (nonatomic, strong) UIImageView *overlay;

@end

@implementation YAMainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeAll;
//    [YAUtils randomQuoteWithCompletion:^(NSString *quote, NSError *error) {
//        self.navigationItem.prompt = quote;
//    }];
    
//    if ([[[YAGroup allObjects] objectsWhere:@"(amFollowing = 1 || amMember = 1)"] count]) {
//        [YAUtils setCompletedForcedFollowing];
//    }
    
    self.onboardingFinished = [YAUtils hasCompletedForcedFollowing];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UIViewController *vc0 = [[YASloppyNavigationController alloc] initWithRootViewController:[YALatestStreamViewController new]];
    vc0.tabBarItem.image = [UIImage imageNamed:@"StreamBarItem"];
    vc0.tabBarItem.title = @"Latest";
    
    UIViewController *vc1 = [[YASloppyNavigationController alloc] initWithRootViewController:[YAFindGroupsViewConrtoller new]];
    vc1.tabBarItem.image = [UIImage imageNamed:@"ExploreBarItem"];
    vc1.tabBarItem.title = @"Explore";

    UIViewController *vc2 = [UIViewController new];
    
    UIViewController *vc3 = [[YASloppyNavigationController alloc] initWithRootViewController:[YAGroupsListViewController new]];
    vc3.tabBarItem.image = [UIImage imageNamed:@"ChannelsBarItem"];
    vc3.tabBarItem.title = @"Channels";

    UIViewController *vc4 = [[YASloppyNavigationController alloc] initWithRootViewController:[YAMyStreamViewController new]];
    vc4.tabBarItem.image = [UIImage imageNamed:@"MeBarItem"];
    vc4.tabBarItem.title = @"Me";

    self.viewControllers = @[vc0, vc1, vc2, vc3, vc4];
    self.cameraTabViewController = self.viewControllers[2];
    
    self.animationController = [YAAnimatedTransitioningController new];
    self.delegate = self;
    self.tabBar.itemSpacing = VIEW_WIDTH/2;
    self.tabBar.tintColor = [UIColor whiteColor];
    self.tabBar.translucent = NO;
    self.tabBar.backgroundColor = [UIColor whiteColor];
    self.tabBar.barTintColor = [UIColor clearColor];
    CGFloat cameraWidth = VIEW_WIDTH/5-6;
    self.cameraButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - cameraWidth)/2, 5, cameraWidth, self.tabBar.frame.size.height - 10)];
    self.cameraButton.backgroundColor = PRIMARY_COLOR;
    [self.cameraButton setImage:[UIImage imageNamed:@"Camera"] forState:UIControlStateNormal];
    self.cameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.cameraButton.imageEdgeInsets = UIEdgeInsetsMake(2, 8, 5, 8);
    self.cameraButton.layer.cornerRadius = 7;
    self.cameraButton.layer.masksToBounds = YES;
    [self.cameraButton addTarget:self action:@selector(cameraPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.cameraButton];
    
    if (self.onboardingFinished) {
        self.selectedIndex = 0;
        self.forceCamera = !self.overrideForceCamera;
        if (self.forceCamera) {
            UIImageView *overlay = [[UIImageView alloc] initWithFrame:self.view.bounds];
            overlay.backgroundColor = [UIColor blackColor];
            [overlay setImage:[UIImage imageNamed:@"LaunchImage"]];
            overlay.contentMode = UIViewContentModeScaleAspectFill;
            [self.view addSubview:overlay];
            self.overlay = overlay;
        }
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.selectedIndex = 1;
        self.tabBar.frame = CGRectMake(0, VIEW_HEIGHT, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openGifGridFromNotification:) name:OPEN_GROUP_GRID_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedOnboarding) name:GROUP_FOLLOW_OR_REQUEST_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(![YAUserPermissions pushPermissionsRequestedBefore])
        [YAUserPermissions registerUserNotificationSettings];
    
    if (!self.onboardingFinished) {
        [self showForceFollowTooltip];
    } else {
        if (self.forceCamera) {
            self.forceCamera = NO;
            [self presentCameraAnimated:NO shownViaBackgrounding:NO withCompletion:^{
                [self.overlay removeFromSuperview];
            }];
        }
    }
}

- (UIViewController *)getTopmostViewControllerFromBaseVC:(UIViewController *)baseVC {
    UIViewController *visibleVC = baseVC;
    while (true) {
        if ([visibleVC presentedViewController]) {
            visibleVC = [visibleVC presentedViewController];
        } else {
            break;
        }
    }
    return visibleVC;
}

// Any view controller that wants to maintain presence when the app enters background
// must implement -blockCameraPresentationOnBackground and return YES.
- (void)didEnterBackground {
    if (![self isEqual:[UIApplication sharedApplication].keyWindow.rootViewController]) {
        // Only the root should be doing this
        return;
    }
    if (!self.onboardingFinished) return;
    
    UIViewController *visibleVC;
    if (self.presentedViewController) {
        visibleVC = [self getTopmostViewControllerFromBaseVC:self];
    } else {
        // Check deepest presented from
        visibleVC = [self getTopmostViewControllerFromBaseVC:self.selectedViewController];
    }
    SEL presentCameraSelector = @selector(blockCameraPresentationOnBackground);
    BOOL presentCamera = YES;
    if ([visibleVC respondsToSelector:presentCameraSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        presentCamera = ![visibleVC performSelector:presentCameraSelector];
#pragma clang diagnostic pop
    }
    if (presentCamera) {
        [self dismissAnyViewControllersAndPresentCamera];
    }
    
    // Force these updates to happen before app is opened again
    [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.1]];
}

- (void)dismissAnyViewControllersAndPresentCamera {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        if (self.selectedViewController.presentedViewController) {
            [self.selectedViewController dismissViewControllerAnimated:NO completion:nil];
        }
    }
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self presentCameraAnimated:NO shownViaBackgrounding:YES withCompletion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_GROUP_GRID_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_FOLLOW_OR_REQUEST_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];

}

- (void)finishedOnboarding {
    if (self.onboardingFinished) return;
    self.onboardingFinished = YES;
    CGRect frame = self.tabBar.frame;
    frame.origin.y -= frame.size.height;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.tabBar.frame = frame;
    }];
}

- (void)presentCreateGroup {
    NameGroupViewController *vc = [NameGroupViewController new];
    YASloppyNavigationController *createGroupNavController = [[YASloppyNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:createGroupNavController animated:YES completion:nil];
}

- (void)openGifGridFromNotification:(NSNotification *)notif {
    YAGroup *group = notif.object;
    if (!group) return;
    
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    
    UINavigationController *navVC = self.viewControllers[3];
    [navVC popToRootViewControllerAnimated:NO];
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = group;
    
    if ([notif.userInfo[kOpenToPendingVideos] boolValue])
        vc.openStraightToPendingSection = YES;
    
    self.selectedIndex = 3;
    [navVC pushViewController:vc animated:YES];
}


- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (!self.onboardingFinished)
        return NO;
    
    return viewController != self.cameraTabViewController;
}


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if ([item isEqual:self.cameraTabViewController.tabBarItem]) {
        // This is the camera button. Present modal camera instead of selecting tab
        [self presentCameraAnimated:YES shownViaBackgrounding:NO withCompletion:nil];
    }
}

- (void)cameraPressed {
    [self presentCameraAnimated:YES shownViaBackgrounding:NO withCompletion:nil];
}

- (void)presentCameraAnimated:(BOOL)animated shownViaBackgrounding:(BOOL)shownViaBackgrounding withCompletion:(void (^)(void))completion {
    
    YACameraViewController *camVC = [YACameraViewController new];
    camVC.shownViaBackgrounding = shownViaBackgrounding;
    
    YASloppyNavigationController *navVC = [[YASloppyNavigationController alloc] initWithRootViewController:camVC];
    navVC.view.backgroundColor = [UIColor clearColor];
    navVC.navigationBarHidden = YES;
    navVC.transitioningDelegate = self;
    navVC.modalPresentationStyle = UIModalPresentationCustom;
    
    camVC.showsStatusBarOnDismiss = YES;
    
    CGRect initialFrame = [UIApplication sharedApplication].keyWindow.bounds;
    
    CGAffineTransform initialTransform = CGAffineTransformMakeTranslation(0, VIEW_HEIGHT * .6); //(0.2, 0.2);
    initialTransform = CGAffineTransformScale(initialTransform, 0.3, 0.3);
    
    [self setInitialAnimationFrame: initialFrame];
    [self setInitialAnimationTransform:initialTransform];
    //    self.animationController.initialTransform = initialTransform;
    [self presentViewController:navVC animated:animated completion:completion];
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

- (void)showForceFollowTooltip {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FORCE_FOLLOW_TITLE", @"") bodyText:NSLocalizedString(@"FORCE_FOLLOW_BODY", @"") dismissText:@"Got it" addToView:self.view] show];
}



@end
