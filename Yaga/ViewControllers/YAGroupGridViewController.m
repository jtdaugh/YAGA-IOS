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
#import "YAProfileFlexibleHeightBar.h"
#import "YAPullToRefreshLoadingView.h"
#import "YAViewCountManager.h"

@interface YAGroupGridViewController () <YAGroupViewCountDelegate>

@property (nonatomic,strong) UILabel *groupNameLabel;
@property (nonatomic,strong) UILabel *groupDescriptionLabel;
@property (nonatomic,strong) UILabel *groupViewsLabel;
@property (nonatomic,strong) UIButton *followButton;
@property (nonatomic,strong) UIButton *backButton;
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
    [self updateViewCountLabel];
    [YAViewCountManager sharedManager].groupViewCountDelegate = self;
    [[YAViewCountManager sharedManager] monitorGroupWithId:self.group.serverId];
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
    YAProfileFlexibleHeightBar *bar = [YAProfileFlexibleHeightBar emptyProfileBar];
    if (!self.group.publicGroup) {
        bar.maximumBarHeight -= 40;
        CGRect frame = bar.frame;
        frame.size.height -= 40;
        bar.frame = frame;
    }
    
    [bar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [bar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];
    bar.backgroundColor = self.group.publicGroup ? (self.group.amMember ? HOSTING_GROUP_COLOR : PUBLIC_GROUP_COLOR) : PRIVATE_GROUP_COLOR;
    bar.nameLabel.text = self.group.name;
    if (self.group.publicGroup) {
        bar.descriptionLabel.text = self.group.amMember ? @"You're the host!" : [NSString stringWithFormat:@"Hosted by %@", self.group.membersString];
    } else {
        bar.descriptionLabel.text = self.group.membersString;
    }
    [bar.backButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    [bar.moreButton addTarget:self action:@selector(groupInfoPressed) forControlEvents:UIControlEventTouchUpInside];
    self.followButton = bar.followButton;
    self.segmentedControl = bar.segmentedControl;
    
    if (self.group.amMember) {
        // show approved/unapproved posts segmented
        [bar.followButton removeFromSuperview];
        if (self.group.publicGroup) {
            [bar.segmentedControl addTarget:self action:@selector(segmentedControlChanged) forControlEvents:UIControlEventValueChanged];
        } else {
            [bar.segmentedControl removeFromSuperview];
        }
    } else {
        // show follow/unfollow button
        if (!self.group.publicGroup) {
            // Enforce that it is a public group.
            [self.navigationController popViewControllerAnimated:YES];
        }
        [bar.segmentedControl removeFromSuperview];
        if (self.group.amFollowing) {
            self.buttonIsUnfollow = YES;
            [bar.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
        }
        [bar.followButton addTarget:self action:@selector(followPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return bar;
}

- (void)updateViewCountLabel {
    if (self.group.publicGroup) {
        ((YAProfileFlexibleHeightBar *)self.flexibleNavBar).viewsLabel.text = [NSString stringWithFormat:@"%ld followers    %ld views", (long)self.group.followerCount, self.groupViewCount];
    } else {
        ((YAProfileFlexibleHeightBar *)self.flexibleNavBar).viewsLabel.text = [NSString stringWithFormat:@"%ld members    %ld views", (long)self.group.members.count, self.groupViewCount];
    }
}

- (void)segmentedControlChanged {
    DLog(@"Segmented control changed");
    self.pendingMode = self.segmentedControl.selectedSegmentIndex == 1;
}

- (void)followPressed {
    if (self.buttonIsUnfollow) {
        // TODO: Unfollow group
        DLog(@"Unfollow pressed");
        [self.group unfollowWithCompletion:^(NSError *error) {
            if (error) {
                DLog(@"Failed to leave group");
            } else {
                DLog(@"Left group");
            }
        }];
    } else {
        [[YAServer sharedServer] followGroupWithId:self.group.serverId withCompletion:^(id response, NSError *error) {
            if (error) {
                DLog(@"Failed to follow group");
            } else {
                DLog(@"Followed group");
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

@end
