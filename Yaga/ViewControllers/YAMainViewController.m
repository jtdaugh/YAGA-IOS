//
//  YAMainViewController.m
//  
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAMainViewController.h"
#import "YAUtils.h"
#import "YAGroupsNavigationController.h"
#import "YACameraViewController.h"
#import "YAAnimatedTransitioningController.h"
#import "YACameraManager.h"

@interface YAMainViewController () <UIViewControllerTransitioningDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;

@property (nonatomic, weak) UIViewController *cameraTabViewController;

@end

@implementation YAMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [YAUtils randomQuoteWithCompletion:^(NSString *quote, NSError *error) {
//        self.navigationItem.prompt = quote;
//    }];
    self.cameraTabViewController = self.viewControllers[2];
    
    [[YACameraManager sharedManager] initCamera];
    
    self.animationController = [YAAnimatedTransitioningController new];
    self.delegate = self;
    self.tabBar.itemSpacing = VIEW_WIDTH/2;
    self.tabBar.tintColor = PRIMARY_COLOR;
    self.tabBar.barTintColor = [UIColor whiteColor];

//    self.tabBar.backgroundImage = [YAUtils imageWithColor:[UIColor whiteColor]];
//    self.tabBar.shadowImage = [UIImage imageNamed:@"BarShadow"];
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
