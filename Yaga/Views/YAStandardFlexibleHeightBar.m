//
//  YAStandardFlexibleHeightBar.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAStandardFlexibleHeightBar.h"

#define kBarHeight 66.0
#define kStatusBarHeight 20.0

@implementation YAStandardFlexibleHeightBar

+ (YAStandardFlexibleHeightBar *)emptyStandardFlexibleBar {

    YAStandardFlexibleHeightBar *bar = [[YAStandardFlexibleHeightBar alloc] initWithFrame:CGRectMake(0.0, 0.0, VIEW_WIDTH, 66)];
    bar.minimumBarHeight = 20;

    UIButton *titleButton = [UIButton new];
    titleButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
    titleButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    BLKFlexibleHeightBarSubviewLayoutAttributes *titleExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    titleExpanded.frame = CGRectMake(kFlexNavBarButtonWidth - 40, kStatusBarHeight, VIEW_WIDTH-2*kFlexNavBarButtonWidth + 80, kBarHeight - kStatusBarHeight);
    [titleButton addLayoutAttributes:titleExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *titleCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:titleExpanded];
    titleCollapsed.alpha = 0;
    CGAffineTransform translation = CGAffineTransformMakeTranslation(0.0, -30.0);
    CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
    titleCollapsed.transform = CGAffineTransformConcat(scale, translation);

    [titleButton addLayoutAttributes:titleCollapsed forProgress:1.0];
    
    [bar addSubview:titleButton];
    bar.titleButton = titleButton;
    
    CGFloat buttonSize = kFlexNavBarButtonHeight;
    
    UIButton *leftButton = [UIButton new];
    leftButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, kFlexNavBarButtonWidth - kFlexNavBarButtonHeight + 20);
    leftButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    leftButton.tintColor = [UIColor whiteColor];
    leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    BLKFlexibleHeightBarSubviewLayoutAttributes *leftButtonExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    leftButtonExpanded.frame = CGRectMake(10, kStatusBarHeight, kFlexNavBarButtonWidth, buttonSize);
    [leftButton addLayoutAttributes:leftButtonExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *leftButtonCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:leftButtonExpanded];
    leftButtonCollapsed.alpha = 0;
    
    leftButtonCollapsed.transform = CGAffineTransformConcat(scale, translation);

    [leftButton addLayoutAttributes:leftButtonCollapsed forProgress:1.0];
    
    [bar addSubview:leftButton];
    bar.leftBarButton = leftButton;
    
    UIButton *rightButton = [UIButton new];
    rightButton.imageEdgeInsets = UIEdgeInsetsMake(10, kFlexNavBarButtonWidth - kFlexNavBarButtonHeight + 20, 10, 0);
    rightButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    rightButton.tintColor = [UIColor whiteColor];
    rightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *rightButtonExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    rightButtonExpanded.frame = CGRectMake(VIEW_WIDTH - kFlexNavBarButtonWidth - 10, kStatusBarHeight, kFlexNavBarButtonWidth, buttonSize);
    [rightButton addLayoutAttributes:rightButtonExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *rightButtonCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:rightButtonExpanded];
    rightButtonCollapsed.alpha = 0;
    
    rightButtonCollapsed.transform = CGAffineTransformConcat(scale, translation);
    
    [rightButton addLayoutAttributes:rightButtonCollapsed forProgress:1.0];
    
    [bar addSubview:rightButton];
    bar.rightBarButton = rightButton;
    
    bar.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
    return bar;
}

@end
