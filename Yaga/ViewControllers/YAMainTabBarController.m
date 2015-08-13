//
//  YAMainViewController.m
//  
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAMainTabBarController.h"
#import "YAUtils.h"
#import "YAGroupsNavigationController.h"
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

@interface YAMainTabBarController () <UIViewControllerTransitioningDelegate, UITabBarControllerDelegate>

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
    
    UIViewController *vc0 = [[YAGroupsNavigationController alloc] initWithRootViewController:[YAStreamViewController new]];
    vc0.tabBarItem.image = [UIImage imageNamed:@"StreamBarItem"];
    vc0.tabBarItem.title = @"Feed";
    
    UIViewController *vc1 = [[YAGroupsNavigationController alloc] initWithRootViewController:[YAFindGroupsViewConrtoller new]];
    vc1.tabBarItem.image = [UIImage imageNamed:@"ExploreBarItem"];
    vc1.tabBarItem.title = @"Explore";
    
    UIViewController *vc2 = [UIViewController new];

    UIViewController *vc3 = [[YAGroupsNavigationController alloc] initWithRootViewController:[YAGroupsListViewController new]];
    vc3.tabBarItem.image = [UIImage imageNamed:@"ChannelsBarItem"];
    vc3.tabBarItem.title = @"Channels";

    UIViewController *vc4 = [[YAGroupsNavigationController alloc] initWithRootViewController:[YAMyStreamViewController new]];
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
    
}


- (void)presentCreateGroup {
    NameGroupViewController *vc = [NameGroupViewController new];
    YAGroupsNavigationController *createGroupNavController = [[YAGroupsNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:createGroupNavController animated:YES completion:nil];
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
    camVC.shownViaBackgrounding = NO;
    [self presentViewController:camVC animated:animated completion:nil];
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
