//
//  YAProfileFlexibleHeightBar.h
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "BLKFlexibleHeightBar.h"

@interface YAProfileFlexibleHeightBar : BLKFlexibleHeightBar

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *viewsLabel;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

+ (YAProfileFlexibleHeightBar *)emptyProfileBar;

@end
