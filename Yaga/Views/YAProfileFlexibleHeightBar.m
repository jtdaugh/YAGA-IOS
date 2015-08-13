//
//  YAProfileFlexibleHeightBar.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#define kHeaderHeight 200.0
#define kTitleOriginCollapsed 16.0
#define kTitleOriginExpanded 30.0
#define kTitleMaxFont 36.0

#import "YAProfileFlexibleHeightBar.h"
#import "SquareCashStyleBehaviorDefiner.h"

@implementation YAProfileFlexibleHeightBar

+ (YAProfileFlexibleHeightBar *)emptyProfileBar {
    YAProfileFlexibleHeightBar *bar = [[YAProfileFlexibleHeightBar alloc] initWithFrame:CGRectMake(0.0, 0.0, VIEW_WIDTH, kHeaderHeight)];
    bar.minimumBarHeight = 60;
    bar.backgroundColor = SECONDARY_COLOR;
    bar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    bar.layer.masksToBounds = YES;
    
    
    [bar addEmptyNameLabel];
    [bar addEmptyDescriptionLabel];
    [bar addEmptyViewsLabel];
    [bar addFollowBtn];
    [bar addBackBtn];
    [bar addMoreBtn];
    [bar addSegmentCtrl];

    //
    //    UILabel *viewsLabel = [UILabel new];
    //    viewsLabel.font = [UIFont fontWithName:BIG_FONT size:16];
    //    viewsLabel.textColor = [UIColor whiteColor];
    //    viewsLabel.textAlignment = NSTextAlignmentCenter;
    //    [bar addSubview:viewsLabel];
    //
    //    CGFloat btnWidth = 140;
    //    UIButton *followButton = [UIButton new];
    //    followButton.backgroundColor = [UIColor clearColor];
    //    [followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //    [followButton setTitle:@"Follow" forState:UIControlStateNormal];
    //    followButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    //    followButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
    //    followButton.layer.borderWidth = 2;
    //    followButton.layer.cornerRadius = 10;
    //    [bar addSubview:followButton];
    //
    //    UIButton *backButton = [UIButton new];
    //    backButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    //    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    //    [backButton setImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];
    //    [backButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    //    [bar addSubview:backButton];
    //
//    groupNameLabel.text = self.group.name;
//    descriptionLabel.text = @"Hosted by Arauh";
//    //    viewsLabel.text = @"456 followers      123,543 views";
//    
//    self.groupNameLabel = groupNameLabel;
//    self.groupDescriptionLabel = descriptionLabel;
    //    self.groupViewsLabel = viewsLabel;
    //    self.followButton = followButton;
    //    self.backButton = backButton;
    return bar;

}

- (void)addEmptyNameLabel {
    UILabel *groupNameLabel = [UILabel new];
    groupNameLabel.font = [UIFont fontWithName:BOLD_FONT size:kTitleMaxFont];
    groupNameLabel.textColor = [UIColor whiteColor];
    groupNameLabel.textAlignment = NSTextAlignmentCenter;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *nameExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    nameExpanded.frame = CGRectMake(20, kTitleOriginExpanded, VIEW_WIDTH-40, 40);
    [groupNameLabel addLayoutAttributes:nameExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *nameCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    nameCollapsed.frame = CGRectMake(20, kTitleOriginCollapsed, VIEW_WIDTH-40, 40);
    nameCollapsed.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [groupNameLabel addLayoutAttributes:nameCollapsed forProgress:1.0];

    [self addSubview:groupNameLabel];
    self.nameLabel = groupNameLabel;
}

- (void)addEmptyDescriptionLabel {
    UILabel *descriptionLabel = [UILabel new];
    descriptionLabel.font = [UIFont fontWithName:BIG_FONT size:16];
    descriptionLabel.textColor = [UIColor whiteColor];
    descriptionLabel.textAlignment = NSTextAlignmentCenter;

    BLKFlexibleHeightBarSubviewLayoutAttributes *descriptionExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    CGRect frame = CGRectMake(20, kTitleOriginExpanded + 50, VIEW_WIDTH - 40, 20);
    descriptionExpanded.frame = frame;
    descriptionExpanded.alpha = 1;
    descriptionExpanded.transform = CGAffineTransformIdentity;
    [descriptionLabel addLayoutAttributes:descriptionExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [[self class] collapsedAttributes];
    frame.origin.y = 50;
    collapsed.frame = frame;
    [descriptionLabel addLayoutAttributes:collapsed forProgress:1.0];
    
    [self addSubview:descriptionLabel];
    self.descriptionLabel = descriptionLabel;
}

- (void)addEmptyViewsLabel {
    UILabel *viewsLabel = [UILabel new];
    viewsLabel.font = [UIFont fontWithName:BIG_FONT size:16];
    viewsLabel.textColor = [UIColor whiteColor];
    viewsLabel.textAlignment = NSTextAlignmentCenter;
    CGRect frame =  CGRectMake(20, kTitleOriginExpanded + 90, VIEW_WIDTH - 40, 20);
    BLKFlexibleHeightBarSubviewLayoutAttributes *viewsExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    viewsExpanded.frame = frame;
    viewsExpanded.alpha = 1;
    viewsExpanded.transform = CGAffineTransformIdentity;
    [viewsLabel addLayoutAttributes:viewsExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [[self class] collapsedAttributes];
    frame.origin.y = 50;
    collapsed.frame = frame;
    [viewsLabel addLayoutAttributes:collapsed forProgress:1.0];

    [self addSubview:viewsLabel];
    self.viewsLabel = viewsLabel;
}

- (void)addFollowBtn {
    UIButton *followButton = [UIButton new];
    followButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:16];
    followButton.tintColor = [UIColor whiteColor];
    followButton.layer.cornerRadius = 6;
    followButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    followButton.layer.borderWidth = 2;
    [followButton setTitle:@"Follow" forState:UIControlStateNormal];
    
    CGRect frame =  CGRectMake((VIEW_WIDTH - 150)/2, kTitleOriginExpanded + 130, 150, 30);
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = frame;
    expanded.alpha = 1;
    [followButton addLayoutAttributes:expanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [[self class] collapsedAttributes];
    frame.origin.y = 50;
    collapsed.frame = frame;
    [followButton addLayoutAttributes:collapsed forProgress:1.0];
    
    [self addSubview:followButton];
    self.followButton = followButton;
}

- (void)addMoreBtn {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - 44, 16, 44, 44)];
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [button setImage:[UIImage imageNamed:@"More"] forState:UIControlStateNormal];
    [self addSubview:button];
    self.moreButton = button;
}

- (void)addBackBtn {
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 16, 44, 44)];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [backButton setImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];
    [self addSubview:backButton];
    self.backButton = backButton;
}

- (void)addSegmentCtrl {
    
}

+ (BLKFlexibleHeightBarSubviewLayoutAttributes *)collapsedAttributes {
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    collapsed.alpha = 0;
    return collapsed;
}

@end
