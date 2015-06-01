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
@property (strong, nonatomic) UIView *checkbox;
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
        self.groupTitleLabel.font = [UIFont fontWithName:BOLD_FONT size:32];
        self.groupTitleLabel.textColor = PRIMARY_COLOR;
        [self addSubview:self.groupTitleLabel];
        
        self.checkbox = [[UIView alloc] initWithFrame:CGRectMake(VIEW_WIDTH - checkboxWidth - padding, (XPCellHeight - checkboxWidth)/2, checkboxWidth, checkboxWidth)];
        self.checkbox.layer.masksToBounds = YES;
        self.checkbox.layer.cornerRadius = checkboxWidth/2;
        self.checkbox.layer.borderColor = PRIMARY_COLOR.CGColor;
        self.checkbox.layer.borderWidth = 5.0f;
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
        [self.checkbox setBackgroundColor:PRIMARY_COLOR];
    } else {
        [self.checkbox setBackgroundColor:[UIColor clearColor]];
    }
    // Configure the view for the selected state
}

- (void)setGroupTitle:(NSString *)title {
    self.groupTitleLabel.text = title;
}

@end
