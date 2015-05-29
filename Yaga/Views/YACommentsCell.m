//
//  YACommentsCell.m
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACommentsCell.h"

@interface YACommentsCell ()

@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UITextView *commentsTextView;

@end

@implementation YACommentsCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        CGFloat initialUsernameWidth = 100, initialHeight = 24;
        self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, initialUsernameWidth, initialHeight)];
        self.usernameLabel.textColor = PRIMARY_COLOR;
        self.usernameLabel.font = [UIFont boldSystemFontOfSize:14.f];
        [self addSubview:self.usernameLabel];
        self.commentsTextView = [[UITextView alloc] initWithFrame:CGRectMake(initialUsernameWidth, 0, self.frame.size.width - initialUsernameWidth, initialHeight)];
        self.commentsTextView.textColor = [UIColor whiteColor];
        self.commentsTextView.font = [UIFont systemFontOfSize:14.f];
        self.commentsTextView.backgroundColor = [UIColor clearColor];
        self.commentsTextView.scrollEnabled = NO;
        [self addSubview:self.commentsTextView];
    }
    return self;    
}

- (void)setComment:(NSString *)comment {
    self.commentsTextView.text = comment;
}

- (void)setUsername:(NSString *)username {
    self.usernameLabel.text = username;
    CGFloat userWidth = [self.usernameLabel sizeThatFits:CGSizeMake(VIEW_WIDTH/2, CGFLOAT_MAX)].width;
    CGRect userFrame = self.usernameLabel.frame;
    userFrame.size.width = userWidth;
    self.usernameLabel.frame = userFrame;
    CGRect commentFrame = self.commentsTextView.frame;
    commentFrame.origin.x = userWidth + 12;
    commentFrame.size.width = self.frame.size.width - (userWidth + 12);
    self.commentsTextView.frame = commentFrame;
}

+ (CGFloat)heightForCellWithUsername:(NSString *)username comment:(NSString *)comment {
    // should actually implement this
    return 30;
}

@end
