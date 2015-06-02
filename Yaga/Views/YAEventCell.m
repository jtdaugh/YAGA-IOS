//
//  YACommentsCell.m
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAEventCell.h"

#import "YAUser.h"

#define COMMENTS_FONT_SIZE 16.f


@interface YAEventCell ()

@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) UITextView *commentsTextView;

@end

@implementation YAEventCell


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
        self.usernameLabel.userInteractionEnabled = NO;

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
        self.commentsTextView.userInteractionEnabled = NO;
        self.commentsTextView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.commentsTextView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        self.commentsTextView.layer.shadowOpacity = 1.0;
        self.commentsTextView.layer.shadowRadius = 0.0f;
        self.commentsTextView.editable = NO;
        
        [self addSubview:self.commentsTextView];
        
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(initialUsernameWidth, -3, 30, initialHeight)];
        self.iconImageView.image = [UIImage imageNamed:@"rainHeart"];
        self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.iconImageView];
        
        self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 3, initialUsernameWidth, initialHeight)];
        self.timestampLabel.textColor = [UIColor colorWithWhite:0.85 alpha:0.75];
        self.timestampLabel.font = [UIFont systemFontOfSize:COMMENTS_FONT_SIZE-3.f];
        self.timestampLabel.userInteractionEnabled = NO;

        self.timestampLabel.shadowColor = [UIColor blackColor];
        self.timestampLabel.shadowOffset = CGSizeMake(0.5, 0.5);
        [self addSubview:self.timestampLabel];
        
        self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, initialHeight)];
        self.deleteButton.backgroundColor = [UIColor clearColor];
//        self.deleteButton.layer.cornerRadius = 10.f;
//        self.deleteButton.layer.borderColor = [[UIColor redColor] CGColor];
//        self.deleteButton.layer.borderWidth = 2.f;
        [self.deleteButton.titleLabel setFont:[UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE - 3.0f]];
        [self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
        [self.deleteButton addTarget:self action:@selector(deletePressed) forControlEvents:UIControlEventTouchUpInside];
        [self.deleteButton setTitleColor:[UIColor colorWithRed:158.0f/255.0f green:11.0f/255.0f blue:15.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
        self.deleteButton.layer.shadowColor = [UIColor blackColor].CGColor;
        self.deleteButton.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        self.deleteButton.layer.shadowOpacity = 0.5;
        self.deleteButton.layer.shadowRadius = 0.0f;
        [self.deleteButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];

        [self addSubview:self.deleteButton];

//        [self.usernameLabel setBackgroundColor:[UIColor greenColor]];
//        [self.commentsTextView setBackgroundColor:[UIColor redColor]];
    }
    return self;    
}

- (void)configureCellWithEvent:(YAEvent *)event {
    switch (event.eventType) {
        case YAEventTypeComment:
            [self configureCommentCellWithUsername:event.username comment:event.comment];
            break;
        case YAEventTypeLike:
            [self configureLikeCellWithUsername:event.username];
            break;
        case YAEventTypePost:
            [self configurePostCellWithUsername:event.username
                                      timestamp:event.timestamp
                                     isOwnVideo:[event.username isEqualToString:[YAUser currentUser].username]];
            break;
    }
}

- (void)configureCommentCellWithUsername:(NSString *)username comment:(NSString *)comment {
    [self setCellType:YAEventTypeComment];
    self.usernameLabel.text = username;
    [self layoutUsername];
    self.commentsTextView.text = comment;
    CGRect commentFrame = self.commentsTextView.frame;
    commentFrame.origin.x = self.usernameLabel.frame.size.width + 6.0f;
    CGSize commentsSize = [self.commentsTextView sizeThatFits:CGSizeMake(self.frame.size.width - (commentFrame.origin.x), CGFLOAT_MAX)];
    commentFrame.size = commentsSize;
    self.commentsTextView.frame = commentFrame;
}

- (void)configureLikeCellWithUsername:(NSString *)username {
    [self setCellType:YAEventTypeLike];
    self.usernameLabel.text = username;
    [self layoutUsername];
    self.iconImageView.image = [UIImage imageNamed:@"rainHeart"];
    [self layoutImageViewWithYOffset:-2.f];
    
}

- (void)configurePostCellWithUsername:(NSString *)username timestamp:(NSString *)timestamp isOwnVideo:(BOOL)isOwnVideo {
    [self setCellType:YAEventTypePost];
    self.usernameLabel.text = username;
    [self layoutUsername];
    self.timestampLabel.text = timestamp;
    self.deleteButton.hidden = !isOwnVideo;
    self.iconImageView.image = [UIImage imageNamed:@"Movie"];
    [self layoutImageViewWithYOffset:-4.f];
    [self layoutPostViews];
}

- (void)layoutUsername {
    CGSize userSize = [self.usernameLabel sizeThatFits:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
    CGRect userFrame = self.usernameLabel.frame;
    userFrame.size = userSize;
    self.usernameLabel.frame = userFrame;
}

- (void)layoutImageViewWithYOffset:(CGFloat)yOffset {
    CGRect imageFrame = self.iconImageView.frame;
    imageFrame.origin.x = self.usernameLabel.frame.size.width + 6.f;
    imageFrame.origin.y = yOffset;
    self.iconImageView.frame = imageFrame;
}

- (void)layoutPostViews {
    CGFloat deleteWidth = self.deleteButton.frame.size.width;

    CGRect timestampFrame = self.timestampLabel.frame;
    timestampFrame.origin.x = self.iconImageView.frame.origin.x + self.iconImageView.frame.size.width + 6.f;
    timestampFrame.size.width = self.frame.size.width - timestampFrame.origin.x - deleteWidth;
    self.timestampLabel.frame = timestampFrame;
    [self.timestampLabel sizeToFit];
    
    CGRect deleteFrame = self.deleteButton.frame;
    deleteFrame.origin.x = self.timestampLabel.frame.origin.x + self.timestampLabel.frame.size.width + 6.f;
    deleteFrame.size.width = deleteWidth;
    self.deleteButton.frame = deleteFrame;
}

- (void)setCellType:(YAEventType)cellType {
    switch (cellType) {
        case YAEventTypeComment:
            self.commentsTextView.hidden = NO;
            self.iconImageView.hidden = YES;
            self.timestampLabel.hidden = YES;
            self.deleteButton.hidden = YES;
            break;
        case YAEventTypePost:
            self.commentsTextView.hidden = YES;
            self.iconImageView.hidden = NO;
            self.timestampLabel.hidden = NO;
            self.deleteButton.hidden = NO;
            break;
        case YAEventTypeLike:
            self.iconImageView.hidden = NO;
            self.commentsTextView.hidden = YES;
            self.timestampLabel.hidden = YES;
            self.deleteButton.hidden = YES;
            break;
    }
}


- (void)deletePressed {
    [YAUtils deleteVideo:self.containingVideoPage.video];
}

#pragma mark - Class methods

+ (CGFloat)heightForCellWithEvent:(YAEvent *)event {
    switch (event.eventType) {
        case YAEventTypeComment:
            return [YAEventCell heightForCommentCellWithUsername:event.username comment:event.comment];
            break;
        case YAEventTypeLike:
            return [YAEventCell heightForLikeCell];
            break;
        case YAEventTypePost:
            return [YAEventCell heightForPostCell];
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
    
    return commentSize.height + 8.0f;
}

+ (CGFloat)heightForPostCell {
    return 26.f;
}

+ (CGFloat)heightForLikeCell {
    return 26.f;
}

@end
