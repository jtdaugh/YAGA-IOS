//
//  ListTileCell.m
//  Pic6
//
//  Created by Raj Vir on 8/19/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "ListTileCell.h"

@implementation ListTileCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [self addSubview:self.titleContainer];
        
        UILabel *groupTitle = [[UILabel alloc] init];
        groupTitle.translatesAutoresizingMaskIntoConstraints = NO;
        groupTitle.textColor = [UIColor whiteColor];
        groupTitle.textAlignment = NSTextAlignmentCenter;

        [self.titleContainer addSubview:groupTitle];
        self.groupTitle = groupTitle;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(groupTitle);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[groupTitle]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[groupTitle(36)]|" options:0 metrics:nil views:views]];
        
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
