//
//  YAProfileFlexibleHeightBar.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGroupFlexibleHeightBar.h"
#import "SquareCashStyleBehaviorDefiner.h"

@implementation YAGroupFlexibleHeightBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.minimumBarHeight = 60;
        self.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
        self.layer.masksToBounds = YES;
        
        CGFloat yOrigin = kTitleOriginExpanded + 50;
        if ([self showsDescriptionLabel]) {
            [self addDescriptionLabel];
            yOrigin += 20;
        }
        [self addEmptyNameLabel];
        [self addViewsLabelsWithYOrigin:yOrigin];
        [self addMembersLabelsWithYOrigin:yOrigin];
        [self addBackBtn];
        [self addMoreBtn];
    }
    return self;
}

- (void)addEmptyNameLabel {
    UILabel *groupNameLabel = [UILabel new];
    groupNameLabel.font = [UIFont fontWithName:BOLD_FONT size:kTitleMaxFont];
    groupNameLabel.textColor = [UIColor whiteColor];
    groupNameLabel.textAlignment = NSTextAlignmentCenter;
    groupNameLabel.adjustsFontSizeToFitWidth = YES;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *nameExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    nameExpanded.frame = CGRectMake(60, kTitleOriginExpanded, VIEW_WIDTH-120, 40);
    [groupNameLabel addLayoutAttributes:nameExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *nameCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:nameExpanded];
    nameCollapsed.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, kTitleOriginCollapsed - kTitleOriginExpanded), 0.8, 0.8);
    [groupNameLabel addLayoutAttributes:nameCollapsed forProgress:1.0];
    
    [self addSubview:groupNameLabel];
    self.nameLabel = groupNameLabel;
}

- (void)addViewsLabelsWithYOrigin:(CGFloat)yOrigin {
    
    // view count top label
    UILabel *topLabel = [UILabel new];
    topLabel.font = [UIFont fontWithName:BIG_FONT size:32];
    topLabel.textColor = [UIColor whiteColor];
    topLabel.textAlignment = NSTextAlignmentCenter;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *topExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    CGRect frame =  CGRectMake(VIEW_WIDTH/2, yOrigin, VIEW_WIDTH/2, 40);
    topExpanded.frame = frame;
    [topLabel addLayoutAttributes:topExpanded forProgress:0.0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *topCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:topExpanded];
    topCollapsed.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -yOrigin), 0.5, 0.5);
    topCollapsed.alpha = 0;
    [topLabel addLayoutAttributes:topCollapsed forProgress:1.0];
    
    [self addSubview:topLabel];
    self.viewCountLabel = topLabel;
    
    
    // "video views" bottom label
    UILabel *bottomLabel = [UILabel new];
    bottomLabel.font = [UIFont fontWithName:BIG_FONT size:16];
    bottomLabel.textColor = [UIColor whiteColor];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"video views";
    BLKFlexibleHeightBarSubviewLayoutAttributes *bottomExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    frame =  CGRectMake(VIEW_WIDTH/2, yOrigin + 35, VIEW_WIDTH/2, 20);
    bottomExpanded.frame = frame;
    [bottomLabel addLayoutAttributes:bottomExpanded forProgress:0.0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *bottomCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:bottomExpanded];
    bottomCollapsed.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -yOrigin), 0.5, 0.5);
    bottomCollapsed.alpha = 0;
    [bottomLabel addLayoutAttributes:bottomCollapsed forProgress:1.0];
    
    [self addSubview:bottomLabel];
}

- (void)addMembersLabelsWithYOrigin:(CGFloat)yOrigin {
    
    // members count top label
    UILabel *topLabel = [UILabel new];
    topLabel.font = [UIFont fontWithName:BIG_FONT size:32];
    topLabel.textColor = [UIColor whiteColor];
    topLabel.textAlignment = NSTextAlignmentCenter;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *topExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    CGRect frame =  CGRectMake(0, yOrigin, VIEW_WIDTH/2, 40);
    topExpanded.frame = frame;
    [topLabel addLayoutAttributes:topExpanded forProgress:0.0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *topCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:topExpanded];
    topCollapsed.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -yOrigin), 0.5, 0.5);
    topCollapsed.alpha = 0;
    [topLabel addLayoutAttributes:topCollapsed forProgress:1.0];
    
    [self addSubview:topLabel];
    self.memberCountLabel = topLabel;
    
    
    // "members" bottom label
    UILabel *bottomLabel = [UILabel new];
    bottomLabel.font = [UIFont fontWithName:BIG_FONT size:16];
    bottomLabel.textColor = [UIColor whiteColor];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"followers";
    BLKFlexibleHeightBarSubviewLayoutAttributes *bottomExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    frame =  CGRectMake(0, yOrigin + 35, VIEW_WIDTH/2, 20);
    bottomExpanded.frame = frame;
    [bottomLabel addLayoutAttributes:bottomExpanded forProgress:0.0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *bottomCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:bottomExpanded];
    bottomCollapsed.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -yOrigin), 0.5, 0.5);
    bottomCollapsed.alpha = 0;
    [bottomLabel addLayoutAttributes:bottomCollapsed forProgress:1.0];
    
    self.membersTextLabel = bottomLabel;
    [self addSubview:bottomLabel];
}

- (void)addDescriptionLabel {
    UILabel *descriptionLabel = [UILabel new];
    descriptionLabel.font = [UIFont fontWithName:BIG_FONT size:14];
    descriptionLabel.textColor = [UIColor whiteColor];
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = CGRectMake(30, kTitleOriginExpanded + 40, VIEW_WIDTH - 60, 25);
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:expanded];
    collapsed.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -50), 0.5, 0.5);
    collapsed.alpha = 0;
    
    [descriptionLabel addLayoutAttributes:expanded forProgress:0];
    [descriptionLabel addLayoutAttributes:collapsed forProgress:1.0];
    
    [self addSubview:descriptionLabel];
    self.descriptionLabel = descriptionLabel;
}

- (void)addBackBtn {
    UIButton *backButton = [UIButton new];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [backButton setImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *backExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    backExpanded.frame = CGRectMake(0, kTitleOriginExpanded, 44, 44);
    BLKFlexibleHeightBarSubviewLayoutAttributes *backCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:backExpanded];
    backCollapsed.transform = CGAffineTransformMakeTranslation(0, kTitleOriginCollapsed - kTitleOriginExpanded);
    
    [backButton addLayoutAttributes:backExpanded forProgress:0];
    [backButton addLayoutAttributes:backCollapsed forProgress:1.0];
    
    [self addSubview:backButton];
    self.backButton = backButton;
}


- (void)addMoreBtn {
    UIButton *button = [UIButton new];
    button.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6);
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [button setImage:[UIImage imageNamed:@"InfoWhite"] forState:UIControlStateNormal];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = CGRectMake(VIEW_WIDTH - 44, kTitleOriginExpanded, 44, 44);
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:expanded];
    collapsed.transform = CGAffineTransformMakeTranslation(0, kTitleOriginCollapsed - kTitleOriginExpanded);
    
    [button addLayoutAttributes:expanded forProgress:0];
    [button addLayoutAttributes:collapsed forProgress:1.0];
    
    
    [self addSubview:button];
    self.moreButton = button;
}

@end

