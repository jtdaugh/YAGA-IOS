//
//  YAProfileFlexibleHeightBar.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//


#import "YAPublicGroupFlexibleHeightBar.h"
#import "SquareCashStyleBehaviorDefiner.h"

@implementation YAPublicGroupFlexibleHeightBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = PUBLIC_GROUP_COLOR;
        [self.moreButton removeFromSuperview];
        self.moreButton = nil;
        
        [self addFollowButton];
        
    }
    return self;
}

- (BOOL)showsDescriptionLabel {
    return YES;
}


- (void)addFollowButton {
    UIButton *button = [UIButton new];
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.layer.borderWidth = 2;
    button.layer.cornerRadius = 10;
    button.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    button.titleLabel.textColor = [UIColor whiteColor];
    
    CGRect frame =  CGRectMake((VIEW_WIDTH - 250)/2, kTitleOriginExpanded + 135, 250, 30);
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = frame;
    [button addLayoutAttributes:expanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:expanded];
    collapsed.alpha = 0;
    collapsed.transform = CGAffineTransformMakeTranslation(0, -130);
    [button addLayoutAttributes:collapsed forProgress:1.0];
    
    [self addSubview:button];
    self.followButton = button;
}


@end
