//
//  YACommentsCell.m
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAEventCell.h"

#import "YAUser.h"

#define USERNAME_HEIGHT 26
#define MAX_USERNAME_WIDTH (VIEW_WIDTH*0.5)
@interface YAEventCell ()

@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UITextView *commentsTextView;
@property (nonatomic, strong) UILabel *likeCountLabel;

@property (nonatomic, strong) NSString *timestamp;

@end

@implementation YAEventCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        CGFloat initialUsernameWidth = 100, initialHeight = USERNAME_HEIGHT;
        self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, initialUsernameWidth, initialHeight)];
        self.usernameLabel.textColor = PRIMARY_COLOR;
        self.usernameLabel.font = [UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE];
        self.usernameLabel.shadowColor = [UIColor blackColor];
        self.usernameLabel.shadowOffset = CGSizeMake(0.5, 0.5);
        self.usernameLabel.userInteractionEnabled = NO;
        self.usernameLabel.adjustsFontSizeToFitWidth = YES;
        self.usernameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.usernameLabel.minimumScaleFactor = 0.5;
        
        self.likeCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(initialUsernameWidth + 11, 0, self.frame.size.width - (initialUsernameWidth + 30), initialHeight)];
        self.likeCountLabel.textColor = [UIColor whiteColor];
        self.likeCountLabel.font = [UIFont boldSystemFontOfSize:LIKE_COUNT_SIZE];
        self.likeCountLabel.shadowColor = [UIColor blackColor];
        self.likeCountLabel.shadowOffset = CGSizeMake(0.5, 0.5);
        self.likeCountLabel.userInteractionEnabled = NO;


//        self.commentsTextView.layer.shadowColor = [UIColor blackColor].CGColor;
//        self.commentsTextView.layer.shadowOffset = CGSizeMake(1.0, 1.0);
//        self.commentsTextView.layer.shadowOpacity = 1.0;
//        self.commentsTextView.layer.shadowRadius = 0.0f;
        
        [self addSubview:self.usernameLabel];
        [self addSubview:self.likeCountLabel];

        self.commentsTextView = [[UITextView alloc] initWithFrame:CGRectMake(initialUsernameWidth, 3, self.frame.size.width - initialUsernameWidth, initialHeight-3)];
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
        
        self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, initialUsernameWidth, initialHeight)];
        self.timestampLabel.textColor = [UIColor colorWithWhite:0.85 alpha:0.75];
        self.timestampLabel.font = [UIFont systemFontOfSize:COMMENTS_FONT_SIZE-3.f];
        self.timestampLabel.userInteractionEnabled = NO;

        self.timestampLabel.shadowColor = [UIColor blackColor];
        self.timestampLabel.shadowOffset = CGSizeMake(0.5, 0.5);
        [self addSubview:self.timestampLabel];


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
            [self configureLikeCellWithUsername:event.username likeCount:event.likeCount ? event.likeCount.integerValue : 0];
            break;
        case YAEventTypePost:
            [self configurePostCellWithUsername:event.username
                                      timestamp:event.timestamp
                                     isOwnVideo:[[[event.username componentsSeparatedByString:@" "] firstObject] isEqualToString:[YAUser currentUser].username]];
            break;
    }
}

- (void)configureCommentCellWithUsername:(NSString *)username comment:(NSString *)comment {
    [self setCellType:YAEventTypeComment];
    self.usernameLabel.text = username;
    [self layoutUsername:username];
    self.commentsTextView.text = comment;
    CGRect commentFrame = self.commentsTextView.frame;
    commentFrame.origin.x = self.usernameLabel.frame.size.width + 8.0f;
    commentFrame.size = [[self class] sizeForCommentsCellWithUsername:username comment:comment];
    self.likeCountLabel.text = @"";
    self.commentsTextView.frame = commentFrame;
}

- (void)configureLikeCellWithUsername:(NSString *)username likeCount:(NSInteger)likeCount {
    [self setCellType:YAEventTypeLike];
    self.usernameLabel.text = username;
    [self layoutUsername:username];
    self.iconImageView.image = [UIImage imageNamed:@"Liked"];
    [self layoutImageViewWithYOffset:0];
    [self layoutLikeCountLabelWithYOffset:0];
    if (likeCount > 1) {
        self.likeCountLabel.text = [NSString stringWithFormat:@"✕ %ld", likeCount];
    } else {
        self.likeCountLabel.text = @"";
    }
}

- (void)configurePostCellWithUsername:(NSString *)username timestamp:(NSString *)timestamp isOwnVideo:(BOOL)isOwnVideo {
    self.timestamp = timestamp;
    
    [self setCellType:YAEventTypePost];
    self.usernameLabel.text = username;
    [self layoutUsername:username];
    self.timestampLabel.text = timestamp;
    self.commentsTextView.text = @"";
    self.likeCountLabel.text = @"";
    [self layoutPostViews];
}

- (void)layoutUsername:(NSString *)username {
    CGFloat width = [[self class] frameForUsernameLabel:username].size.width;
    CGRect frame = self.usernameLabel.frame;
    frame.size.width = width > MAX_USERNAME_WIDTH ? MAX_USERNAME_WIDTH : width;
    self.usernameLabel.frame = frame;
}

- (void)layoutImageViewWithYOffset:(CGFloat)yOffset {
    CGRect imageFrame = self.iconImageView.frame;
    imageFrame.origin.x = self.usernameLabel.frame.size.width + 4.f;
    imageFrame.origin.y = yOffset;
    self.iconImageView.frame = imageFrame;
}

- (void)layoutLikeCountLabelWithYOffset:(CGFloat)yOffset {
    CGRect likeCountLabelFrame = self.likeCountLabel.frame;
    likeCountLabelFrame.origin.x = CGRectGetMaxX(self.iconImageView.frame);
    likeCountLabelFrame.origin.y = yOffset;
    self.likeCountLabel.frame = likeCountLabelFrame;
}

- (void)layoutPostViews {

    CGRect timestampFrame = self.timestampLabel.frame;
    timestampFrame.origin.x = self.usernameLabel.frame.origin.x + self.usernameLabel.frame.size.width + COMMENTS_SPACE_AFTER_USERNAME;
    timestampFrame.size.width = self.frame.size.width - timestampFrame.origin.x - 5;
    self.timestampLabel.frame = timestampFrame;
    [self.timestampLabel sizeToFit];
    timestampFrame = self.timestampLabel.frame;
    timestampFrame.origin.y = (USERNAME_HEIGHT - timestampFrame.size.height)/2;
    self.timestampLabel.frame = timestampFrame;
    
}

- (void)setVideoState:(YAEventCellVideoState)state{
    switch (state) {
        case YAEventCellVideoStateUploading:
            self.timestampLabel.text = @"Uploading...";
            break;
        case YAEventCellVideoStateUnapproved:
            self.timestampLabel.text = @"Pending";
            break;
        case YAEventCellVideoStateApproved:
            self.timestampLabel.text = [NSString stringWithFormat:@"%@", self.timestamp];
            break;
    }
    [self layoutPostViews];
}

- (void)setCellType:(YAEventType)cellType {
    switch (cellType) {
        case YAEventTypeComment:
            self.commentsTextView.hidden = NO;
            self.iconImageView.hidden = YES;
            self.timestampLabel.hidden = YES;
            break;
        case YAEventTypePost:
            self.commentsTextView.hidden = YES;
            self.iconImageView.hidden = YES;
            self.timestampLabel.hidden = NO;
            break;
        case YAEventTypeLike:
            self.iconImageView.hidden = NO;
            self.commentsTextView.hidden = YES;
            self.timestampLabel.hidden = YES;
            break;
    }
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
    CGSize commentSize = [YAEventCell sizeForCommentsCellWithUsername:username comment:comment];
    return commentSize.height + 8.0f;
}

+ (CGRect)frameForUsernameLabel:(NSString *)username {
    NSDictionary *usernameAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE]};
    CGRect rect = [username boundingRectWithSize:CGSizeMake(MAX_USERNAME_WIDTH, USERNAME_HEIGHT)
                                         options:NSStringDrawingTruncatesLastVisibleLine
                                      attributes:usernameAttributes
                                         context:nil];
    
    return rect;
}

+ (CGSize)sizeForCommentsCellWithUsername:(NSString *)username comment:(NSString *)comment {
    CGSize usernameSize = [[self class] frameForUsernameLabel:username].size;
    CGFloat commentWidth = VIEW_WIDTH - (COMMENTS_SIDE_MARGIN*2) - (usernameSize.width + COMMENTS_SPACE_AFTER_USERNAME);
    
    NSDictionary *commentAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE]};
    CGRect commentsRect = [comment boundingRectWithSize:CGSizeMake(commentWidth, CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:commentAttributes
                                                context:nil];
    
    CGSize commentSize = commentsRect.size;
    
    return commentSize;
}

+ (CGFloat)heightForPostCell {
    return 26.f;
}

+ (CGFloat)heightForLikeCell {
    return 26.f;
}

@end
