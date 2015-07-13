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
#import "YACreateGroupNavigationController.h"

#import "YAUtils.h"
#import "YAGroupOptionsViewController.h"
#import "YACameraManager.h"

#import "YACameraViewController.h"
#import "YAGroupsViewController.h"
#import "YACollectionViewController.h"
#import "YAPostCaptureViewController.h"
#import "YAFindGroupsViewConrtoller.h"
#import "NameGroupViewController.h"

#import "SloppySwiper.h"

//Swift headers
//#import "Yaga-Swift.h"

#define HEADER_HEIGHT 32
#define HEADER_SPACING 6

@interface YAGridViewController ()

@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;
@property (nonatomic, strong) UINavigationController *bottomNavigationController;
@property (strong, nonatomic) SloppySwiper *swiper;
@property (nonatomic, strong) UIView *onboardingHeaderView;
@property (nonatomic, strong) UILabel *onboardingLabel;
@property (nonatomic, strong) UIView *myGroupsHeaderView;
@property (nonatomic, strong) YAGroupsViewController *groupsViewController;

@property (nonatomic) BOOL onboarding;

@end

@implementation YAGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
//    [self.navigationController setNavigationBarHidden:YES animated:NO];
//    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.onboarding = ![YAUtils hasVisitedGifGrid];

    [self setupView];
    self.animationController = [YAAnimatedTransitioningController new];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openGroupOptions)
                                                 name:OPEN_GROUP_OPTIONS_NOTIFICATION
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showCreateGroup:)
                                                 name:BEGIN_CREATE_GROUP_FROM_VIDEO_NOTIFICATION
                                               object:nil];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_GROUP_OPTIONS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BEGIN_CREATE_GROUP_FROM_VIDEO_NOTIFICATION object:nil];
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
    CGFloat topInset;
    if (!self.onboarding ) {
        topInset = VIEW_HEIGHT/2 + 2 - CAMERA_MARGIN + HEADER_HEIGHT - HEADER_SPACING;
    } else  {
        topInset = VIEW_HEIGHT/3 - CAMERA_MARGIN + HEADER_HEIGHT - HEADER_SPACING;
    }

    _groupsViewController = [[YAGroupsViewController alloc] initWithCollectionViewTopInset:topInset];;
    
    _groupsViewController.delegate = self;
    _bottomNavigationController = [[UINavigationController alloc] initWithRootViewController:_groupsViewController];
    _bottomNavigationController.view.frame = CGRectMake(0, CAMERA_MARGIN, VIEW_WIDTH, VIEW_HEIGHT - CAMERA_MARGIN);
    [_bottomNavigationController.view.layer setMasksToBounds:NO];
    _bottomNavigationController.interactivePopGestureRecognizer.enabled = NO;
    self.swiper = [[SloppySwiper alloc] initWithNavigationController:_bottomNavigationController];
    _bottomNavigationController.delegate = self.swiper;

    [self addChildViewController:_bottomNavigationController];
    [self.view addSubview:_bottomNavigationController.view];
    
    self.myGroupsHeaderView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, HEADER_HEIGHT)];
    self.myGroupsHeaderView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];

    UILabel *myGroupsLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, 200, HEADER_HEIGHT-10)];
    [myGroupsLabel setFont:[UIFont fontWithName:BOLD_FONT size:16]];
    myGroupsLabel.textColor = [UIColor lightGrayColor];
    myGroupsLabel.text = @"My Groups";
    [self.myGroupsHeaderView addSubview:myGroupsLabel];
    
    if (!self.onboarding) {
        [self setupCameraViewController];
        CGRect headerFrame = self.myGroupsHeaderView.frame;
        headerFrame.origin.y = VIEW_HEIGHT/2 - CAMERA_MARGIN;
        self.myGroupsHeaderView.frame = headerFrame;
        [self.groupsViewController.view addSubview:self.myGroupsHeaderView];
        
        
    } else {
        self.onboardingHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/3)];
        self.onboardingHeaderView.backgroundColor = PRIMARY_COLOR;
        [self.view addSubview:self.onboardingHeaderView];
        CGSize logoSize = CGSizeMake(120, 80);
        UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake((VIEW_WIDTH - logoSize.width)/2, 20, logoSize.width, logoSize.height)];
        logo.contentMode = UIViewContentModeScaleAspectFit;
        logo.image = [UIImage imageNamed:@"Logo"];
        [self.onboardingHeaderView addSubview:logo];
        CGSize labelSize = CGSizeMake(VIEW_WIDTH*0.85, 60);
        self.onboardingLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - labelSize.width)/2, self.onboardingHeaderView.frame.size.height - labelSize.height - 20, labelSize.width, labelSize.height)];
        self.onboardingLabel.textAlignment = NSTextAlignmentCenter;
        self.onboardingLabel.font = [UIFont fontWithName:BIG_FONT size:20];
        self.onboardingLabel.textColor = [UIColor whiteColor];
        self.onboardingLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.onboardingLabel.numberOfLines = 2;
        self.onboardingLabel.text = @"Welcome!\nPick a group and enjoy!";
        [self.onboardingHeaderView addSubview:self.onboardingLabel];
        CGRect headerFrame = self.myGroupsHeaderView.frame;
        headerFrame.origin.y = VIEW_HEIGHT/3- CAMERA_MARGIN;
        self.myGroupsHeaderView.frame = headerFrame;
        [self.groupsViewController.view addSubview:self.myGroupsHeaderView];

    }
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)setupCameraViewController {
    _cameraViewController = [YACameraViewController new];
    _cameraViewController.delegate = self;
    
    // Add shadow to camera view
    _cameraViewController.view.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2 + recordButtonWidth/2);
    _cameraViewController.view.layer.masksToBounds = NO;
    _cameraViewController.view.layer.shadowOffset = CGSizeMake(0, 8);
    _cameraViewController.view.layer.shadowRadius = 3;
    _cameraViewController.view.layer.shadowOpacity = 0.f;
    _cameraViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    [self addChildViewController:_cameraViewController];
    [self.view addSubview:_cameraViewController.view];

}

- (void)swapOutOfOnboardingState {
    if (self.onboarding) {
        self.onboarding = NO;
        [self setupCameraViewController];
        [self.onboardingHeaderView removeFromSuperview];
        
        CGRect headerFrame = self.myGroupsHeaderView.frame;
        headerFrame.origin.y = VIEW_HEIGHT/2;
        self.myGroupsHeaderView.frame = headerFrame;
        [self.groupsViewController changeTopInset:VIEW_HEIGHT/2-CAMERA_MARGIN + HEADER_HEIGHT - HEADER_SPACING];
        self.myGroupsHeaderView.layer.zPosition = 1000;
    }
}

- (void)showCreateGroup:(NSNotification *)notif {
    YAVideo *video = notif.object;
    [self showCreateGroupWithInitialVideo:video];
}

- (void)showCreateGroupWithInitialVideo:(YAVideo *)initialVideo {
    NameGroupViewController *vc = [NameGroupViewController new];
    YACreateGroupNavigationController *createGroupNavController = [[YACreateGroupNavigationController alloc] initWithRootViewController:vc];

    if (initialVideo) {
        vc.initialVideo = initialVideo; // may be nil
        [self.presentedViewController presentViewController:createGroupNavController animated:YES completion:nil];
    } else {
        [self presentViewController:createGroupNavController animated:YES completion:nil];
    }
}

- (void)showFindGroups {
    YAGroupsNavigationController *navController = [[YAGroupsNavigationController alloc] initWithRootViewController:[YAFindGroupsViewConrtoller new]];
    [self presentViewController:navController animated:YES completion:nil];

}

- (UICollectionView *)getRelevantCollectionView {
    NSArray *vcs = self.bottomNavigationController.viewControllers;
    for (NSUInteger i = [vcs count] - 1;; i--) {
        UIViewController *vc = vcs[i];
        if ([vc isKindOfClass:[YAGroupsViewController class]]) {
            return [((YAGroupsViewController *)vc) collectionView];
        } else if ([vc isKindOfClass:[YACollectionViewController class]]) {
            return [((YACollectionViewController *)vc) collectionView];
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
        self.bottomNavigationController.view.frame = CGRectMake(0, origin + separator, self.bottomNavigationController.view.frame.size.width, VIEW_HEIGHT - origin - separator);
        
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
    if (self.onboarding) return;
    CGRect cameraFrame = self.cameraViewController.view.frame;
    CGRect gridFrame = self.bottomNavigationController.view.frame;
    CGRect myGroupsFrame = self.myGroupsHeaderView.frame;
    
    UICollectionView *collectionView = [self getRelevantCollectionView];
    if (!collectionView) return;
    
    CGFloat scrollOffset = collectionView.contentOffset.y;
    CGFloat offset = collectionView.contentInset.top + scrollOffset;
    
    // Update the groups table view to match the scrolling of the group table view.
    id groupsVC = self.bottomNavigationController.viewControllers[0];
    UICollectionView *groupsCollectionView;
    if ([groupsVC respondsToSelector:@selector(collectionView)])
        groupsCollectionView = [groupsVC collectionView];
    if (groupsCollectionView && ![collectionView isEqual:groupsCollectionView]) {
        CGPoint groupsOffset = groupsCollectionView.contentOffset;
        groupsOffset.y = MIN(collectionView.contentOffset.y - HEADER_HEIGHT + HEADER_SPACING, -HEADER_HEIGHT + HEADER_SPACING);
        groupsCollectionView.contentOffset = groupsOffset;
    }
    
    if(offset < 0) {
        offset = 0;
    } else if(offset > VIEW_HEIGHT/2 - CAMERA_MARGIN) {
        offset = VIEW_HEIGHT/2 - CAMERA_MARGIN;
        [self toggleShadow:YES];
    } else {
        [self toggleShadow:NO];
    }
    
    cameraFrame.origin.y = -offset;
    myGroupsFrame.origin.y = VIEW_HEIGHT/2-CAMERA_MARGIN-offset;
    self.myGroupsHeaderView.frame = myGroupsFrame;
    if (![self.cameraViewController.recording boolValue]) {
        self.cameraViewController.view.frame = cameraFrame;
    }
    self.bottomNavigationController.view.frame = gridFrame;
}

- (void)updateCameraAccessoriesWithViewIndex:(NSUInteger)index {
    [self.cameraViewController setCameraButtonMode:index ? YACameraButtonModeBackAndInfo : YACAmeraButtonModeFindAndCreate];
}

#pragma mark - YACameraViewControllerDelegate
- (void)openGroupOptions {
    if(![YAUser currentUser].currentGroup)
        return;
    
    if([self.navigationController.topViewController isKindOfClass:[YAGroupOptionsViewController class]]) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    
    YAGroupOptionsViewController *vc = [[YAGroupOptionsViewController alloc] init];
    vc.group = [YAUser currentUser].currentGroup;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)scrollToTop {
    UICollectionView *collectionView = [self getRelevantCollectionView];
    if (!collectionView) return;
    if (self.onboarding) return;
    if ([collectionView.superview isEqual:self.groupsViewController.view]) {
        [collectionView setContentOffset:CGPointMake(0, -1 * (VIEW_HEIGHT/2 - CAMERA_MARGIN+ HEADER_HEIGHT - HEADER_SPACING)) animated:YES];
    } else {
        [collectionView setContentOffset:CGPointMake(0, -1 * (VIEW_HEIGHT/2 - CAMERA_MARGIN)) animated:YES];
    }
}

- (void)backPressed {
    // Dont set current group to nil here or else the gif collection view
    // reloads data and we see the loading monkey as it pops.
    [self updateCameraAccessoriesWithViewIndex:0];
    [self.bottomNavigationController popViewControllerAnimated:YES];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)presentNewlyRecordedVideo:(YAVideo *)video {
    YAPostCaptureViewController *vc = [[YAPostCaptureViewController alloc] initWithVideo:video];
    [self.navigationController presentViewController:vc animated:NO completion:nil];
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

#pragma mark - shadow 

- (void)toggleShadow:(BOOL)shadow {
    if ([[self.bottomNavigationController visibleViewController] isEqual:self.groupsViewController]) {
        [self removeShadowBelowCamera];
    } else {
        shadow ? [self addShadowBelowCamera] : [self removeShadowBelowCamera];
    }
}
- (void)addShadowBelowCamera {
    if (!self.cameraViewController.view) return;
    if (self.cameraViewController.view.layer.shadowOpacity != 0.35f) {
        CABasicAnimation *borderAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        borderAnimation.fromValue = @(0.f);
        borderAnimation.toValue = @(0.35f);
        borderAnimation.duration = 0.25f;
        
        [self.cameraViewController.view.layer addAnimation:borderAnimation forKey:@"shadowOpacity"];
        self.cameraViewController.view.layer.shadowOpacity = 0.35f;
    }
}

- (void)removeShadowBelowCamera {
    if (!self.cameraViewController.view) return;
    if (self.cameraViewController.view.layer.shadowOpacity != 0.f) {
        CABasicAnimation *borderAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        borderAnimation.fromValue = @(self.cameraViewController.view.layer.shadowOpacity);
        borderAnimation.toValue = @(0.f);
        borderAnimation.duration = 0.25f;
        
        [self.cameraViewController.view.layer addAnimation:borderAnimation forKey:@"shadowOpacity"];
        self.cameraViewController.view.layer.shadowOpacity = 0.f;
    }
}
@end
