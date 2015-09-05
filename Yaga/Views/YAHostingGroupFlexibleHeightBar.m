//
//  YAHostingGroupFlexibleHeightBar.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAHostingGroupFlexibleHeightBar.h"
#import "SquareCashStyleBehaviorDefiner.h"

@implementation YAHostingGroupFlexibleHeightBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = HOSTING_GROUP_COLOR;

        [self addSegmentCtrl];
    }
    return self;
}

- (BOOL)showsDescriptionLabel {
    return YES;
}

- (void)addSegmentCtrl {
    UISegmentedControl *seg = [UISegmentedControl new];
    seg.tintColor = [UIColor whiteColor];
    [seg insertSegmentWithTitle:@"Approved" atIndex:0 animated:NO];
    [seg insertSegmentWithTitle:@"Pending" atIndex:1 animated:NO];
    seg.selectedSegmentIndex = 0;
    
    CGRect frame =  CGRectMake((VIEW_WIDTH - 250)/2, kTitleOriginExpanded + 135, 250, 30);
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = frame;
    [seg addLayoutAttributes:expanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:expanded];
    collapsed.alpha = 0;
    collapsed.transform = CGAffineTransformMakeTranslation(0, -130);
    [seg addLayoutAttributes:collapsed forProgress:1.0];
    
    [self addSubview:seg];
    self.segmentedControl = seg;
}


@end
