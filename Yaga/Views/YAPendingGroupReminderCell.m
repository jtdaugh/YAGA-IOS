//
//  YAPendingGroupReminderCell.m
//  Yaga
//
//  Created by Jesse on 8/18/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAPendingGroupReminderCell.h"

#define ACCESSORY_SIZE 26
#define LEFT_MARGIN 10
#define RIGHT_MARGIN 10

@interface YAPendingGroupReminderCell ()

@property(nonatomic, strong) UIImageView *disclosureImageView;

@end

@implementation YAPendingGroupReminderCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = HOSTING_GROUP_COLOR;
        self.separatorView = [[UIView alloc] initWithFrame:CGRectMake(LEFT_MARGIN, kReminderCellHeight - 1, frame.size.width - LEFT_MARGIN, 1)];
        self.separatorView.backgroundColor = [UIColor whiteColor];
        self.boldSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0, kReminderCellHeight - 2, frame.size.width, 2)];
        self.boldSeparatorView.backgroundColor = [UIColor whiteColor];

        self.disclosureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width - RIGHT_MARGIN - ACCESSORY_SIZE, (kReminderCellHeight - ACCESSORY_SIZE)/2, ACCESSORY_SIZE, ACCESSORY_SIZE)];
        [self.disclosureImageView setImage:[[UIImage imageNamed:@"Disclosure"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.disclosureImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.disclosureImageView.tintColor = [UIColor whiteColor];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_MARGIN, 0, frame.size.width - LEFT_MARGIN - RIGHT_MARGIN - ACCESSORY_SIZE - 10, kReminderCellHeight)];
        self.textLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        
        [self.contentView addSubview:self.separatorView];
        [self.contentView addSubview:self.boldSeparatorView];
        [self.contentView addSubview:self.disclosureImageView];
        [self.contentView addSubview:self.textLabel];
    }
    return self;
}

@end
