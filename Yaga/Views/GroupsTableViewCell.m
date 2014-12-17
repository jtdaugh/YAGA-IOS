//
//  GroupListCell.m
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupsTableViewCell.h"

@interface GroupsTableViewCell ()
@property(nonatomic, strong) UIButton *editButton;
@end

@implementation GroupsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        CGFloat subtitleHeight = 18;
        CGFloat between_margin = 4;
        CGFloat margin = 44;
        CGFloat height = 44;

        CGRect frame = self.frame;
        frame.size.width = VIEW_WIDTH;
        frame.size.height = 54;
        
        self.textLabel.frame = CGRectMake(margin, 0, self.frame.size.width-margin*2-height, self.frame.size.height - subtitleHeight - between_margin);
        [self.textLabel setClipsToBounds:NO];
        [self.textLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
        self.textLabel.textColor = PRIMARY_COLOR;
        
        self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.size.height + between_margin, self.textLabel.frame.size.width, subtitleHeight);
        
        [self.detailTextLabel setFont:[UIFont fontWithName:BIG_FONT size:14]];
        self.detailTextLabel.numberOfLines = 0;
        [self.detailTextLabel setTextColor:PRIMARY_COLOR];
        [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
        
        [self setBackgroundColor:[UIColor clearColor]];
        
        self.editButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - margin - height, (self.frame.size.height - height)/2, height, height)];
        [self.editButton setBackgroundImage:[UIImage imageNamed:@"Settings"] forState:UIControlStateNormal];
        [self addSubview:self.editButton];
        [self.editButton addTarget:self action:@selector(showGroupOptions:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.detailTextLabel sizeToFit];
    self.editButton.hidden = !self.showEditButton;
}

- (void)showGroupOptions:(id)sender {
    if(self.editBlock)
        self.editBlock();
}

@end
