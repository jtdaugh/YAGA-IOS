//
//  YAStreamFlexibleNavBar.h
//  Yaga
//
//  Created by Jesse on 8/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "BLKFlexibleHeightBar.h"

@interface YAStreamFlexibleNavBar : BLKFlexibleHeightBar

@property (nonatomic, strong) UILabel *titleLabel;
+ (YAStreamFlexibleNavBar *)emptyStreamNavBar;

@end
