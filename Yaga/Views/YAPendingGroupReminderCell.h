//
//  YAPendingGroupReminderCell.h
//  Yaga
//
//  Created by Jesse on 8/18/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kReminderCellHeight 60

@interface YAPendingGroupReminderCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *textLabel;
@property(nonatomic, strong) UIView *separatorView;
@property(nonatomic, strong) UIView *boldSeparatorView;

@end
