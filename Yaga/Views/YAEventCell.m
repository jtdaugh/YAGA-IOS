//
//  YACommentsCell.m
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAEventCell.h"

#import "YAUser.h"

@interface YAEventCell ()

@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) UITextView *commentsTextView;

@property (nonatomic, strong) NSString *timestamp;

@end

@implementation YAEventCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        CGFloat initialUsernameWidth = 100, initialHeight = 26;
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
        

        // Text Delete button
        self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, initialHeight)];
        [self.deleteButton.titleLabel setFont:[UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE - 3.0f]];
        [self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
        [self.deleteButton setTitleColor:[UIColor colorWithRed:158.0f/255.0f green:11.0f/255.0f blue:15.0f/255.0f alpha:1.0] forState:UIControlStateNormal];

        [self.deleteButton addTarget:self action:@selector(deletePressed) forControlEvents:UIControlEventTouchUpInside];
        self.deleteButton.layer.shadowColor = [UIColor blackColor].CGColor;
        self.deleteButton.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        self.deleteButton.layer.shadowOpacity = 0.3;
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
    [self layoutUsername:username];
    self.commentsTextView.text = comment;
    CGRect commentFrame = self.commentsTextView.frame;
    commentFrame.origin.x = self.usernameLabel.frame.size.width + 8.0f;
    commentFrame.size = [[self class] sizeForCommentsCellWithUsername:username comment:comment];
    self.commentsTextView.frame = commentFrame;
}

- (void)configureLikeCellWithUsername:(NSString *)username {
    [self setCellType:YAEventTypeLike];
    self.usernameLabel.text = username;
    [self layoutUsername:username];
    self.iconImageView.image = [UIImage imageNamed:@"Liked"];
    [self layoutImageViewWithYOffset:-1.f];
    
}

- (void)configurePostCellWithUsername:(NSString *)username timestamp:(NSString *)timestamp isOwnVideo:(BOOL)isOwnVideo {
    self.timestamp = timestamp;
    
    [self setCellType:YAEventTypePost];
    self.usernameLabel.text = username;
    [self layoutUsername:username];
    self.timestampLabel.text = timestamp;
    self.deleteButton.hidden = !isOwnVideo;
    self.iconImageView.image = [UIImage imageNamed:@"Movie"];
    [self layoutImageViewWithYOffset:-3.f];
    [self layoutPostViews];
}

- (void)layoutUsername:(NSString *)username {
    self.usernameLabel.frame = [[self class] frameForUsernameLabel:username];
}

- (void)layoutImageViewWithYOffset:(CGFloat)yOffset {
    CGRect imageFrame = self.iconImageView.frame;
    imageFrame.origin.x = self.usernameLabel.frame.size.width + 4.f;
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

- (void)setUploadInProgress:(BOOL)uploadInProgress {
    if (uploadInProgress) {
        self.timestampLabel.text = @"Uploading...";
        [self.deleteButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self layoutPostViews];
    } else {
        self.timestampLabel.text = self.timestamp;
        [self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
        [self layoutPostViews];
    }
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
    [YAUtils confirmDeleteVideo:self.containingVideoPage.video withConfirmationBlock:^{
        if(self.containingVideoPage.video.realm)
            [self.containingVideoPage.video removeFromCurrentGroupWithCompletion:nil removeFromServer:[YAUser currentUser].currentGroup != nil];
        else
            [self.containingVideoPage closeAnimated];
    }];;
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
    CGRect rect = [username boundingRectWithSize:CGSizeMake(VIEW_WIDTH/2, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:usernameAttributes
                                         context:nil];
    
    return rect;
}

+ (CGSize)sizeForCommentsCellWithUsername:(NSString *)username comment:(NSString *)comment {
    CGSize usernameSize = [[self class] frameForUsernameLabel:username].size;
    CGFloat commentWidth = VIEW_WIDTH - (COMMENTS_SIDE_MARGIN*2) - (usernameSize.width + 6.0f);
    
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
