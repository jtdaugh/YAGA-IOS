//
//  GroupListCell.m
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupListCell.h"

@implementation GroupListCell

- (void)awakeFromNib {
    // Initialization code
    NSLog(@"awake? cell");
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        CGFloat subtitleHeight = 18;
        CGFloat between_margin = 4;
        CGFloat margin = 44;
        CGFloat height = 44;

        CGRect frame = self.frame;
        frame.size.width = VIEW_WIDTH;
        frame.size.height = 54;
        self.frame = frame;
        
        self.title = [[UILabel alloc] initWithFrame:CGRectMake(margin, 0, self.frame.size.width-margin*2-height, self.frame.size.height - subtitleHeight - between_margin)];
        
        [self.title setClipsToBounds:NO];
        [self.title setFont:[UIFont fontWithName:BIG_FONT size:28]];
        
        //    [label setFont:[UIFont systemFontOfSize:28]];
        self.title.textColor = PRIMARY_COLOR;
        [self addSubview:self.title];
        
        self.subtitle = [[UILabel alloc] initWithFrame:CGRectMake(self.title.frame.origin.x, self.title.frame.size.height + between_margin, self.title.frame.size.width, subtitleHeight)];
        
        [self.subtitle setFont:[UIFont fontWithName:BIG_FONT size:14]];
        [self.subtitle setTextColor:PRIMARY_COLOR];
        [self.subtitle setBackgroundColor:[UIColor clearColor]];
        [self addSubview:self.subtitle];
        
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        [self setBackgroundColor:[UIColor clearColor]];
        
        
        self.icon = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - margin - height, (self.frame.size.height - height)/2, height, height)];
        [self.icon setBackgroundImage:[UIImage imageNamed:@"Settings"] forState:UIControlStateNormal];
        [self addSubview:self.icon];

    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
