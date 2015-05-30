//
//  YACommentsCell.m
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACommentsCell.h"

@interface YACommentsCell ()


@end

@implementation YACommentsCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        CGFloat initialUsernameWidth = 100, initialHeight = 24;
        self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, initialUsernameWidth, initialHeight)];
        self.usernameLabel.textColor = PRIMARY_COLOR;
        self.usernameLabel.font = [UIFont boldSystemFontOfSize:18.f];
        
        self.usernameLabel.shadowColor = [UIColor blackColor];
        self.usernameLabel.shadowOffset = CGSizeMake(0.5, 0.5);
        
//        
//        self.commentsTextView.layer.shadowColor = [UIColor blackColor].CGColor;
//        self.commentsTextView.layer.shadowOffset = CGSizeMake(1.0, 1.0);
//        self.commentsTextView.layer.shadowOpacity = 1.0;
//        self.commentsTextView.layer.shadowRadius = 0.0f;
        
        [self addSubview:self.usernameLabel];

        self.commentsTextView = [[UITextView alloc] initWithFrame:CGRectMake(initialUsernameWidth, 0, self.frame.size.width - initialUsernameWidth, initialHeight)];
        self.commentsTextView.textContainer.lineFragmentPadding = 0;
        self.commentsTextView.textContainerInset = UIEdgeInsetsZero;
        self.commentsTextView.textColor = [UIColor whiteColor];
        self.commentsTextView.textContainerInset = UIEdgeInsetsZero;
        self.commentsTextView.font = [UIFont systemFontOfSize:18.f];
        self.commentsTextView.backgroundColor = [UIColor clearColor];
        self.commentsTextView.scrollEnabled = NO;
        
        self.commentsTextView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.commentsTextView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        self.commentsTextView.layer.shadowOpacity = 1.0;
        self.commentsTextView.layer.shadowRadius = 0.0f;
        
        [self addSubview:self.commentsTextView];
        
//        [self.usernameLabel setBackgroundColor:[UIColor greenColor]];
//        [self.commentsTextView setBackgroundColor:[UIColor redColor]];
    }
    return self;    
}

- (void)setComment:(NSString *)comment {
    self.commentsTextView.text = comment;
    [self.commentsTextView sizeToFit];
}

- (void)setUsername:(NSString *)username {
    self.usernameLabel.text = username;
    CGSize userSize = [self.usernameLabel sizeThatFits:CGSizeMake(VIEW_WIDTH/2, CGFLOAT_MAX)];
    CGRect userFrame = self.usernameLabel.frame;
    userFrame.size = userSize;
    self.usernameLabel.frame = userFrame;
    CGRect commentFrame = self.commentsTextView.frame;
    commentFrame.origin.x = userSize.width + 6.0f;
    commentFrame.size.width = VIEW_WIDTH - (userSize.width + 6.0f);
//    commentFrame.origin.x = userWidth + 10;
//    commentFrame.size.width = self.frame.size.width - (userWidth + 10);
    self.commentsTextView.frame = commentFrame;
}

+ (CGFloat)heightForCellWithUsername:(NSString *)username comment:(NSString *)comment {
    // should actually implement this
    UILabel *dummy = [[UILabel alloc] init];
    dummy.text = username;
    dummy.font = [UIFont boldSystemFontOfSize:18.f];
    CGSize userSize = [dummy sizeThatFits:CGSizeMake(VIEW_WIDTH/2, CGFLOAT_MAX)];
    
    UITextView *dummyTextView = [[UITextView alloc] init];
    dummyTextView.font = [UIFont boldSystemFontOfSize:18.f];
    dummyTextView.textContainer.lineFragmentPadding = 0;
    dummyTextView.textContainerInset = UIEdgeInsetsZero;
    dummyTextView.text = comment;
    CGFloat commentWidth = VIEW_WIDTH - (userSize.width + 6.0f);

    CGSize commentSize = [dummyTextView sizeThatFits:CGSizeMake(commentWidth, CGFLOAT_MAX)];
    
    NSLog(@"height: %f", commentSize.height);
    return commentSize.height + 6.0f;
}

@end
