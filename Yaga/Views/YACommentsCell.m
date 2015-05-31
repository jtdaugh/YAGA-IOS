//
//  YACommentsCell.m
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACommentsCell.h"

#define COMMENTS_FONT_SIZE 16.f

@interface YACommentsCell ()

@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UILabel *postEmojiLabel;

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
        self.usernameLabel.font = [UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE];
        
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
        self.commentsTextView.font = [UIFont systemFontOfSize:COMMENTS_FONT_SIZE];
        self.commentsTextView.backgroundColor = [UIColor clearColor];
        self.commentsTextView.scrollEnabled = NO;
        
        self.commentsTextView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.commentsTextView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        self.commentsTextView.layer.shadowOpacity = 1.0;
        self.commentsTextView.layer.shadowRadius = 0.0f;
        self.commentsTextView.editable = NO;
        
        [self addSubview:self.commentsTextView];
        
        self.postEmojiLabel = [[UILabel alloc] initWithFrame:CGRectMake(initialUsernameWidth, -2, 30, initialHeight)];
        self.postEmojiLabel.text = @"🎬";
        self.postEmojiLabel.font = [UIFont systemFontOfSize:COMMENTS_FONT_SIZE+6];
        [self.postEmojiLabel sizeToFit];
        [self addSubview:self.postEmojiLabel];
        
        self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, initialUsernameWidth, initialHeight)];
        self.timestampLabel.textColor = [UIColor colorWithWhite:0.85 alpha:0.75];
        self.timestampLabel.font = [UIFont systemFontOfSize:COMMENTS_FONT_SIZE-3.f];
        self.timestampLabel.shadowColor = [UIColor blackColor];
        self.timestampLabel.shadowOffset = CGSizeMake(0.5, 0.5);
        [self addSubview:self.timestampLabel];

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
    // set username, resize username label, and then resize all other labels around the username label
    self.usernameLabel.text = username;
    CGSize userSize = [self.usernameLabel sizeThatFits:CGSizeMake(VIEW_WIDTH/2, CGFLOAT_MAX)];
    CGRect userFrame = self.usernameLabel.frame;
    userFrame.size = userSize;
    self.usernameLabel.frame = userFrame;
    CGRect commentFrame = self.commentsTextView.frame;
    commentFrame.origin.x = userSize.width + 6.0f;
    commentFrame.size.width = VIEW_WIDTH - (commentFrame.origin.x);
//    commentFrame.origin.x = userWidth + 10;
//    commentFrame.size.width = self.frame.size.width - (userWidth + 10);
    self.commentsTextView.frame = commentFrame;
    
    CGRect postEmojiFrame = self.postEmojiLabel.frame;
    postEmojiFrame.origin.x = userSize.width + 6.f;
    self.postEmojiLabel.frame = postEmojiFrame;
    
    CGRect timestampFrame = self.timestampLabel.frame;
    timestampFrame.origin.x = postEmojiFrame.origin.x + postEmojiFrame.size.width + 6.f;
    timestampFrame.size.width = VIEW_WIDTH - timestampFrame.origin.x;
    self.timestampLabel.frame = timestampFrame;
}

- (void)setTimestamp:(NSString *)timestamp {
    self.timestampLabel.text = timestamp;
}

- (void)setCellType:(YACommentsCellType)cellType {
    switch (cellType) {
        case YACommentsCellTypeComment:
            self.commentsTextView.hidden = NO;
            self.postEmojiLabel.hidden = YES;
            self.timestampLabel.hidden = YES;
            break;
        case YACommentsCellTypePost:
            self.commentsTextView.hidden = YES;
            self.postEmojiLabel.hidden = NO;
            self.timestampLabel.hidden = NO;
            break;
    }
}

+ (CGFloat)heightForCommentCellWithUsername:(NSString *)username comment:(NSString *)comment {
    // should actually implement this
    UILabel *dummy = [[UILabel alloc] init];
    dummy.text = username;
    dummy.font = [UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE];
    CGSize userSize = [dummy sizeThatFits:CGSizeMake(VIEW_WIDTH/2, CGFLOAT_MAX)];
    
    UITextView *dummyTextView = [[UITextView alloc] init];
    dummyTextView.font = [UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE];
    dummyTextView.textContainer.lineFragmentPadding = 0;
    dummyTextView.textContainerInset = UIEdgeInsetsZero;
    dummyTextView.text = comment;
    CGFloat commentWidth = VIEW_WIDTH - (userSize.width + 6.0f);

    CGSize commentSize = [dummyTextView sizeThatFits:CGSizeMake(commentWidth, CGFLOAT_MAX)];
    
    return commentSize.height + 6.0f;
}

+ (CGFloat)heightForPostCellWithUsername:(NSString *)username timestamp:(NSString *)timestamp {
    return 24.f;
}

@end
