//
//  YAStandardFlexibleHeightBar.h
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "BLKFlexibleHeightBar.h"

@interface YAStandardFlexibleHeightBar : BLKFlexibleHeightBar

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *leftBarButton;
@property (nonatomic, strong) UIButton *rightBarButton;

+ (YAStandardFlexibleHeightBar *)emptyStandardFlexibleBar;

@end
