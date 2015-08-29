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
#import "YAChannelsViewController.h"
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
    
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UIViewController *vc0 = [[YASloppyNavigationController alloc] initWithRootViewController:[YALatestStreamViewController new]];
    vc0.tabBarItem.image = [UIImage imageNamed:@"StreamBarItem"];
    vc0.tabBarItem.title = @"Grid";
    
    UIViewController *vc1 = [UIViewController new];

    UIViewController *vc2 = [[YASloppyNavigationController alloc] initWithRootViewController:[YAChannelsViewController new]];
    vc2.tabBarItem.image = [UIImage imageNamed:@"ChannelsBarItem"];
    vc2.tabBarItem.title = @"Channels";

//    UIViewController *vc2 = [[YASloppyNavigationController alloc] initWithRootViewController:[YAFindGroupsViewConrtoller new]];
//    vc2.tabBarItem.image = [UIImage imageNamed:@"ExploreBarItem"];
//    vc2.tabBarItem.title = @"Explore";

//    UIViewController *vc4 = [[YASloppyNavigationController alloc] initWithRootViewController:[YAMyStreamViewController new]];
//    vc4.tabBarItem.image = [UIImage imageNamed:@"MeBarItem"];
//    vc4.tabBarItem.title = @"Me";

    

    self.viewControllers = @[vc0, vc1, vc2];
    self.cameraTabViewController = self.viewControllers[1];
    
    self.animationController = [YAAnimatedTransitioningController new];
    self.delegate = self;
    self.tabBar.itemSpacing = VIEW_WIDTH/2;
    self.tabBar.tintColor = [UIColor whiteColor];
    self.tabBar.translucent = NO;
    self.tabBar.backgroundColor = [UIColor whiteColor];
    self.tabBar.barTintColor = [UIColor clearColor];
    CGFloat cameraWidth = VIEW_WIDTH/5-6;
    self.cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH * .5 - cameraWidth/2, 5, cameraWidth, self.tabBar.frame.size.height - 10)];
    self.cameraButton.backgroundColor = PRIMARY_COLOR;
    [self.cameraButton setImage:[UIImage imageNamed:@"Camera"] forState:UIControlStateNormal];
    self.cameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.cameraButton.imageEdgeInsets = UIEdgeInsetsMake(2, 8, 5, 8);
    self.cameraButton.layer.cornerRadius = 7;
    self.cameraButton.layer.masksToBounds = YES;
    [self.cameraButton addTarget:self action:@selector(cameraPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:self.cameraButton];
    
    if(![YAUserPermissions pushPermissionsRequestedBefore])
        [YAUserPermissions registerUserNotificationSettings];

    if ([YAUtils hasSeenFollowingScreen]) {
        self.selectedIndex = 0;
        self.forceCamera = !self.overrideForceCamera && ALWAYS_LAUNCH_TO_CAMERA;
        if (self.forceCamera) {
            UIImageView *overlay = [[UIImageView alloc] initWithFrame:self.view.bounds];
            overlay.backgroundColor = [UIColor blackColor];
            [overlay setImage:[UIImage imageNamed:@"LaunchImage"]];
            overlay.contentMode = UIViewContentModeScaleAspectFill;
            [self.view addSubview:overlay];
            self.overlay = overlay;
        }
    } else {
        [YAUtils setSeenFollowingScreen];
        [self showForceFollowTooltip];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.selectedIndex = 2;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openGifGridFromNotification:) name:OPEN_GROUP_GRID_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.forceCamera) {
        self.forceCamera = NO;
        [self presentCameraAnimated:NO shownViaBackgrounding:NO withCompletion:^{
            [self.overlay removeFromSuperview];
        }];
    }
}

- (void)returnToStreamViewController {
    self.selectedIndex = 0;
    UINavigationController *navVC = self.viewControllers[0];
    if ([navVC.viewControllers count] > 1) {
        [navVC popToRootViewControllerAnimated:NO];
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
    if (!ALWAYS_LAUNCH_TO_CAMERA) return;
    
    if (![self isEqual:[UIApplication sharedApplication].keyWindow.rootViewController]) {
        // Only the root should be doing this
        return;
    }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)presentCreateGroup {
    [[Mixpanel sharedInstance] track:@"Create Group Pressed"];
    NameGroupViewController *vc = [NameGroupViewController new];
    YASloppyNavigationController *createGroupNavController = [[YASloppyNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:createGroupNavController animated:YES completion:nil];
}

- (void)presentFindGroups {
    self.selectedIndex = 2;
    YASloppyNavigationController *navController = self.viewControllers[2];
    [navController popToRootViewControllerAnimated:NO];
    YAChannelsViewController *channels = navController.viewControllers[0];
    
    channels.segmentedControl.selectedSegmentIndex = 0;
    [channels.segmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
    channels.flexibleNavBar.progress = 0;
}

- (void)openGifGridFromNotification:(NSNotification *)notif {
    YAGroup *group = notif.object;
    if (!group) return;
    
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    
    UINavigationController *navVC = self.viewControllers[2];
    [navVC popToRootViewControllerAnimated:NO];
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = group;
    
    if ([notif.userInfo[kOpenToPendingVideos] boolValue])
        vc.openStraightToPendingSection = YES;
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    self.selectedIndex = 2;
    [navVC pushViewController:vc animated:YES];
}


- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    return viewController != self.cameraTabViewController;
}


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if ([item isEqual:self.cameraTabViewController.tabBarItem]) {
        // This is the camera button. Present modal camera instead of selecting tab
        [self presentCameraAnimated:YES shownViaBackgrounding:NO withCompletion:nil];
    }
}

- (void)cameraPressed {
    [[Mixpanel sharedInstance] track:@"Camera Pressed"];

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
