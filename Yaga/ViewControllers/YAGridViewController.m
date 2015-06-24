//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGridViewController.h"

#import "YaOnboardingNavigationController.h"
#import "YAPhoneNumberViewController.h"
#import "YAGroupAddMembersViewController.h"
#import "YAAnimatedTransitioningController.h"

#import "YAUtils.h"
#import "YAGroupOptionsViewController.h"
#import "YACameraManager.h"

#import "YACameraViewController.h"
#import "YAGroupsViewController.h"
#import "YACollectionViewController.h"
#import "YAPostCaptureViewController.h"

//Swift headers
//#import "Yaga-Swift.h"


@interface YAGridViewController ()

@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;

@end

@implementation YAGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    [self setupView];
    [[YACameraManager sharedManager] initCamera];
    self.animationController = [YAAnimatedTransitioningController new];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)logout {
    [[YAUser currentUser] logout];
    
    YaOnboardingNavigationController *vc = [[YaOnboardingNavigationController alloc] init];
    [vc setViewControllers:@[[[YAPhoneNumberViewController alloc] init]]];
    
    [self presentViewController:vc animated:NO completion:^{
    }];
    
}

- (void)setupView {
    YAGroupsViewController *groupsRootViewController = [YAGroupsViewController new];
    groupsRootViewController.delegate = self;
    _groupsNavigationController = [[YAGroupsNavigationController alloc] initWithRootViewController:groupsRootViewController];
    _groupsNavigationController.view.frame = CGRectMake(0, CAMERA_MARGIN, VIEW_WIDTH, VIEW_HEIGHT - CAMERA_MARGIN);
    [_groupsNavigationController.view.layer setMasksToBounds:NO];
    _groupsNavigationController.interactivePopGestureRecognizer.enabled = NO;
    
    [self addChildViewController:_groupsNavigationController];
    [self.view addSubview:_groupsNavigationController.view];
    
    _cameraViewController = [YACameraViewController new];
    _cameraViewController.delegate = self;
    
    _cameraViewController.view.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2 + recordButtonWidth/2);
    [self addChildViewController:_cameraViewController];
    [self.view addSubview:_cameraViewController.view];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (UICollectionView *)getRelevantCollectionView {
    NSArray *vcs = self.groupsNavigationController.viewControllers;
    for (NSUInteger i = [vcs count] - 1;; i--) {
        id vc = vcs[i];
        if ([vc isKindOfClass:[YAGroupsViewController class]] ||
            [vc isKindOfClass:[YACollectionViewController class]]) {
            return [vc collectionView];
        }
        if (i == 0) break;
    }
    return nil;
}

#pragma mark - YAGridViewControllerDelegate

- (void)showCamera:(BOOL)show showPart:(BOOL)showPart animated:(BOOL)animated completion:(cameraCompletion)completion {
    
    void (^showHideBlock)(void) = ^void(void) {
        if(show) {
            self.cameraViewController.view.frame = CGRectMake(0, 0, self.cameraViewController.view.frame.size.width, self.cameraViewController.view.frame.size.height);
        }
        else {
            self.cameraViewController.view.frame = CGRectMake(0, -self.cameraViewController.view.frame.size.height + (showPart ? ELEVATOR_MARGIN : 0) + recordButtonWidth / 2, self.cameraViewController.view.frame.size.width, self.cameraViewController.view.frame.size.height);
        }
        CGFloat origin = self.cameraViewController.view.frame.origin.y + self.cameraViewController.view.frame.size.height - recordButtonWidth / 2;
        CGFloat separator = show ? 2 : 0;
        self.groupsNavigationController.view.frame = CGRectMake(0, origin + separator, self.groupsNavigationController.view.frame.size.width, VIEW_HEIGHT - origin - separator);
        
        [self.cameraViewController showCameraAccessories:(show && !showPart)];
    };
    
    if(animated) {
        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
            showHideBlock();
            
        } completion:^(BOOL finished) {
            if(finished && completion)
                completion();
        }];
    }
    else {
        showHideBlock();
    }
}

- (void)enableRecording:(BOOL)enable {
    [self.cameraViewController enableRecording:enable];
}

- (void)scrollViewDidScroll {
    CGRect cameraFrame = self.cameraViewController.view.frame;
    CGRect gridFrame = self.groupsNavigationController.view.frame;
    
    UICollectionView *collectionView = [self getRelevantCollectionView];
    if (!collectionView) return;
    
    CGFloat scrollOffset = collectionView.contentOffset.y;
    CGFloat offset = collectionView.contentInset.top + scrollOffset;
    
    // Update the groups table view to match the scrolling of the group table view.
    id groupsVC = self.groupsNavigationController.viewControllers[0];
    UICollectionView *groupsCollectionView;
    if ([groupsVC respondsToSelector:@selector(collectionView)])
        groupsCollectionView = [groupsVC collectionView];
    if (groupsCollectionView && ![collectionView isEqual:groupsCollectionView]) {
        CGPoint groupsOffset = groupsCollectionView.contentOffset;
        groupsOffset.y = MIN(collectionView.contentOffset.y, 0);
        groupsCollectionView.contentOffset = groupsOffset;
    }
    
    if(offset < 0) {
        offset = 0;
    } else if(offset > VIEW_HEIGHT/2 - CAMERA_MARGIN) {
        offset = VIEW_HEIGHT/2 - CAMERA_MARGIN;
        [self.cameraViewController showBottomShadow];
    } else {
        [self.cameraViewController removeBottomShadow];
    }
    
    cameraFrame.origin.y = -offset;

    if (![self.cameraViewController.recording boolValue]) {
        self.cameraViewController.view.frame = cameraFrame;
    }
    self.groupsNavigationController.view.frame = gridFrame;
}

- (void)updateCameraAccessories {
    [self.cameraViewController updateCameraAccessories];
}

#pragma mark - YACameraViewControllerDelegate
- (void)openGroupOptions {
    YAGroupOptionsViewController *vc = [[YAGroupOptionsViewController alloc] init];
    vc.group = [YAUser currentUser].currentGroup;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)scrollToTop {
    UICollectionView *collectionView = [self getRelevantCollectionView];
    if (!collectionView) return;
    [collectionView setContentOffset:CGPointMake(0, -1 * (VIEW_HEIGHT/2 - CAMERA_MARGIN)) animated:YES];
}

- (void)backPressed {
    [YAUser currentUser].currentGroup = nil;
    [self.groupsNavigationController popViewControllerAnimated:YES];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)presentNewlyRecordedVideo:(YAVideo *)video {
    YAPostCaptureViewController *vc = [[YAPostCaptureViewController alloc] initWithVideo:video];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;

    [self presentViewController:vc animated:NO completion:nil];
}

- (void)setInitialAnimationFrame:(CGRect)initialFrame {
    self.animationController.initialFrame = initialFrame;
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
