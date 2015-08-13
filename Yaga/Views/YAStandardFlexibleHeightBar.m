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
    titleLabel.font = [UIFont fontWithName:BIG_FONT size:20];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    BLKFlexibleHeightBarSubviewLayoutAttributes *titleExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    titleExpanded.frame = CGRectMake(70, kStatusBarHeight, VIEW_WIDTH-140, kBarHeight - kStatusBarHeight);
    [titleLabel addLayoutAttributes:titleExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *titleCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    titleCollapsed.frame = CGRectMake(70, -30, VIEW_WIDTH-140, 30);
    titleCollapsed.alpha = 0;
    [titleLabel addLayoutAttributes:titleCollapsed forProgress:1.0];
    
    [bar addSubview:titleLabel];
    bar.titleLabel = titleLabel;
    
    CGFloat buttonSize = kBarHeight - kStatusBarHeight;
    
    UIButton *leftButton = [UIButton new];
    leftButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    leftButton.imageView.contentMode = UIViewContentModeScaleAspectFit;

    BLKFlexibleHeightBarSubviewLayoutAttributes *leftButtonExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    leftButtonExpanded.frame = CGRectMake(0, kStatusBarHeight, buttonSize, buttonSize);
    [leftButton addLayoutAttributes:leftButtonExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *leftButtonCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    leftButtonCollapsed.frame = CGRectMake(0, -buttonSize, buttonSize, buttonSize);
    leftButtonCollapsed.alpha = 0;
    [leftButton addLayoutAttributes:leftButtonCollapsed forProgress:1.0];
    
    [bar addSubview:leftButton];
    bar.leftBarButton = leftButton;
    
    UIButton *rightButton = [UIButton new];
    rightButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    rightButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *rightButtonExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    rightButtonExpanded.frame = CGRectMake(VIEW_WIDTH - buttonSize, kStatusBarHeight, buttonSize, buttonSize);
    [rightButton addLayoutAttributes:rightButtonExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *rightButtonCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    rightButtonCollapsed.frame = CGRectMake(VIEW_WIDTH - buttonSize, -buttonSize, buttonSize, buttonSize);
    rightButtonCollapsed.alpha = 0;
    [rightButton addLayoutAttributes:rightButtonCollapsed forProgress:1.0];
    
    [bar addSubview:rightButton];
    bar.rightBarButton = rightButton;
    
    bar.backgroundColor = PRIMARY_COLOR;
    return bar;
}


@end
