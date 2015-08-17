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
#import "YAStreamViewController.h"
#import "YAFindGroupsViewConrtoller.h"
#import "YAGroupsListViewController.h"
#import "YAMyStreamViewController.h"
#import "YAGroupOptionsViewController.h"
#import "YAGroupGridViewController.h"

@interface YAMainTabBarController () <UITabBarControllerDelegate>

@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;

@property (nonatomic, weak) UIViewController *cameraTabViewController;
@property (nonatomic, strong) UIButton *cameraButton;

@end

@implementation YAMainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [YAUtils randomQuoteWithCompletion:^(NSString *quote, NSError *error) {
//        self.navigationItem.prompt = quote;
//    }];
    
    UIViewController *vc0 = [[YASloppyNavigationController alloc] initWithRootViewController:[YAStreamViewController new]];
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
    
    [[YACameraManager sharedManager] initCamera];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openGifGridFromNotification:) name:OPEN_GROUP_GRID_NOTIFICATION object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_GROUP_GRID_NOTIFICATION object:nil];
}

- (void)presentCreateGroup {
    NameGroupViewController *vc = [NameGroupViewController new];
    YASloppyNavigationController *createGroupNavController = [[YASloppyNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:createGroupNavController animated:YES completion:nil];
}

- (void)openGifGridFromNotification:(NSNotification *)notif {
    YAGroup *group = notif.object;
    if (!group) return;
    
    UINavigationController *navVC = self.viewControllers[3];
    [navVC popToRootViewControllerAnimated:NO];
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = group;
    
    self.selectedIndex = 3;
    [navVC pushViewController:vc animated:YES];
}

//- (void)viewWillAppear:(BOOL)animated {
//    
//    
//    if(self.navigationController.viewControllers.count == 1)
//        [self.navigationController setNavigationBarHidden:YES animated:YES];
//    [super viewWillAppear:animated];
//}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    return viewController != self.cameraTabViewController;
}


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if ([item isEqual:self.cameraTabViewController.tabBarItem]) {
        // This is the camera button. Present modal camera instead of selecting tab
        [self presentCameraAnimated:YES];
    }
}

- (void)cameraPressed {
    [self presentCameraAnimated:YES];
}

- (void)presentCameraAnimated:(BOOL)animated {
    YACameraViewController *camVC = [YACameraViewController new];
    
    
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
    camVC.shownViaBackgrounding = NO;
    [self presentViewController:navVC animated:animated completion:nil];
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