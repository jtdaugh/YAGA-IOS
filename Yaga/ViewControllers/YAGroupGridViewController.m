//
//  YAGroupGridViewController.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGroupGridViewController.h"
#import "YAGroup.h"
#import "YAServer.h"

#import "BLKFlexibleHeightBar.h"
#import "YAPrivateGroupFlexibleHeightBar.h"
#import "YAHostingGroupFlexibleHeightBar.h"
#import "YAPublicGroupFlexibleHeightBar.h"
#import "YAPullToRefreshLoadingView.h"
#import "YAViewCountManager.h"
#import "YAPopoverView.h"

@interface YAGroupGridViewController () <YAGroupViewCountDelegate>

@property (nonatomic,strong) UILabel *groupNameLabel;
@property (nonatomic,strong) UIButton *s;
@property (nonatomic,strong) UIButton *backButton;
@property (nonatomic,strong) UIButton *moreButton;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic) BOOL buttonIsUnfollow;

@property (nonatomic) NSUInteger groupViewCount;

@end

@implementation YAGroupGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.groupViewCount = 0;
    
    self.pendingMode = self.openStraightToPendingSection;
    
    self.segmentedControl.selectedSegmentIndex = self.openStraightToPendingSection ? 1 : 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDueToApprovalOrRejection) name:VIDEO_REJECTED_OR_APPROVED_NOTIFICATION object:nil];
    // Do any additional setup after loading the view.
}

- (void)reloadDueToApprovalOrRejection {
    [self reloadSortedVideos];
    [self.collectionView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBarWithGroupInfo];
    [self updateViewCountLabel];
    [YAViewCountManager sharedManager].groupViewCountDelegate = self;
    [[YAViewCountManager sharedManager] monitorGroupWithId:self.group.serverId];
    [[Mixpanel sharedInstance] track:@"Viewed Group Grid"];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.group.publicGroup) {
        if (self.group.amMember) {
            // Host
            if (![YAUtils hasCreatedPublicGroup]) {
                [YAUtils setCreatedPublicGroup];
                [self showFirstCreatePublicGroupPopover];
            }
        } else {
            // Follower
            if (![YAUtils hasVisitedPublicGroup]) {
                [YAUtils setVisitedPublicGroup];
                [self showFirstPublicGroupVisitPopover];
            }
        }
    } else {
        // Member of private group
        if (![YAUtils hasVisitedPrivateGroup]) {
            [YAUtils setVisitedPrivateGroup];
            [self showFirstPrivateGroupVisitPopover];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [YAViewCountManager sharedManager].groupViewCountDelegate = nil;
    [[YAViewCountManager sharedManager] monitorGroupWithId:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BLKFlexibleHeightBar *)createNavBar {
    YAGroupFlexibleHeightBar *bar;
    if (!self.group.publicGroup) {
        bar = [[YAPrivateGroupFlexibleHeightBar alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, kPrivateGroupBarHeight)];
        self.moreButton = ((YAPrivateGroupFlexibleHeightBar *) bar).moreButton;
        [((YAPrivateGroupFlexibleHeightBar *) bar).moreButton addTarget:self action:@selector(groupInfoPressed) forControlEvents:UIControlEventTouchUpInside];
    } else {
        if (self.group.amMember) {
            bar = [[YAHostingGroupFlexibleHeightBar alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, kHostingGroupBarHeight)];
            self.segmentedControl = ((YAHostingGroupFlexibleHeightBar *)bar).segmentedControl;
            [((YAHostingGroupFlexibleHeightBar *)bar).segmentedControl addTarget:self action:@selector(segmentedControlChanged) forControlEvents:UIControlEventValueChanged];

            self.moreButton = ((YAHostingGroupFlexibleHeightBar *)bar).moreButton;
            [((YAHostingGroupFlexibleHeightBar *)bar).moreButton addTarget:self action:@selector(groupInfoPressed) forControlEvents:UIControlEventTouchUpInside];
        } else {
            bar = [[YAPublicGroupFlexibleHeightBar alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, kPublicGroupBarHeight)];
            [((YAPublicGroupFlexibleHeightBar *)bar).followButton addTarget:self action:@selector(followPressed) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    self.groupNameLabel = bar.nameLabel;
    self.backButton = bar.backButton;
    [bar.backButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [bar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [bar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];
    return bar;

}

- (void)updateBarWithGroupInfo {
    NSString *string = self.group.membersString;
    if (self.group.publicGroup) {
        self.groupNameLabel.text = self.group.name;
        if (self.group.amMember) {
            // Hosting
            if ([string isEqualToString:@"No members"]) {
                ((YAHostingGroupFlexibleHeightBar *)self.flexibleNavBar).descriptionLabel.text = @"You're the host";
            } else {
                ((YAHostingGroupFlexibleHeightBar *)self.flexibleNavBar).descriptionLabel.text = [NSString stringWithFormat:@"Co-Hosts: %@", self.group.membersString];
            }
        } else {
            // Following
            ((YAPublicGroupFlexibleHeightBar *)self.flexibleNavBar).descriptionLabel.text = [NSString stringWithFormat:@"Hosted by %@", self.group.membersString];
            if (self.group.amFollowing) {
                self.buttonIsUnfollow = YES;
                [((YAPublicGroupFlexibleHeightBar *)self.flexibleNavBar).followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
            } else {
                self.buttonIsUnfollow = NO;
                [((YAPublicGroupFlexibleHeightBar *)self.flexibleNavBar).followButton setTitle:@"+ Follow" forState:UIControlStateNormal];
            }
        }
    } else {
        self.groupNameLabel.text = [@"🔒 " stringByAppendingString:self.group.name];
    }
}

- (void)updateViewCountLabel {
    ((YAGroupFlexibleHeightBar *)self.flexibleNavBar).viewCountLabel.text = [NSString stringWithFormat:@"%ld", self.groupViewCount];
    if (self.group.publicGroup) {
        ((YAGroupFlexibleHeightBar *)self.flexibleNavBar).memberCountLabel.text = [NSString stringWithFormat:@"%ld", self.group.followerCount];
    } else {
        ((YAGroupFlexibleHeightBar *)self.flexibleNavBar).memberCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.group.members.count + 1];  // add 1 to the member count because it excludes you
    }
}

- (void)segmentedControlChanged {
    DLog(@"Segmented control changed");
    self.pendingMode = self.segmentedControl.selectedSegmentIndex == 1;
}

- (void)followPressed {
    if (self.buttonIsUnfollow) {
        [[Mixpanel sharedInstance] track:@"Unfollow Pressed"];
        // TODO: Unfollow group
        DLog(@"Unfollow pressed");
        [self.group unfollowWithCompletion:^(NSError *error) {
            if (error) {
                DLog(@"Failed to leave group");
            } else {
                DLog(@"Left group");
                [self updateViewCountLabel];
                self.buttonIsUnfollow = NO;
                [((YAPublicGroupFlexibleHeightBar *)self.flexibleNavBar).followButton setTitle:@"+ Follow" forState:UIControlStateNormal];
            }
        }];
    } else {
        [[Mixpanel sharedInstance] track:@"Follow Pressed"];
        [self.group followWithCompletion:^(NSError *error) {
            if (error) {
                DLog(@"Failed to follow group");
                [YAUtils showHudWithText:@"👎"];
            } else {
                [YAUtils showHudWithText:@"👍"];
                [self updateViewCountLabel];
                DLog(@"Followed group");
                self.buttonIsUnfollow = YES;
                [((YAPublicGroupFlexibleHeightBar *)self.flexibleNavBar).followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
            }
        }];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_REJECTED_OR_APPROVED_NOTIFICATION object:nil];
}

#pragma mark - YAGroupViewCountDelegate

- (void)groupUpdatedWithMyViewCount:(NSUInteger)myViewCount otherViewCount:(NSUInteger)othersViewCount {
    self.groupViewCount = myViewCount + othersViewCount;
    [self updateViewCountLabel];
}

- (void)showFirstPublicGroupVisitPopover {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_PUBLIC_GROUP_VISIT_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_PUBLIC_GROUP_VISIT_BODY", @"") dismissText:@"Got it" addToView:self.view] show];
}

- (void)showFirstCreatePublicGroupPopover {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_CREATE_PUBLIC_GROUP_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_CREATE_PUBLIC_GROUP_BODY", @"") dismissText:@"Got it" addToView:self.view] show];
}

- (void)showFirstPrivateGroupVisitPopover {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_PRIVATE_GROUP_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_PRIVATE_GROUP_BODY", @"") dismissText:@"Got it" addToView:self.view] show];
}


@end
