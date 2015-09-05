//
//  YAProfileFlexibleHeightBar.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAPrivateGroupFlexibleHeightBar.h"
#import "SquareCashStyleBehaviorDefiner.h"

@implementation YAPrivateGroupFlexibleHeightBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = PRIVATE_GROUP_COLOR;
        self.membersTextLabel.text = @"members";
    }
    return self;
}

- (BOOL)showsDescriptionLabel {
    return NO;
}

@end
