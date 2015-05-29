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


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat initialUsernameWidth = 100, initialHeight = 20;
        self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, initialUsernameWidth, initialHeight)];
        self.usernameLabel.textColor = PRIMARY_COLOR;
        self.usernameLabel.font = [UIFont boldSystemFontOfSize:12.f];
        [self addSubview:self.usernameLabel];
        self.commentsTextView = [[UITextView alloc] initWithFrame:CGRectMake(initialUsernameWidth, 0, frame.size.width - initialUsernameWidth, initialHeight)];
        self.commentsTextView.textColor = [UIColor whiteColor];
        self.commentsTextView.font = [UIFont systemFontOfSize:12.f];
    }
    return self;
}

- (void)setComment:(NSString *)comment {
    self.commentsTextView.text = comment;
}

- (void)setUsername:(NSString *)username {
    self.usernameLabel.text = username;
}

+ (CGFloat)heightForCellWithUsername:(NSString *)username comment:(NSString *)comment {
    // should actually implement this
    return 30;
}

@end
