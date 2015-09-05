//
//  YAProfileFlexibleHeightBar.h
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "BLKFlexibleHeightBar.h"

#define kTitleOriginCollapsed 16.0
#define kTitleOriginExpanded 26.0
#define kTitleMaxFont 34.0

@interface YAGroupFlexibleHeightBar : BLKFlexibleHeightBar

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *viewCountLabel;
@property (nonatomic, strong) UILabel *memberCountLabel;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *moreButton;

@property (nonatomic, strong) UILabel *descriptionLabel;

@property (nonatomic, strong) UILabel *membersTextLabel;

- (BOOL)showsDescriptionLabel;

@end
