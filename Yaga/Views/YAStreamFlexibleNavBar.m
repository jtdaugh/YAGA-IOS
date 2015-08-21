//
//  YAStreamFlexibleNavBar.m
//  Yaga
//
//  Created by Jesse on 8/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#define kHeaderHeight 56
#define kStatusBarHeight 20

#import "YAStreamFlexibleNavBar.h"
#import "SquareCashStyleBehaviorDefiner.h"

@implementation YAStreamFlexibleNavBar

+ (YAStreamFlexibleNavBar *)emptyStreamNavBar {
    YAStreamFlexibleNavBar *bar = [[YAStreamFlexibleNavBar alloc] initWithFrame:CGRectMake(0.0, 0.0, VIEW_WIDTH, kHeaderHeight)];
    bar.minimumBarHeight = 20;
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    BLKFlexibleHeightBarSubviewLayoutAttributes *titleExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    titleExpanded.frame = CGRectMake(40, kStatusBarHeight, VIEW_WIDTH-80, kHeaderHeight - kStatusBarHeight);
    [titleLabel addLayoutAttributes:titleExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *titleCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:titleExpanded];
    titleCollapsed.alpha = 0;
    CGAffineTransform translation = CGAffineTransformMakeTranslation(0.0, -30.0);
    CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
    titleCollapsed.transform = CGAffineTransformConcat(scale, translation);
    
    [titleLabel addLayoutAttributes:titleCollapsed forProgress:1.0];
    
    [bar addSubview:titleLabel];
    bar.titleLabel = titleLabel;
    
    bar.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
    return bar;
}


@end
