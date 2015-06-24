//
//  YAPage.m
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import "YAVideoPage.h"
#import "YAActivityView.h"
#import "YAUser.h"
#import "YAAssetsCreator.h"
#import "YAUtils.h"
#import "YAServer.h"
#import <Social/Social.h>
#import "YAProgressView.h"
#import "YASwipingViewController.h"
#import "YACopyVideoToClipboardActivity.h"
#import "MBProgressHUD.h"
#import "OrderedDictionary.h"
#import "YAPanGestureRecognizer.h"
#import "YADownloadManager.h"
#import "YAServerTransactionQueue.h"
#import "YACrosspostCell.h"
#import "YAEventCell.h"
#import "NSArray+Reverse.h"
#import "UIImage+Color.h"
#import "Constants.h"

#import "YASharingView.h"

#define CAPTION_DEFAULT_SCALE 0.75f
#define CAPTION_WRAPPER_INSET 100.f

#define CAPTION_BUTTON_HEIGHT 80.f
#define CAPTION_DONE_PROPORTION 0.5

#define DOWN_MOVEMENT_TRESHHOLD 800.0f

static NSString *commentCellID = @"CommentCell";


@interface YAVideoPage ()  <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) YAActivityView *activityView;

@property (strong, nonatomic) UIVisualEffectView *captionBlurOverlay;

//overlay controls
@property (strong, nonatomic) UIButton *XButton;
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property BOOL likesShown;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *commentButton;

@property BOOL loading;
@property (strong, nonatomic) UIView *loader;
@property (nonatomic, strong) YAProgressView *progressView;
@property (nonatomic) CGRect keyboardRect;

@property (nonatomic, strong) UILabel *debugLabel;
@property NSUInteger fontIndex;

@property (strong, nonatomic) UITapGestureRecognizer *likeDoubleTapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *captionTapRecognizer;
@property (strong, nonatomic) UILongPressGestureRecognizer *hideGestureRecognizer;

@property (strong, nonatomic) UIView *overlay;

@property (strong, nonatomic) UIView *serverCaptionWrapperView;
@property (strong, nonatomic) UITextView *serverCaptionTextView;
@property (strong, nonatomic) FDataSnapshot *currentCaptionSnapshot;

@property (strong, nonatomic) UIView *editableCaptionWrapperView;
@property (strong, nonatomic) UITextView *editableCaptionTextView;

@property (nonatomic) CGFloat textFieldHeight;
@property (nonatomic) CGAffineTransform textFieldTransform;
@property (nonatomic) CGPoint textFieldCenter;

@property (strong, nonatomic) UIView *tapOutView;
@property (strong, nonatomic) UITapGestureRecognizer *tapOutGestureRecognizer;
@property (strong, nonatomic) YAPanGestureRecognizer *panGestureRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (strong, nonatomic) UIRotationGestureRecognizer *rotateGestureRecognizer;

@property (nonatomic, strong) UIButton *cancelWhileTypingButton;

@property (nonatomic, strong) NSMutableArray *events;

@property (nonatomic, strong) UIButton *textButton;
@property (nonatomic, strong) UIButton *rajsBelovedDoneButton;
@property (nonatomic, strong) UIButton *cancelCaptionButton;
@property (nonatomic) BOOL editingCaption;

@property (nonatomic, strong) UIView *captionButtonContainer;

@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) BOOL previousKeyboardLocation;

@property (strong, nonatomic) UIView *commentsGradient;
@property (nonatomic, strong) UIView *commentsWrapperView;
@property (nonatomic, strong) UITableView *commentsTableView;
@property (nonatomic, strong) UITextField *commentsTextField;
@property (nonatomic, strong) UIButton *commentsSendButton;
@property (nonatomic, strong) UITapGestureRecognizer *commentsTapOutRecognizer;

@property (nonatomic, assign) BOOL uploadInProgress;

//@property CGFloat lastScale;
//@property CGFloat lastRotation;
@property CGFloat firstX;
@property CGFloat firstY;

@property (nonatomic, assign) BOOL shouldPreload;
@property (nonatomic, assign) BOOL myVideo;

@property (strong, nonatomic) YASharingView *sharingView;

@end

@implementation YAVideoPage

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {

        //self.activityView = [[YAActivityView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5)];
//        self.loader = [[UIView alloc] initWithFrame:self.bounds];
//        [self addSubview:self.loader];

        [self addSubview:self.activityView];
        _playerView = [YAVideoPlayerView new];
        [self addSubview:self.playerView];
        
        self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self addSubview:self.overlay];
        
        [self.playerView addObserver:self forKeyPath:@"readyToPlay" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidFinish:) name:AFNetworkingOperationDidFinishNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressChanged:) name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoChanged:) name:VIDEO_CHANGED_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        [self initOverlayControls];
        
//#ifdef DEBUG
//        self.debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 100, self.frame.size.width, 30)];
//        self.debugLabel.textAlignment = NSTextAlignmentCenter;
//        self.debugLabel.textColor = [UIColor whiteColor];
//        [self addSubview:self.debugLabel];
//#endif
        
        [self setBackgroundColor:PRIMARY_COLOR];
    }
    return self;
}

#pragma mark - YAEventReceiver

- (void)videoId:(NSString *)videoId didReceiveNewEvent:(YAEvent *)event {
    if (![videoId isEqualToString:self.video.serverId]) {
        return;
    }
    [self.events insertObject:event atIndex:0];
    [self.commentsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)videoId:(NSString *)videoId receivedInitialEvents:(NSArray *)events {
    if (![videoId isEqualToString:self.video.serverId]) {
        return;
    }
    if ([events count]) {
        [self refreshWholeTableWithEventsArray:[events reversedArray]];
    }
}

- (void)refreshWholeTableWithEventsArray:(NSArray *)events {
    [self.events removeAllObjects];
    [self.commentsTableView reloadData];
    self.events = events ? [events mutableCopy] : [NSMutableArray array];
    [self.events addObject:[YAEvent eventForCreationOfVideo:self.video]];
    NSMutableArray *indexArray = [NSMutableArray array];
    for (int i = 0; i < [self.events count]; i++) {
        [indexArray addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    [self.commentsTableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationTop];
}

#pragma mark - keyboard

- (void)commentsTapOut:(UIGestureRecognizer *)recognizer {
    [self.commentsTextField resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    // Don't move stuff if its the caption keyboard. Only for the comments one.
    if (self.editingCaption) return;
    [self setGesturesEnabled:NO];
    self.commentsTapOutRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentsTapOut:)];
    [self addGestureRecognizer:self.commentsTapOutRecognizer];
    [self moveControls:notification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if (self.editingCaption) return;

    [self setGesturesEnabled:YES];

    [self removeGestureRecognizer:self.commentsTapOutRecognizer];
    // Don't move stuff if its the caption keyboard. Only for the comments one.
    [self moveControls:notification up:NO];
}

- (void)moveControls:(NSNotification*)notification up:(BOOL)up
{
    NSDictionary* userInfo = [notification userInfo];
    CGFloat kbHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    CGFloat delta = kbHeight - self.keyboardHeight;
    self.keyboardHeight = kbHeight;
    CGRect wrapperFrame = self.commentsWrapperView.frame;
    CGRect gradientFrame = self.commentsGradient.frame;
    
    if (up) {
        wrapperFrame.size.height = VIEW_HEIGHT * COMMENTS_HEIGHT_PROPORTION + COMMENTS_TEXT_FIELD_HEIGHT;;
        wrapperFrame.origin.y -= self.previousKeyboardLocation ? delta : (kbHeight + COMMENTS_TEXT_FIELD_HEIGHT-COMMENTS_BOTTOM_MARGIN);
        gradientFrame.origin.y -= self.previousKeyboardLocation ? delta : kbHeight;
    } else {
        // just set the view back to the bottom
        wrapperFrame.size.height = VIEW_HEIGHT*COMMENTS_HEIGHT_PROPORTION;
        wrapperFrame.origin.y = VIEW_HEIGHT - COMMENTS_BOTTOM_MARGIN - wrapperFrame.size.height;
        gradientFrame.origin.y = VIEW_HEIGHT - gradientFrame.size.height;
    }
    
//    if (!self.previousKeyboardLocation && up) {
//        // full on moving this keyboard up
//        wrapperFrame.origin.y -= (COMMENTS_TEXT_FIELD_HEIGHT + 10);
//    } else if (self.previousKeyboardLocation && !up) {
//        // full on moving this keyboard down
//        wrapperFrame.origin.y += (COMMENTS_TEXT_FIELD_HEIGHT + 10);
//    }
    
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.commentsWrapperView.frame = wrapperFrame;
                         self.commentsGradient.frame = gradientFrame;
                         self.commentsTextField.alpha = up ? 1.0 : 0.0;
                         self.commentsSendButton.alpha = up ? 1.0 : 0.0;
                         self.likeButton.alpha = up ? 1.0 : 0.0;
                     }
                     completion:^(BOOL finished){
                         if ([self.events count]) {
                             [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                         }
                     }];
    self.previousKeyboardLocation = up;
}

- (void)keyboardShown:(NSNotification*)n
{
    NSNumber *info = n.userInfo[ UIKeyboardFrameEndUserInfoKey ];
    self.keyboardRect = info.CGRectValue;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.activityView.frame = CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5);
    self.activityView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)setVideo:(YAVideo *)video shouldPreload:(BOOL)shouldPreload {
    if([_video isInvalidated] || ![_video.localId isEqualToString:video.localId]) {
        
        _video = video;

//        self.debugLabel.text = video.serverId;
        
        [self updateControls];
        
        if(!shouldPreload) {
            self.playerView.frame = CGRectZero;
            [self showLoading:YES];
        }
    }
    
    self.shouldPreload = shouldPreload;
    
    if(shouldPreload) {
        [self prepareVideoForPlaying];
    }
    else {
        [self addFullscreenJpgPreview];
    }
    
    //uploading progress
    BOOL uploadInProgress = [[YAServerTransactionQueue sharedQueue] hasPendingUploadTransactionForVideo:self.video];
    [self showUploadingProgress:uploadInProgress];

}

- (void)prepareVideoForPlaying {
    NSURL *movUrl = [YAUtils urlFromFileName:self.video.mp4Filename];
    [self showLoading:![movUrl.absoluteString isEqualToString:self.playerView.URL.absoluteString]];
    
    if(self.video.mp4Filename.length)
    {
        self.playerView.URL = movUrl;
    }
    else
    {
        self.playerView.URL = nil;
    }
    
    self.playerView.frame = self.bounds;
    
    [self addFullscreenJpgPreview];
}

- (void)addFullscreenJpgPreview {
    if([self.playerView isPlaying])
       return;
    
    //add preview if there is one
    if(self.video.jpgFullscreenFilename.length) {
        UIImageView *jpgImageView;
        
        if(self.playerView.subviews.count)
            jpgImageView = self.playerView.subviews[0];
        else {
            jpgImageView = [[UIImageView alloc] init];
            jpgImageView.frame = self.bounds;
            [self.playerView addSubview:jpgImageView];
        }
        
        NSString *jpgPath = [YAUtils urlFromFileName:self.video.jpgFullscreenFilename].path;
        UIImage *jpgImage = [UIImage imageWithContentsOfFile:jpgPath];
        jpgImageView.image = jpgImage;
    }
    //remove if no preview for current video
    else if(self.playerView.subviews.count) {
        UIImageView *jpgImageView = self.playerView.subviews[0];
        [jpgImageView removeFromSuperview];
    }
}

- (void)dealloc {
//    [self clearFirebase];
    
    [self.playerView removeObserver:self forKeyPath:@"readyToPlay"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION      object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION      object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidFinishNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Overlay controls

- (void)initOverlayControls {
    
    CGFloat gradientHeight = VIEW_HEIGHT/3;
    CGFloat buttonRadius = 22.f, padding = 4.f;

    self.commentsGradient = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - gradientHeight, VIEW_WIDTH, gradientHeight)];
//    self.commentsGradient.backgroundColor = [UIColor redColor];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.commentsGradient.bounds;
    ;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithWhite:0.0 alpha:.0] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.4] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.6] CGColor],
//                       (id)[[UIColor colorWithWhite:0.0 alpha:.6] CGColor],
                       nil];
//    gradient.locations = [NSArray arrayWithObjects:
//                          [NSNumber numberWithInt:1.0],
//                          [NSNumber numberWithInt:0.75],
////                          [NSNumber numberWithInt:0.0],
//                          nil];
    
    [self.commentsGradient.layer insertSublayer:gradient atIndex:0];
    [self.overlay addSubview:self.commentsGradient];
    
    CGFloat height = 24;
    self.userLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonRadius*2 + padding*2, 10, 200, height)];
    [self.userLabel setTextAlignment:NSTextAlignmentLeft];
    
//    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"." attributes:@{
//                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
//                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-2.0]                                                                                              }];
//    [self.userLabel setAttributedText: string];
    [self.userLabel setTextColor:[UIColor whiteColor]];
    [self.userLabel setFont:[UIFont fontWithName:BIG_FONT size:21]];

    self.userLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.userLabel.layer.shadowRadius = 0.0f;
    self.userLabel.layer.shadowOpacity = 1.0;
    self.userLabel.layer.shadowOffset = CGSizeMake(0.5, 0.5);
//    [self.overlay addSubview:self.userLabel];
    
    CGFloat timeHeight = 24;
    self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonRadius*2 + padding*2, height + 12, 200, timeHeight)];
    [self.timestampLabel setTextAlignment:NSTextAlignmentLeft];
    [self.timestampLabel setTextColor:[UIColor whiteColor]];
    [self.timestampLabel setFont:[UIFont fontWithName:BIG_FONT size:14]];
    self.timestampLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.timestampLabel.layer.shadowRadius = 0.0f;
    self.timestampLabel.layer.shadowOpacity = 1.0;
    self.timestampLabel.layer.shadowOffset = CGSizeMake(0.5, 0.5);
//    [self.overlay addSubview:self.timestampLabel];
    

//    CGFloat tSize = CAPTION_FONT_SIZE;

    self.XButton = [YAUtils circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding, padding + buttonRadius)];
    self.XButton.transform = CGAffineTransformMakeScale(0.85, 0.85);
    self.XButton.alpha = 0.7;
    [self.XButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.XButton];
    
    self.shareButton = [YAUtils circleButtonWithImage:@"Share" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding,
                                                                                                 VIEW_HEIGHT - buttonRadius - padding)];
    [self.shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.shareButton];
//    self.shareButton.layer.zPosition = 100;
    
//    self.deleteButton = [self circleButtonWithImage:@"Delete" diameter:buttonRadius*2 center:CGPointMake(padding + buttonRadius, padding*2 + buttonRadius)];
//    [self.deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.overlay addSubview:self.deleteButton];
//    self.deleteButton.layer.zPosition = 100;
    
    self.captionButton = [YAUtils circleButtonWithImage:@"Text" diameter:buttonRadius*2 center:CGPointMake(buttonRadius + padding, buttonRadius + padding)];
    [self.captionButton addTarget:self action:@selector(captionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.captionButton];

    
    self.commentButton = [YAUtils circleButtonWithImage:@"comment" diameter:buttonRadius*2 center:CGPointMake(buttonRadius + padding, VIEW_HEIGHT - buttonRadius - padding)];
    [self.commentButton addTarget:self action:@selector(commentButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.commentButton];

    self.cancelWhileTypingButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 30, 30)];
    [self.cancelWhileTypingButton setImage:[UIImage imageNamed:@"Remove"] forState:UIControlStateNormal];
    [self.cancelWhileTypingButton addTarget:self action:@selector(captionCancelPressedWhileTyping) forControlEvents:UIControlEventTouchUpInside];
    
    [self setupCommentsContainer];

    const CGFloat radius = 40;
    self.progressView = [[YAProgressView alloc] initWithFrame:self.bounds];
    self.progressView.radius = radius;
    UIView *progressBkgView = [[UIView alloc] initWithFrame:self.bounds];
    progressBkgView.backgroundColor = [UIColor clearColor];
    self.progressView.backgroundView = progressBkgView;
    
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.progressView];
    
    UIButton *progressXButton = [YAUtils circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding, padding + buttonRadius)];
    progressXButton.transform = CGAffineTransformMakeScale(0.85, 0.85);
    progressXButton.alpha = 0.7;
    [progressXButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.progressView addSubview:progressXButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_progressView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_progressView]-0-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_progressView]-0-|" options:0 metrics:nil views:views]];
    
    self.progressView.indeterminate = NO;
    self.progressView.lineWidth = 4;
    self.progressView.showsText = NO;
    self.progressView.tintColor = [UIColor whiteColor];
    
    self.likeDoubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.likeDoubleTapRecognizer setNumberOfTapsRequired:2];
    self.likeDoubleTapRecognizer.delegate = self;
    [self addGestureRecognizer:self.likeDoubleTapRecognizer];
    
    self.captionTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.captionTapRecognizer setNumberOfTapsRequired:1];
    self.captionTapRecognizer.delegate = self;
    
    [self.captionTapRecognizer requireGestureRecognizerToFail:self.likeDoubleTapRecognizer];

    self.hideGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hideHold:)];
    [self.hideGestureRecognizer setMinimumPressDuration:0.2f];
    [self addGestureRecognizer:self.hideGestureRecognizer];
    
    [self setupCaptionButtonContainer];
    [self setupCaptionGestureRecognizers];
    [self.overlay bringSubviewToFront:self.shareButton];
    [self.overlay bringSubviewToFront:self.deleteButton];
    [self.overlay bringSubviewToFront:self.commentButton];
    
    [self.overlay setAlpha:0.0];
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        [self.overlay setAlpha:1.0];
    } completion:^(BOOL finished) {
        //
    }];

}

#pragma mark - Comments Table View

- (void)setupCommentsContainer {
    CGFloat height = VIEW_HEIGHT*COMMENTS_HEIGHT_PROPORTION;
    self.commentsWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - COMMENTS_BOTTOM_MARGIN - height, VIEW_WIDTH, height)];
    self.commentsTableView = [[UITableView alloc] initWithFrame:CGRectMake(COMMENTS_SIDE_MARGIN, 0, VIEW_WIDTH - (2*COMMENTS_SIDE_MARGIN), height)];
    self.commentsTableView.transform = CGAffineTransformMakeRotation(-M_PI);

    self.commentsTableView.backgroundColor = [UIColor clearColor];
    [self.commentsTableView registerClass:[YAEventCell class] forCellReuseIdentifier:commentCellID];
    
    CAGradientLayer *commentsViewMask = [CAGradientLayer layer];
    CGRect maskFrame = self.commentsWrapperView.bounds;
    maskFrame.size.height += COMMENTS_TEXT_FIELD_HEIGHT;
    commentsViewMask.frame = maskFrame;
    commentsViewMask.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[UIColor whiteColor].CGColor, nil];
    commentsViewMask.startPoint = CGPointMake(0.5f, 0.0f);
    commentsViewMask.endPoint = CGPointMake(0.5f, 0.22f);
    self.commentsWrapperView.layer.mask = commentsViewMask;
    
    self.commentsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.commentsTableView.allowsSelection = NO;
    self.commentsTableView.showsVerticalScrollIndicator = NO;
    self.commentsTableView.contentInset = UIEdgeInsetsMake(0, 0, 30, 0);
    self.commentsTableView.delegate = self;
    self.commentsTableView.dataSource = self;
    self.commentsTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, height, VIEW_WIDTH-COMMENTS_SEND_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    self.commentsTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.commentsTextField.leftViewMode = UITextFieldViewModeAlways;
    self.commentsTextField.returnKeyType = UIReturnKeySend;
    self.commentsTextField.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    UILabel *leftUsernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(COMMENTS_SIDE_MARGIN, 0, VIEW_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    leftUsernameLabel.font = [UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE];
    leftUsernameLabel.text = [NSString stringWithFormat:@"  %@ ", [YAUser currentUser].username];
    leftUsernameLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    leftUsernameLabel.shadowOffset = CGSizeMake(0.5, 0.5);
    leftUsernameLabel.userInteractionEnabled = NO;

    [leftUsernameLabel sizeToFit];
    leftUsernameLabel.textColor = PRIMARY_COLOR;
    self.commentsTextField.leftView = leftUsernameLabel;
    self.commentsTextField.textColor = [UIColor whiteColor];
    self.commentsTextField.font = [UIFont systemFontOfSize:COMMENTS_FONT_SIZE];
    self.commentsTextField.layer.shadowColor = [UIColor blackColor].CGColor;
    self.commentsTextField.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    self.commentsTextField.layer.shadowOpacity = 1.0;
    self.commentsTextField.layer.shadowRadius = 0.0f;

    self.commentsTextField.delegate = self;
    
    self.commentsSendButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - COMMENTS_SEND_WIDTH, height, COMMENTS_SEND_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    [self.commentsSendButton addTarget:self action:@selector(commentsSendPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.commentsSendButton setBackgroundImage:[UIImage imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:1.f]] forState:UIControlStateNormal];
    [self.commentsSendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.commentsSendButton setTitle:@"Send" forState:UIControlStateNormal];
    self.commentsSendButton.hidden = YES;
    
    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - COMMENTS_SEND_WIDTH, height, COMMENTS_SEND_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    [self.likeButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.likeButton addTarget:self action:@selector(addLike) forControlEvents:UIControlEventTouchUpInside];
    [self.likeButton setBackgroundImage:[UIImage imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:1.f]] forState:UIControlStateNormal];
    [self.likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.likeButton setImage:[UIImage imageNamed:@"Liked"] forState:UIControlStateNormal];
    
    [self.commentsWrapperView addSubview:self.commentsTableView];
    [self.commentsWrapperView addSubview:self.commentsSendButton];
    [self.commentsWrapperView addSubview:self.likeButton];
    [self.commentsWrapperView addSubview:self.commentsTextField];
    self.commentsWrapperView.layer.masksToBounds = YES;
    [self.overlay addSubview:self.commentsWrapperView];
    
}

- (void)commentsSendPressed:(id)sender {
    NSString *text = self.commentsTextField.text;
    if ([text length]) {
        // post the comment
        YAEvent *event = [YAEvent new];
        event.eventType = YAEventTypeComment;
        event.comment = text;
        event.username = [YAUser currentUser].username;
        [[YAEventManager sharedManager] addEvent:event toVideoId:[self.video.serverId copy]];
        
        self.commentsTextField.text = @"";
        self.commentsSendButton.hidden = YES;
        self.likeButton.hidden = NO;
//        [self.commentsTextField resignFirstResponder]; // do we want to hide the keyboard after each comment?
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *replaced = [textField.text stringByReplacingCharactersInRange:range withString:string];
    self.commentsSendButton.hidden = ![replaced length];
    self.likeButton.hidden = [replaced length];
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YAEventCell *cell = [tableView dequeueReusableCellWithIdentifier:commentCellID forIndexPath:indexPath];
    cell.containingVideoPage = self;
    cell.transform = cell.transform = CGAffineTransformMakeRotation(M_PI);
    
    YAEvent *event = self.events[indexPath.row];
    [cell configureCellWithEvent:event];

    if (event.eventType == YAEventTypePost) {
        [cell setUploadInProgress:self.uploadInProgress];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.events count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    YAEvent *event = self.events[indexPath.row];
    return [YAEventCell heightForCellWithEvent:event];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.events.count > indexPath.row) {
        return [YAEventCell heightForCellWithEvent:self.events[indexPath.row]];
    }
    else {
        return 0;
    }
}

- (void)setupCaptionButtonContainer {
    self.captionButtonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - CAPTION_BUTTON_HEIGHT, VIEW_WIDTH, CAPTION_BUTTON_HEIGHT)];
    [self.overlay addSubview:self.captionButtonContainer];
    
//    self.textButton = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_ACTION_MARGIN + BOTTOM_ACTION_SIZE, 0, BOTTOM_ACTION_SIZE, BOTTOM_ACTION_SIZE)];
//    [self.textButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
//    self.textButton.tintColor = [YAUtils UIColorFromUsernameString:[YAUser currentUser].username];
//    [self.textButton addTarget:self action:@selector(textButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    
    self.cancelCaptionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH*(1.0-CAPTION_DONE_PROPORTION), CAPTION_BUTTON_HEIGHT)];
    [self.cancelCaptionButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.cancelCaptionButton.backgroundColor = [UIColor colorWithRed:(231.f/255.f) green:(76.f/255.f) blue:(60.f/255.f) alpha:.75];
    [self.cancelCaptionButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.cancelCaptionButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    self.rajsBelovedDoneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cancelCaptionButton.frame.size.width, 0, VIEW_WIDTH*CAPTION_DONE_PROPORTION, CAPTION_BUTTON_HEIGHT)];
    self.rajsBelovedDoneButton.backgroundColor = SECONDARY_COLOR;
    [self.rajsBelovedDoneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.rajsBelovedDoneButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.rajsBelovedDoneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.captionButtonContainer addSubview:self.textButton];
    [self.captionButtonContainer addSubview:self.rajsBelovedDoneButton];
    [self.captionButtonContainer addSubview:self.cancelCaptionButton];
    
    [self toggleEditingCaption:NO];
}

// initial adding of caption. modifications will instead call -updateCaptionFromSnapshot
- (void)insertCaption {
    UIView *textWrapper = [[UIView alloc] initWithFrame:CGRectInfinite];
    UITextView *textView = [self textViewWithCaptionAttributes];
    textView.text = self.video.caption;
    textView.editable = NO;
    
    CGSize newSize = [textView sizeThatFits:CGSizeMake(MAX_CAPTION_WIDTH, MAXFLOAT)];
    CGRect captionFrame = CGRectMake(0, 0, newSize.width, newSize.height);
    textView.frame = captionFrame;

    CGFloat xPos = self.video.caption_x * VIEW_WIDTH;
    CGFloat yPos = self.video.caption_y * VIEW_HEIGHT;
    
    CGRect wrapperFrame = CGRectMake(xPos - (newSize.width/2.f),
                                     yPos - (newSize.height/2.f),
                                     newSize.width,
                                     newSize.height);
    textWrapper.frame = wrapperFrame;

    [textWrapper addSubview:textView];
    
    CGFloat displayScale = self.video.caption_scale * CAPTION_SCREEN_MULTIPLIER;
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(self.video.caption_rotation);
    CGAffineTransform final = CGAffineTransformScale(transform, displayScale, displayScale);
    textWrapper.transform = final;

    [self.overlay addSubview:textWrapper];
    [self.overlay sendSubviewToBack:textWrapper];
    
    self.serverCaptionWrapperView = textWrapper;
    self.serverCaptionTextView = textView;
    self.serverCaptionTextView.userInteractionEnabled = NO;
    
    if ([[self gestureRecognizers] containsObject:self.captionTapRecognizer]) {
        [self removeGestureRecognizer:self.captionTapRecognizer];
    }
    
    textWrapper.alpha = 0;
    CGAffineTransform original = textWrapper.transform;
    textWrapper.transform = CGAffineTransformScale(textWrapper.transform, 0.75, 0.75);
    
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        textWrapper.alpha = 1.f;
        textWrapper.transform = original;
    } completion:nil];
}

#pragma mark - caption gestures

- (void)captionCancelPressedWhileTyping {
    self.editableCaptionTextView.text = @"";
    [self doneTypingCaption];
}

- (void)cancelButtonPressed:(id)sender {
    [self.editableCaptionWrapperView removeFromSuperview];
    self.editableCaptionTextView = nil;
    [self toggleEditingCaption:NO];
    // remove caption and replace done/cancel buttons with text button
}

- (void)doneButtonPressed:(id)sender {
    // Send caption data to firebase
    self.captionButton.hidden = YES;
    [self toggleEditingCaption:NO];
    [self commitCurrentCaption];
}

//- (void)textButtonPressed:(id)sender {
//    [self addCaptionAtPoint:CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT/2)];
//    [self toggleEditingCaption:YES];
//}

- (void)setGesturesEnabled:(BOOL)enabled {
    
    self.hideGestureRecognizer.enabled = enabled;
    self.captionTapRecognizer.enabled = enabled;
    self.likeDoubleTapRecognizer.enabled = enabled;
    if (enabled) {
        [self.presentingVC restoreAllGestures:self];
    } else {
        [self.presentingVC suspendAllGestures:self];
    }
}

- (void)toggleEditingCaption:(BOOL)editing {
    self.editingCaption = editing;
    if (editing) {
        [self setGesturesEnabled:NO];
        self.serverCaptionWrapperView.hidden = YES;
        self.captionButtonContainer.hidden = NO;
//        self.textButton.hidden = YES;
        self.deleteButton.hidden = YES;
        self.shareButton.hidden = YES;
        self.commentsWrapperView.hidden = YES;
        self.XButton.hidden = YES;
        self.commentButton.hidden = YES;
        self.captionButton.hidden = YES;
    } else {
        [self setGesturesEnabled:YES];
        
        self.serverCaptionWrapperView.hidden = NO;

        // could be prettier if i fade all of this
        self.captionButtonContainer.hidden = YES;
//        self.textButton.hidden = NO;
        self.deleteButton.hidden = NO;
        self.shareButton.hidden = NO;
        self.commentsWrapperView.hidden = NO;
        self.XButton.hidden = NO;
        
        self.commentButton.hidden = NO;
        self.captionButton.hidden = NO;
    }
}

- (BOOL)view:(UIView *)view isPositionedEqualTo:(UIView *)view2 {
    if (!(view && view2)) return NO; // Neither are nil
    if (!CGPointEqualToPoint(view.center, view2.center)) return NO; // Have same center
    if (!CGAffineTransformEqualToTransform(view.transform, view2.transform)) return NO; // Have same transform
    return YES;
}

// TODO: Send to server, not firebase, and manually insert serverCaptionWrapper(andText)View
- (void)commitCurrentCaption {
    if (self.editableCaptionTextView) {
        [self.editableCaptionWrapperView removeGestureRecognizer:self.panGestureRecognizer];
        [self.editableCaptionWrapperView removeGestureRecognizer:self.rotateGestureRecognizer];
        [self.editableCaptionWrapperView removeGestureRecognizer:self.pinchGestureRecognizer];
        [self.editableCaptionTextView removeGestureRecognizer:self.captionTapRecognizer];
        [self removeGestureRecognizer:self.captionTapRecognizer];
        self.captionButton.hidden = YES;
        
        NSString *text = self.editableCaptionTextView.text;
        CGFloat x = self.textFieldCenter.x / VIEW_WIDTH;
        CGFloat y = self.textFieldCenter.y / VIEW_HEIGHT;
        
        CGAffineTransform t = self.textFieldTransform;
        CGFloat scale = sqrt(t.a * t.a + t.c * t.c);
//        CGFloat scale = t.a;
        scale = scale / CAPTION_SCREEN_MULTIPLIER;
        
        CGFloat rotation = atan2f(t.b, t.a);
        
        self.serverCaptionWrapperView = self.editableCaptionWrapperView;
        self.serverCaptionTextView = self.editableCaptionTextView;
        self.editableCaptionWrapperView = nil;
        self.editableCaptionTextView = nil;
        self.serverCaptionTextView.editable = NO;
        [self.overlay sendSubviewToBack:self.serverCaptionWrapperView];
        [self.video updateCaption:text withXPosition:x yPosition:y scale:scale rotation:rotation];
    }
}

- (void) setupCaptionGestureRecognizers {
    self.panGestureRecognizer = [[YAPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGestureRecognizer.delegate = self;
    
    self.rotateGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
    self.rotateGestureRecognizer.delegate = self;
    
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    self.pinchGestureRecognizer.delegate = self;
}

// These 3 recognizers should work simultaneously only with eachother
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b {
    if ([a isEqual:self.panGestureRecognizer]) {
        if ([b isEqual:self.rotateGestureRecognizer] || [b isEqual:self.pinchGestureRecognizer]) {
            return YES;
        }
    }
    if ([a isEqual:self.rotateGestureRecognizer]) {
        if ([b isEqual:self.panGestureRecognizer] || [b isEqual:self.pinchGestureRecognizer]) {
            return YES;
        }
    }
    if ([a isEqual:self.pinchGestureRecognizer]) {
        if ([b isEqual:self.panGestureRecognizer] || [b isEqual:self.rotateGestureRecognizer]) {
            return YES;
        }
    }
    return NO;
}


- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         MIN(recognizer.view.center.y + translation.y, VIEW_HEIGHT*.666));
    
    [recognizer setTranslation:CGPointMake(0, 0) inView:self];
    
//    if (recognizer.state == UIGestureRecognizerStateBegan && self.captionTextView.isFirstResponder)
//        [self doneEditingCaption];
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint finalPoint = recognizer.view.center;
        recognizer.view.center = finalPoint;
        self.textFieldCenter = finalPoint;
    }
}

- (void)handleRotate:(UIRotationGestureRecognizer *)recognizer {
    CGAffineTransform newTransform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);
    recognizer.view.transform = newTransform;
    recognizer.rotation = 0;
    self.textFieldTransform = newTransform;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    CGAffineTransform newTransform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    recognizer.view.transform = newTransform;
    recognizer.scale = 1;
    self.textFieldTransform = newTransform;
}


#pragma mark - Caption Positioning


- (void)positionTextViewAboveKeyboard{
    self.editableCaptionWrapperView.transform = CGAffineTransformIdentity;
    [self.editableCaptionWrapperView removeGestureRecognizer:self.panGestureRecognizer];
    [self.editableCaptionWrapperView removeGestureRecognizer:self.rotateGestureRecognizer];
    [self.editableCaptionWrapperView removeGestureRecognizer:self.pinchGestureRecognizer];

    [self resizeTextAboveKeyboardWithAnimation:YES];
}



- (void)moveTextViewBackToSpot {
    CGFloat fixedWidth = MAX_CAPTION_WIDTH;
    CGSize newSize = [self.editableCaptionTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect captionFrame = CGRectMake(CAPTION_WRAPPER_INSET, CAPTION_WRAPPER_INSET, newSize.width, newSize.height);
    CGRect wrapperFrame = CGRectMake(self.textFieldCenter.x - (newSize.width/2.f) - CAPTION_WRAPPER_INSET,
                                 self.textFieldCenter.y - (newSize.height/2.f) - CAPTION_WRAPPER_INSET,
                                 newSize.width + (2.f*CAPTION_WRAPPER_INSET),
                                 newSize.height + (2.f*CAPTION_WRAPPER_INSET));

    __weak YAVideoPage *weakSelf = self;
    
    // sort of hacky way to enable confirming/cancelling caption when near buttons
    [self.overlay bringSubviewToFront:self.captionButtonContainer];
    
    [UIView animateWithDuration:0.2f animations:^{
        weakSelf.editableCaptionWrapperView.frame = wrapperFrame;
        weakSelf.editableCaptionTextView.frame = captionFrame;
        weakSelf.editableCaptionWrapperView.transform = self.textFieldTransform;
    } completion:^(BOOL finished) {
        [weakSelf.editableCaptionWrapperView addGestureRecognizer:self.panGestureRecognizer];
        [weakSelf.editableCaptionWrapperView addGestureRecognizer:self.rotateGestureRecognizer];
        [weakSelf.editableCaptionWrapperView addGestureRecognizer:self.pinchGestureRecognizer];
    }];
}

- (CGSize)sizeThatFitsString:(NSString *)string {
    CGRect frame = [string boundingRectWithSize:CGSizeMake(MAX_CAPTION_WIDTH, CGFLOAT_MAX)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:@{ NSFontAttributeName:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE],
                                                 NSStrokeColorAttributeName:[UIColor whiteColor],
                                                 NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH] } context:nil];
    return frame.size;
}

// returns the same text view, modified. dont need to use return type if u dont wanna
- (UITextView *)textViewWithCaptionAttributes {
    UITextView *textView = [UITextView new];
    textView.alpha = 1;
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"." attributes:@{
                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH]
                                                                                              }];
    [textView setAttributedText:string];
    [textView setBackgroundColor: [UIColor clearColor]]; //[UIColor colorWithWhite:1.0 alpha:0.1]];
    [textView setTextColor:PRIMARY_COLOR];
    [textView setFont:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE]];
    
    [textView setTextAlignment:NSTextAlignmentCenter];
    [textView setAutocorrectionType:UITextAutocorrectionTypeNo];
    [textView setReturnKeyType:UIReturnKeyDone];
    [textView setScrollEnabled:NO];
    textView.textContainer.lineFragmentPadding = 0;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.delegate = self;
    
    return textView;
}

- (void)beginEditableCaptionAtPoint:(CGPoint)point initalText:(NSString *)text initalTransform:(CGAffineTransform)transform {

    self.textFieldCenter = point;
    self.textFieldTransform = transform;
    self.editableCaptionWrapperView = [[UIView alloc] initWithFrame:CGRectInfinite];
    
    self.editableCaptionTextView = [self textViewWithCaptionAttributes];
    self.editableCaptionTextView.text = text;
    
    [self resizeTextAboveKeyboardWithAnimation:NO];
    
    [self.editableCaptionWrapperView addSubview:self.editableCaptionTextView];
    [self.overlay addSubview:self.editableCaptionWrapperView];
    
    [self.editableCaptionTextView becomeFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [self doneTypingCaption];
        return NO;
    }
    
    return [self doesFit:textView string:text range:range];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    self.captionBlurOverlay = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    self.captionBlurOverlay.frame = self.bounds;
    [self.overlay insertSubview:self.captionBlurOverlay belowSubview:self.editableCaptionWrapperView];
    [self.captionBlurOverlay addSubview:self.cancelWhileTypingButton];
    
    if (self.editableCaptionTextView) {
        [self positionTextViewAboveKeyboard];
    }

    return YES;
}

- (float)doesFit:(UITextView*)textView string:(NSString *)myString range:(NSRange) range;
{
    CGSize maxFrame = [self sizeThatFitsString:@"AA\nAA\nAA"];
    maxFrame.width = MAX_CAPTION_WIDTH;
    
    NSMutableAttributedString *atrs = [[NSMutableAttributedString alloc] initWithAttributedString: textView.textStorage];
    [atrs replaceCharactersInRange:range withString:myString];
    
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:atrs];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize: CGSizeMake(maxFrame.width, FLT_MAX)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    float textHeight = [layoutManager
                        usedRectForTextContainer:textContainer].size.height;
    
    if (textHeight >= maxFrame.height - 1) {
        DLog(@" textHeight >= maxViewHeight - 1");
        return NO;
    } else
        return YES;
}


- (void)textViewDidChange:(UITextView *)textView {
    // Should only be called while keyboard is up
    [self resizeTextAboveKeyboardWithAnimation:NO];
}

- (void)resizeTextAboveKeyboardWithAnimation:(BOOL)animated {
    NSString *captionText = [self.editableCaptionTextView.text length] ? self.editableCaptionTextView.text : @"A";
    CGSize size = [self sizeThatFitsString:captionText];
    CGRect wrapperFrame = CGRectMake((VIEW_WIDTH / 2.f) - (size.width/2.f) - CAPTION_WRAPPER_INSET,
                                    (VIEW_HEIGHT / 2.f) - (size.height/2.f) - CAPTION_WRAPPER_INSET,
                                    size.width + (2*CAPTION_WRAPPER_INSET),
                                    size.height + (2*CAPTION_WRAPPER_INSET));
    
    CGRect captionFrame = CGRectMake(CAPTION_WRAPPER_INSET, CAPTION_WRAPPER_INSET, size.width, size.height);
    
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^{
            self.editableCaptionWrapperView.frame = wrapperFrame;
            self.editableCaptionTextView.frame = captionFrame;
        }];
    } else {
        self.editableCaptionWrapperView.frame = wrapperFrame;
        self.editableCaptionTextView.frame = captionFrame;
    }

}

// Send the comment
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self commentsSendPressed:nil];
    return NO;
}


- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.tapOutGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditingTapOut:)];
    [self addGestureRecognizer:self.tapOutGestureRecognizer];
}

- (void)doneEditingTapOut:(id)sender {
    [self doneTypingCaption];
}

- (void)doneTypingCaption {
    [self removeGestureRecognizer:self.tapOutGestureRecognizer];
    
    [self.editableCaptionTextView resignFirstResponder];
    [self.captionBlurOverlay removeFromSuperview];
    
    if (![self.editableCaptionTextView.text length]) {
        [self cancelButtonPressed:nil];
    } else {
        [self moveTextViewBackToSpot];
    }
}

- (void)handleTap:(UITapGestureRecognizer *) recognizer {
    NSLog(@"tapped");
    if (self.editingCaption) return;
    if ([recognizer isEqual:self.likeDoubleTapRecognizer]) {
        [self addLike];
    } else if ([recognizer isEqual:self.captionTapRecognizer]){
        [self toggleEditingCaption:YES];
        CGPoint loc = [recognizer locationInView:self];
        
        float randomRotation = ((float)rand() / RAND_MAX) * .4;
        CGAffineTransform t = CGAffineTransformConcat(CGAffineTransformMakeScale(CAPTION_DEFAULT_SCALE * CAPTION_SCREEN_MULTIPLIER,
                                                                                 CAPTION_DEFAULT_SCALE * CAPTION_SCREEN_MULTIPLIER), CGAffineTransformMakeRotation(-.2 + randomRotation));

        [self beginEditableCaptionAtPoint:loc
                                initalText:@""
                           initalTransform:t];
    }
}

- (void)captionButtonPressed {
    [self toggleEditingCaption:YES];
    
    float randomX = ((float)rand() / RAND_MAX) * 100;
    float randomY = ((float)rand() / RAND_MAX) * 200;
    CGPoint loc = CGPointMake(VIEW_WIDTH/2 - 50 + randomX, VIEW_HEIGHT/2 - randomY);
    
    float randomRotation = ((float)rand() / RAND_MAX) * .4;
    CGAffineTransform t = CGAffineTransformConcat(CGAffineTransformMakeScale(CAPTION_DEFAULT_SCALE * CAPTION_SCREEN_MULTIPLIER,
                                                       CAPTION_DEFAULT_SCALE * CAPTION_SCREEN_MULTIPLIER), CGAffineTransformMakeRotation(-.2 + randomRotation));
    
    [self beginEditableCaptionAtPoint:loc
                           initalText:@""
                      initalTransform:t];

}

- (void)addLike {

    YAEvent *event = [YAEvent new];
    event.eventType = YAEventTypeLike;
    event.username = [YAUser currentUser].username;
    [[YAEventManager sharedManager] addEvent:event toVideoId:[self.video.serverId copy]];
}

- (void)hideHold:(UILongPressGestureRecognizer *) recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan){
        [UIView animateWithDuration:0.2 animations:^{
            [self.overlay setAlpha:0.0];
        }];
        
    } else if(recognizer.state == UIGestureRecognizerStateEnded){
        [UIView animateWithDuration:0.2 animations:^{
            //
            [self.overlay setAlpha:1.0];
        }];
    }
}

#pragma mark - ETC

- (void)deleteButtonPressed {
    [self animateButton:self.deleteButton withImageName:nil completion:^{
        [YAUtils deleteVideo:self.video];
    }];
}


- (void)commentButtonPressed {
    [self.commentsTextField becomeFirstResponder];
}

- (void)animateButton:(UIButton*)button withImageName:(NSString*)imageName completion:(void (^)(void))completion {
    [UIView animateKeyframesWithDuration:0.3 delay:0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
            button.transform = CGAffineTransformMakeScale(1.5, 1.5);
        }];
        
        if(imageName) {
            if([button backgroundImageForState:UIControlStateNormal])
                [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
            else
                [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        }
        
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.4 animations:^{
            button.transform = CGAffineTransformIdentity;
        }];
        
    } completion:^(BOOL finished) {
        if(completion)
            completion();
    }];
    
}

- (void)initializeCaption {
    [self.serverCaptionWrapperView removeFromSuperview];
    if ([self.video.caption length]) {
         [self insertCaption];
    } else if (self.myVideo) {
        [self addGestureRecognizer:self.captionTapRecognizer];
    }
}

- (void)updateControls {
    NSLog(@"update controls");
   
    self.myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
    self.deleteButton.hidden = !self.myVideo;
    self.shareButton.hidden = !self.myVideo;
    self.captionButton.hidden = !self.myVideo || ![self.video.caption isEqualToString:@""];
    NSArray *events = [[[YAEventManager sharedManager] getEventsForVideoId:self.video.serverId] reversedArray];
    [self refreshWholeTableWithEventsArray:events];
    [self initializeCaption];
    
    BOOL mp4Downloaded = self.video.mp4Filename.length;

//    NSAttributedString *string = [[NSAttributedString alloc] initWithString:self.video.creator attributes:@{
//                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
//                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-2.0]                                                                                              }];
//    [self.userLabel setAttributedText: string];
//
    [self.userLabel setText:self.video.creator];
//    self.userLabel.textColor = [YAUtils UIColorFromUsernameString:self.video.creator];
    
    self.timestampLabel.text = [[YAUser currentUser] formatDate:self.video.createdAt]; //[[self.video.createdAt formattedAsTimeAgo] lowercaseString];
//    [self.likeButton setBackgroundImage:self.video.like ? [UIImage imageNamed:@"Liked"] : [UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
//    self.likeCount.hidden = (self.video.like && self.video.likers.count == 1);
//    self.captionField.text = self.video.caption;
    self.fontIndex = self.video.font;
//    if(![self.video.namer isEqual:@""]){
//        [self.captionerLabel setText:[NSString stringWithFormat:@"- %@", self.video.namer]];
//    } else {
//        [self.captionerLabel setText:@""];
//    }
    
    // self.captionField.hidden = !mp4Downloaded;
    // self.captionerLabel.hidden = !mp4Downloaded || !self.captionField.text.length;
//    self.captionButton.hidden = !mp4Downloaded;


    self.deleteButton.hidden = !mp4Downloaded && !self.myVideo;

//    [self.likeCount setTitle:self.video.likes ? [NSString stringWithFormat:@"%ld", (long)self.video.likes] : @""
//                    forState:UIControlStateNormal];
//
    
    self.captionTapRecognizer.enabled = mp4Downloaded;
    self.likeDoubleTapRecognizer.enabled = mp4Downloaded;
    self.commentButton.enabled = mp4Downloaded;
    self.captionButton.enabled = mp4Downloaded;
    self.shareButton.enabled = mp4Downloaded;

    [self showProgress:!mp4Downloaded];
    
}

- (void)closeButtonPressed:(id)sender {
    // close video here
    if([self.presentingVC isKindOfClass:[YASwipingViewController class]]){
        [((YASwipingViewController *) self.presentingVC) dismissAnimated];
    }
}

- (void)shareButtonPressed:(id)sender {
    
    NSLog(@"two thirds: %f", VIEW_HEIGHT * 2 / 3);
    self.sharingView = [[YASharingView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT * .6, VIEW_WIDTH, VIEW_HEIGHT*.4)];
    self.sharingView.video = self.video;
    self.sharingView.page = self;
    [self setGesturesEnabled:NO];
    [self addSubview:self.sharingView];
    
    [self.sharingView setTransform:CGAffineTransformMakeTranslation(0, self.sharingView.frame.size.height)];
    CGRect gradientFrame = self.commentsGradient.frame;
    gradientFrame.size.height = VIEW_HEIGHT / 3;

    [UIView animateWithDuration:0.2 animations:^{
        self.commentsGradient.frame = gradientFrame;
        self.commentsWrapperView.alpha = 0.0;
        self.commentButton.alpha = 0.0;
        self.shareButton.alpha = 0.0;
        [self.sharingView setTransform:CGAffineTransformIdentity];

    }];
    
    self.tapOutView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_HEIGHT * .6, VIEW_WIDTH)];
    [self addSubview:self.tapOutView];
    self.tapOutGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneCrosspostingTapOut:)];
    [self.tapOutView addGestureRecognizer:self.tapOutGestureRecognizer];
    
//    sharingVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
//    [(YASwipingViewController*)self.presentingVC presentViewController:sharingVC animated:YES completion:nil];
}

- (void)collapseCrosspost {
    NSLog(@"collapsing...");
    [self setGesturesEnabled:YES];
    
    CGRect gradientFrame = self.commentsGradient.frame;
    gradientFrame.size.height = VIEW_HEIGHT * .5;
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        //
        self.commentsGradient.frame = gradientFrame;
        self.commentsWrapperView.alpha = 1.0;
        self.commentButton.alpha = 1.0;
        self.shareButton.alpha = 1.0;
        [self.sharingView setTransform:CGAffineTransformMakeTranslation(0, self.sharingView.frame.size.height)];
    } completion:^(BOOL finished) {
        //
        [self.sharingView removeFromSuperview];

    }];

    [self.tapOutView removeFromSuperview];
    [self.tapOutView removeGestureRecognizer:self.tapOutGestureRecognizer];
    
}

- (void)doneCrosspostingTapOut:(UITapGestureRecognizer *)recognizer {
    NSLog(@"rec");
    [self collapseCrosspost];
}

#pragma mark - UITableView delegate methods (groups list)


#pragma mark - YAProgressView
- (void)downloadDidStart:(NSNotification*)notif {
    NSOperation *op = notif.object;
    if(![self.video isInvalidated] && [op.name isEqualToString:self.video.url]) {
        [self showProgress:YES];
    }
}

- (void)downloadDidFinish:(NSNotification*)notif {
    NSOperation *op = notif.object;
    if(![self.video isInvalidated] && [op.name isEqualToString:self.video.url]) {
        [self showProgress:NO];
    }
}

- (void)showProgress:(BOOL)show {
    self.progressView.hidden = !show;
    if(!self.progressView.hidden) {
        if(self.video.url.length) {
            [self.progressView setProgress:[[[YADownloadManager sharedManager].mp4DownloadProgress objectForKey:self.video.url] floatValue] animated:NO];
        }
        else {
            [self.progressView setProgress:0 animated:NO];
        }
        
        [self.progressView setCustomText:@""];
    }
}

- (void)showLoading:(BOOL)show {
    
//    //used to show spinning monkey while video asset is loading, currently does nothing
//    if(self.loading){
//        if(!show){
//            [self.loader.layer removeAllAnimations];
//            self.loading = NO;
//        }
//    } else {
//        if(show){
//            [self.loader setBackgroundColor:[UIColor blackColor]];
//            [self.loader setAlpha:0.0];
//            [UIView animateWithDuration:0.2 delay:0.0 options:(UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionBeginFromCurrentState) animations:^{
//                //
//                [self.loader setAlpha:0.2];
//            } completion:^(BOOL finished) {
//                //
//            }];
//            
//            self.loading = YES;
//        }
//    }
}


- (void)downloadProgressChanged:(NSNotification*)notif {
    NSString *url = notif.object;
    if(![self.video isInvalidated] && [url isEqualToString:self.video.url]) {
        
        if(self.progressView) {
            NSNumber *value = notif.userInfo[kVideoDownloadNotificationUserInfoKey];
            [self.progressView setProgress:value.floatValue animated:YES];
            [self.progressView setCustomText:@""];
        }
    }
}

- (void)showUploadingProgress:(BOOL)show {
    self.uploadInProgress = show;
    
    YAEventCell *postCell = (YAEventCell *)[self.commentsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.events count] - 1 inSection:0]];
    if (postCell) {
        [postCell setUploadInProgress:show];
    }
}

- (void)videoChanged:(NSNotification*)notif {
    if([notif.object isEqual:self.video] && !self.playerView.URL && self.shouldPreload && self.video.mp4Filename.length) {
        //setURL will remove playWhenReady flag, so saving it and using later
        BOOL playWhenReady = self.playerView.playWhenReady;
        [self prepareVideoForPlaying];
        self.playerView.playWhenReady = playWhenReady;
        
        [self updateControls];
        
        //uploading progress
        BOOL uploadInProgress = [[YAServerTransactionQueue sharedQueue] hasPendingUploadTransactionForVideo:self.video];
        [self showUploadingProgress:uploadInProgress];
    }
}

#pragma mark - UIPanGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

// Ignore like tap if in trash button, share button, or caption button, or a tap in the caption field.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.captionButtonContainer.superview != nil) {
        if ([touch.view isDescendantOfView:self.captionButtonContainer]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }
    if (self.deleteButton.superview != nil) {
        if ([touch.view isDescendantOfView:self.deleteButton]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }
    if (self.shareButton.superview != nil) {
        if ([touch.view isDescendantOfView:self.shareButton]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }
    return YES; // handle the touch
}
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[YAVideoPlayerView class]]) {
        [self showLoading:!((YAVideoPlayerView*)object).readyToPlay];
    }
}


@end
