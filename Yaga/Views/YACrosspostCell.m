//
//  YACrosspostCell.m
//  Yaga
//
//  Created by Raj Vir on 5/31/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACrosspostCell.h"
@interface YACrosspostCell ()
@property (strong, nonatomic) UILabel *groupTitleLabel;
@property (strong, nonatomic) UIImageView *checkbox;
@end

@implementation YACrosspostCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        [self setBackgroundColor:[UIColor clearColor]];
        
        CGFloat checkboxWidth = 36;
        CGFloat padding = 24;
        
        self.groupTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding,0,VIEW_WIDTH - padding - checkboxWidth - padding, XPCellHeight)];
        self.groupTitleLabel.font = [UIFont fontWithName:BIG_FONT size:28];
        self.groupTitleLabel.textColor = [UIColor whiteColor];
        
        self.groupTitleLabel.shadowColor = [UIColor blackColor];
        self.groupTitleLabel.shadowOffset = CGSizeMake(0.5, 0.5);
//        self.groupTitleLabel.layer.shadowRadius = 0.5;
//        self.groupTitleLabel.layer.masksToBounds = YES;
        
        
        [self addSubview:self.groupTitleLabel];
        
        self.checkbox = [[UIImageView alloc] initWithFrame:CGRectMake(VIEW_WIDTH - checkboxWidth - padding, (XPCellHeight - checkboxWidth)/2, checkboxWidth, checkboxWidth)];
        self.checkbox.layer.masksToBounds = YES;
        self.checkbox.layer.cornerRadius = 2;
        self.checkbox.layer.borderColor = [UIColor whiteColor].CGColor;
        self.checkbox.layer.borderWidth = 2.0f;
        
        [self addSubview:self.checkbox];
        //        [self.usernameLabel setBackgroundColor:[UIColor greenColor]];
        //        [self.commentsTextView setBackgroundColor:[UIColor redColor]];
        self.selectedBackgroundView = [UIView new];
    }
    return self;    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if(selected){
        [self.checkbox setImage:[UIImage imageNamed:@"Check"]];
        [self.groupTitleLabel setTextColor:PRIMARY_COLOR];
//        [self.checkbox setBackgroundColor:PRIMARY_COLOR];
    } else {
        [self.checkbox setImage:[UIImage new]];
        [self.groupTitleLabel setTextColor:[UIColor whiteColor]];
    }
    // Configure the view for the selected state
}

- (void)setGroupTitle:(NSString *)title {
    self.groupTitleLabel.text = title;
}

@end
