//
//  YAStandardFlexibleHeightBar.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAStandardFlexibleHeightBar.h"
#import "FacebookStyleBarBehaviorDefiner.h"

#define kBarHeight 66.0
#define kStatusBarHeight 20.0

@implementation YAStandardFlexibleHeightBar

+ (YAStandardFlexibleHeightBar *)emptyStandardFlexibleBar {

    YAStandardFlexibleHeightBar *bar = [[YAStandardFlexibleHeightBar alloc] initWithFrame:CGRectMake(0.0, 0.0, VIEW_WIDTH, 66)];
    bar.minimumBarHeight = 20;
    bar.behaviorDefiner = [FacebookStyleBarBehaviorDefiner new];

    UILabel *titleLabel = [UILabel new];
    titleLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    BLKFlexibleHeightBarSubviewLayoutAttributes *titleExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    titleExpanded.frame = CGRectMake(kFlexNavBarButtonWidth - 40, kStatusBarHeight, VIEW_WIDTH-2*kFlexNavBarButtonWidth + 80, kBarHeight - kStatusBarHeight);
    [titleLabel addLayoutAttributes:titleExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *titleCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    titleCollapsed.frame = CGRectMake(kFlexNavBarButtonWidth - 40, -30, VIEW_WIDTH-2*kFlexNavBarButtonWidth + 80, 30);
    titleCollapsed.alpha = 0;
    [titleLabel addLayoutAttributes:titleCollapsed forProgress:1.0];
    
    [bar addSubview:titleLabel];
    bar.titleLabel = titleLabel;
    
    CGFloat buttonSize = kFlexNavBarButtonHeight;
    
    UIButton *leftButton = [UIButton new];
    leftButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 10);
    leftButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    leftButton.tintColor = [UIColor whiteColor];
    leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    BLKFlexibleHeightBarSubviewLayoutAttributes *leftButtonExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    leftButtonExpanded.frame = CGRectMake(10, kStatusBarHeight, kFlexNavBarButtonWidth, buttonSize);
    [leftButton addLayoutAttributes:leftButtonExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *leftButtonCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    leftButtonCollapsed.frame = CGRectMake(10, -buttonSize, kFlexNavBarButtonWidth, buttonSize);
    leftButtonCollapsed.alpha = 0;
    [leftButton addLayoutAttributes:leftButtonCollapsed forProgress:1.0];
    
    [bar addSubview:leftButton];
    bar.leftBarButton = leftButton;
    
    UIButton *rightButton = [UIButton new];
    rightButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0);
    rightButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    rightButton.tintColor = [UIColor whiteColor];
    rightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *rightButtonExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    rightButtonExpanded.frame = CGRectMake(VIEW_WIDTH - kFlexNavBarButtonWidth - 10, kStatusBarHeight, kFlexNavBarButtonWidth, buttonSize);
    [rightButton addLayoutAttributes:rightButtonExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *rightButtonCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    rightButtonCollapsed.frame = CGRectMake(VIEW_WIDTH - kFlexNavBarButtonWidth - 10, -buttonSize, kFlexNavBarButtonWidth, buttonSize);
    rightButtonCollapsed.alpha = 0;
    [rightButton addLayoutAttributes:rightButtonCollapsed forProgress:1.0];
    
    [bar addSubview:rightButton];
    bar.rightBarButton = rightButton;
    
    bar.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
    return bar;
}


@end