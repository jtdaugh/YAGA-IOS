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
#import "YACommentsCell.h"

#define CAPTION_FONT_SIZE 60.0
#define CAPTION_STROKE_WIDTH 3.f
#define CAPTION_DEFAULT_SCALE 0.75f
#define CAPTION_GUTTER 5.f
#define CAPTION_WRAPPER_INSET 100.f

#define COMMENTS_BOTTOM_MARGIN 50.f
#define COMMENTS_FONT_SIZE 16.f
#define COMMENTS_SIDE_MARGIN 10.f
#define COMMENTS_HEIGHT_PROPORTION 0.2f
#define COMMENTS_TEXT_FIELD_HEIGHT 40.f
#define COMMENTS_SEND_WIDTH 70.f

#define BOTTOM_ACTION_SIZE 40.f
#define BOTTOM_ACTION_MARGIN 10.f

#define MAX_CAPTION_WIDTH (VIEW_WIDTH - 2 * CAPTION_GUTTER)
#define DOWN_MOVEMENT_TRESHHOLD 800.0f

static NSString *commentCellID = @"CommentCell";

@interface YAVideoPage ()  <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) YAActivityView *activityView;

//overlay controls
@property (strong, nonatomic) UIButton *XButton;
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property BOOL likesShown;
@property (nonatomic, strong) UIButton *captionButton;
//@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *commentButton;

@property (nonatomic, strong) YAActivityView *uploadingView;

@property BOOL loading;
@property (strong, nonatomic) UIView *loader;
@property (nonatomic, strong) YAProgressView *progressView;
@property (nonatomic) CGRect keyboardRect;
@property (nonatomic, strong) UIButton *keyBoardAccessoryButton;

@property (nonatomic, strong) UILabel *debugLabel;
@property NSUInteger fontIndex;

@property (strong, nonatomic) UITapGestureRecognizer *likeDoubleTapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *captionTapRecognizer;
@property (strong, nonatomic) UILongPressGestureRecognizer *hideGestureRecognizer;

@property (strong, nonatomic) UIView *overlay;
@property (strong, nonatomic) UIVisualEffectView *captionBlurOverlay;

@property (strong, nonatomic) UIView *serverCaptionWrapperView;
@property (strong, nonatomic) UITextView *serverCaptionTextView;
@property (strong, nonatomic) FDataSnapshot *currentCaptionSnapshot;

@property (strong, nonatomic) UIView *editableCaptionWrapperView;
@property (strong, nonatomic) UITextView *editableCaptionTextView;

@property (nonatomic) CGFloat textFieldHeight;
@property (nonatomic) CGAffineTransform textFieldTransform;
@property (nonatomic) CGPoint textFieldCenter;

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

//@property CGFloat lastScale;
//@property CGFloat lastRotation;
@property CGFloat firstX;
@property CGFloat firstY;

@property (nonatomic, assign) BOOL shouldPreload;
@property (nonatomic, assign) BOOL myVideo;
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

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputModeChanged:) name:UITextInputCurrentInputModeDidChangeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDown:) name:UIKeyboardDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUploadVideo:) name:VIDEO_DID_UPLOAD object:nil];
        
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
    CGFloat wrapperHeight = wrapperFrame.size.height;
    CGRect gradientFrame = self.commentsGradient.frame;
    
    if (up) {
        wrapperHeight = VIEW_HEIGHT * COMMENTS_HEIGHT_PROPORTION + COMMENTS_TEXT_FIELD_HEIGHT;
        wrapperFrame.size.height = wrapperHeight;
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
                     }
                     completion:^(BOOL finished){
                         if ([self.events count]) {
                             [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                         }
                     }];
    self.previousKeyboardLocation = up;
}

- (void)keyboardDown:(NSNotification*)n
{
    self.keyBoardAccessoryButton.hidden = YES;
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
    [self clearFirebase];

    [self.playerView removeObserver:self forKeyPath:@"readyToPlay"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION      object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION      object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidFinishNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_UPLOAD object:nil];
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
//    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - tSize, 0, tSize, tSize)];
//    [self.captionButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
//    [self.captionButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.captionButton setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
////    [self addSubview:self.captionButton];
    
    CGFloat bottomButtonCenterY = VIEW_HEIGHT - buttonRadius - padding;
//    self.likeButton = [self circleButtonWithImage:@"Like" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH/2, bottomButtonCenterY)];
//    [self.likeButton addTarget:self action:@selector(likeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.overlay addSubview:self.likeButton];

    
    self.XButton = [self circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding, padding + buttonRadius)];
    self.XButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.XButton.alpha = 0.8;
    [self.XButton addTarget:self action:@selector(XButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.XButton];
    
    self.shareButton = [self circleButtonWithImage:@"Share" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding,
                                                                                                 VIEW_HEIGHT - buttonRadius - padding)];
    [self.shareButton addTarget:self action:@selector(shareButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.shareButton];
//    self.shareButton.layer.zPosition = 100;
    
//    self.deleteButton = [self circleButtonWithImage:@"Delete" diameter:buttonRadius*2 center:CGPointMake(padding + buttonRadius, padding*2 + buttonRadius)];
//    [self.deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.overlay addSubview:self.deleteButton];
//    self.deleteButton.layer.zPosition = 100;
    
    self.commentButton = [self circleButtonWithImage:@"comment" diameter:buttonRadius*2 center:CGPointMake(buttonRadius + padding, VIEW_HEIGHT - buttonRadius - padding)];
    [self.commentButton addTarget:self action:@selector(commentButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.commentButton];
//    self.commentButton.layer.zPosition = 100;
    
//    CGFloat likeSize = 42;
//
//    CGFloat likeCountWidth = 24, likeCountHeight = 42;
//    self.likeCount = [[UIButton alloc] initWithFrame:CGRectMake(self.likeButton.frame.origin.x + self.likeButton.frame.size.width + 8, VIEW_HEIGHT - likeCountHeight - 12, likeCountWidth, likeCountHeight)];
//    [self.likeCount addTarget:self action:@selector(likeCountPressed) forControlEvents:UIControlEventTouchUpInside];
//    //    [self.likeCount setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
//    [self.likeCount.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:16]];
//    self.likeCount.layer.shadowColor = [[UIColor blackColor] CGColor];
//    self.likeCount.layer.shadowRadius = 1.0f;
//    self.likeCount.layer.shadowOpacity = 1.0;
//    self.likeCount.layer.shadowOffset = CGSizeZero;
//    //    [self.likeCount setBackgroundColor:[UIColor greenColor]];
////    [self addSubview:self.likeCount];
    
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

- (UIButton *)circleButtonWithImage:(NSString *)imageName diameter:(CGFloat)diameter center:(CGPoint)center {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
    button.center = center;
//    button.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.2f];
//    button.layer.borderColor = [[UIColor whiteColor] CGColor];
//    button.layer.borderWidth = 1.f;
//    button.layer.cornerRadius = diameter/2.f;
//    button.layer.masksToBounds = YES;
    [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    return button;
}

#pragma mark - Comments Table View

- (void)setupCommentsContainer {
    CGFloat height = VIEW_HEIGHT*COMMENTS_HEIGHT_PROPORTION;
    self.commentsWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - COMMENTS_BOTTOM_MARGIN - height, VIEW_WIDTH, height)];
    self.commentsTableView = [[UITableView alloc] initWithFrame:CGRectMake(COMMENTS_SIDE_MARGIN, 0, VIEW_WIDTH - (2*COMMENTS_SIDE_MARGIN), height)];
    self.commentsTableView.transform = CGAffineTransformMakeRotation(-M_PI);

    self.commentsTableView.backgroundColor = [UIColor clearColor];
    [self.commentsTableView registerClass:[YACommentsCell class] forCellReuseIdentifier:commentCellID];
    self.commentsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.commentsTableView.allowsSelection = NO;
    self.commentsTableView.showsVerticalScrollIndicator = NO;
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
    [leftUsernameLabel sizeToFit];
    leftUsernameLabel.textColor = PRIMARY_COLOR;
    self.commentsTextField.leftView = leftUsernameLabel;
    self.commentsTextField.textColor = [UIColor whiteColor];
    self.commentsTextField.font = [UIFont systemFontOfSize:COMMENTS_FONT_SIZE];
    self.commentsTextField.delegate = self;
    self.commentsSendButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - COMMENTS_SEND_WIDTH, height, COMMENTS_SEND_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    [self.commentsSendButton addTarget:self action:@selector(commentsSendPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.commentsSendButton.backgroundColor = PRIMARY_COLOR;
    [self.commentsSendButton setTitle:@"Send" forState:UIControlStateNormal];
    
    [self.commentsWrapperView addSubview:self.commentsTableView];
    [self.commentsWrapperView addSubview:self.commentsSendButton];
    [self.commentsWrapperView addSubview:self.commentsTextField];
    self.commentsWrapperView.layer.masksToBounds = YES;
    [self.overlay addSubview:self.commentsWrapperView];
    
}

- (void)commentsSendPressed:(id)sender {
    NSString *text = self.commentsTextField.text;
    if ([text length]) {
        // post the comment
        NSDictionary *event = @{
                                @"type":@"comment",
                                @"username":[YAUser currentUser].username,
                                @"comment":text
                                };
        [[[[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAppendingPath:@"events"] childByAutoId] setValue:event];
        self.commentsTextField.text = @"";
//        [self.commentsTextField resignFirstResponder]; // do we want to hide the keyboard after each comment?
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YACommentsCell *cell = [tableView dequeueReusableCellWithIdentifier:commentCellID forIndexPath:indexPath];
    cell.transform = cell.transform = CGAffineTransformMakeRotation(M_PI);

    NSDictionary *event = self.events[indexPath.row];
    if (event[@"username"]) {
        [cell setUsername:event[@"username"]];
    }
    NSString *type = event[@"type"];
    if ([type isEqualToString:@"comment"]) {
        [cell setCellType:YACommentsCellTypeComment];
        [cell setComment:event[@"comment"]];
    } else if ([type isEqualToString:@"post"]) {
        [cell setCellType:YACommentsCellTypePost];
        [cell setTimestamp:event[@"timestamp"]];
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
    
    NSDictionary *event = self.events[indexPath.row];
    if ([event[@"type"] isEqualToString:@"comment"]) {
        return [YACommentsCell heightForCommentCellWithUsername:event[@"username"] comment:event[@"comment"]];
    } else if ([event[@"type"] isEqualToString:@"post"]) {
        return [YACommentsCell heightForPostCellWithUsername:event[@"username"] timestamp:event[@"timestamp"]];
    } else {
        return 0.0;
    }
}

- (void)setupCaptionButtonContainer {
    self.captionButtonContainer = [[UIView alloc] initWithFrame:CGRectMake(VIEW_WIDTH - BOTTOM_ACTION_SIZE*2 - BOTTOM_ACTION_MARGIN*2,
                                                                           VIEW_HEIGHT - BOTTOM_ACTION_MARGIN - BOTTOM_ACTION_SIZE,
                                                                           BOTTOM_ACTION_SIZE*2 + BOTTOM_ACTION_MARGIN*2,
                                                                           BOTTOM_ACTION_SIZE + BOTTOM_ACTION_MARGIN)];
    [self.overlay addSubview:self.captionButtonContainer];
    
//    self.textButton = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_ACTION_MARGIN + BOTTOM_ACTION_SIZE, 0, BOTTOM_ACTION_SIZE, BOTTOM_ACTION_SIZE)];
//    [self.textButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
//    self.textButton.tintColor = [YAUtils UIColorFromUsernameString:[YAUser currentUser].username];
//    [self.textButton addTarget:self action:@selector(textButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    
    self.rajsBelovedDoneButton = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_ACTION_MARGIN + BOTTOM_ACTION_SIZE, 0, BOTTOM_ACTION_SIZE, BOTTOM_ACTION_SIZE)];
    self.rajsBelovedDoneButton.backgroundColor = [UIColor colorWithRed:(39.f/255.f) green:(174.f/255.f) blue:(96.f/255.f) alpha:1];
    self.rajsBelovedDoneButton.layer.cornerRadius = BOTTOM_ACTION_SIZE/2.f;
    self.rajsBelovedDoneButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.rajsBelovedDoneButton.layer.borderWidth = 1.f;
    self.rajsBelovedDoneButton.layer.masksToBounds = YES;
    [self.rajsBelovedDoneButton setImage:[UIImage imageNamed:@"Check"] forState:UIControlStateNormal];
    [self.rajsBelovedDoneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    
    self.cancelCaptionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BOTTOM_ACTION_SIZE, BOTTOM_ACTION_SIZE)];
    [self.cancelCaptionButton setImage:[UIImage imageNamed:@"Cancel"] forState:UIControlStateNormal];
    self.cancelCaptionButton.backgroundColor = [UIColor colorWithRed:(231.f/255.f) green:(76.f/255.f) blue:(60.f/255.f) alpha:1];
    self.cancelCaptionButton.layer.cornerRadius = BOTTOM_ACTION_SIZE/2.f;
    self.cancelCaptionButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.cancelCaptionButton.layer.borderWidth = 1.f;
    self.cancelCaptionButton.layer.masksToBounds = YES;
    
    [self.cancelCaptionButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.captionButtonContainer addSubview:self.textButton];
    [self.captionButtonContainer addSubview:self.rajsBelovedDoneButton];
    [self.captionButtonContainer addSubview:self.cancelCaptionButton];
    
    [self toggleEditingCaption:NO];
}

- (void) clearFirebase {
    
    [[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] removeAllObservers];
    [[[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAppendingPath:@"events"] removeAllObservers];
    [[[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAppendingPath:@"caption"] removeAllObservers];

    [self.serverCaptionWrapperView removeFromSuperview];
    self.serverCaptionWrapperView = nil;
    self.serverCaptionTextView = nil;
}

- (void) initFirebase {
    
    NSLog(@"serverid: %@", self.video.serverId);
    
    [self beginMonitoringForEvents];
    [self beginMonitoringForCaption];
}

- (void)beginMonitoringForCaption {
    __weak YAVideoPage *weakSelf = self;
    Firebase *caption = [[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAppendingPath:@"caption"];
    
    // TODO: Queue these up in case user changes text and position (common). As is, that will cause this to fire multiple times instantly.
    [caption observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (snapshot.exists) {
            [weakSelf insertCaptionFromSnapshot:snapshot];
        } else if (self.myVideo) {
            [weakSelf addGestureRecognizer:weakSelf.captionTapRecognizer];
        }
    }];
}


- (void)beginMonitoringForEvents {
    Firebase *events = [[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAppendingPath:@"events"];
    
    __weak YAVideoPage *weakSelf = self;
    
    __block BOOL initialLoaded = NO;
    
    [events observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [weakSelf.events insertObject:snapshot.value atIndex:0];
        if (initialLoaded) {
            [weakSelf.commentsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        } else {
            [weakSelf.commentsTableView reloadData];
        }
    }];
    
    [events observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        initialLoaded = YES;
    }];
    

}

// initial adding of caption. modifications will instead call -updateCaptionFromSnapshot
- (void)insertCaptionFromSnapshot:(FDataSnapshot *)snapshot {
    self.currentCaptionSnapshot = snapshot;

    NSString *username = snapshot.value[@"username"];
    if (!username) username = @"yaga";

    UIView *textWrapper = [[UIView alloc] initWithFrame:CGRectInfinite];
    UITextView *textView = [self textViewWithCaptionAttributes];
    textView.text = snapshot.value[@"text"];
    textView.editable = NO;
    
    CGSize newSize = [textView sizeThatFits:CGSizeMake(MAX_CAPTION_WIDTH, MAXFLOAT)];
    CGRect captionFrame = CGRectMake(0, 0, newSize.width, newSize.height);
    textView.frame = captionFrame;

    CGRect wrapperFrame = CGRectMake([snapshot.value[@"x"] doubleValue]*VIEW_WIDTH - (newSize.width/2.f),
                                     [snapshot.value[@"y"] doubleValue]*VIEW_HEIGHT - (newSize.height/2.f),
                                     newSize.width,
                                     newSize.height);
    textWrapper.frame = wrapperFrame;

    [textWrapper addSubview:textView];
    textWrapper.transform =CGAffineTransformFromString(snapshot.value[@"transform"]);

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

- (BOOL)captionSnapshot:(FDataSnapshot *)snapshot1 isEqualToSnapshot:(FDataSnapshot *)snapshot2 {
    if (!snapshot1.exists && snapshot2.exists) {
        return NO;
    }
    
    if (![snapshot1.value[@"text"] isEqualToString:snapshot2.value[@"text"]]) {
        return NO;
    }
    if (!([snapshot1.value[@"x"] doubleValue] == [snapshot2.value[@"x"] doubleValue])) {
        return NO;
    }
    if (!([snapshot1.value[@"y"] doubleValue] == [snapshot2.value[@"y"] doubleValue])) {
        return NO;
    }
    if (![snapshot1.value[@"transform"] isEqualToString:snapshot2.value[@"transform"]]) {
        return NO;
    }
    return YES;
    
}

#pragma mark - caption gestures

- (void)captionCancelPressedWhileTyping {
    self.editableCaptionTextView.text = @"";
    [self doneTyping];
}

- (void)cancelButtonPressed:(id)sender {
    [self.editableCaptionWrapperView removeFromSuperview];
    self.editableCaptionTextView = nil;
    [self toggleEditingCaption:NO];
    // remove caption and replace done/cancel buttons with text button
}

- (void)doneButtonPressed:(id)sender {
    // Send caption data to firebase
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
        self.cancelCaptionButton.hidden = NO;
        self.rajsBelovedDoneButton.hidden = NO;
//        self.textButton.hidden = YES;
        self.deleteButton.hidden = YES;
        self.shareButton.hidden = YES;
    } else {
        [self setGesturesEnabled:YES];
        
        self.serverCaptionWrapperView.hidden = NO;

        // could be prettier if i fade all of this
        self.cancelCaptionButton.hidden = YES;
        self.rajsBelovedDoneButton.hidden = YES;
//        self.textButton.hidden = NO;
        self.deleteButton.hidden = NO;
        self.shareButton.hidden = NO;
        
        
    }
}

- (BOOL)view:(UIView *)view isPositionedEqualTo:(UIView *)view2 {
    if (!(view && view2)) return NO; // Neither are nil
    if (!CGPointEqualToPoint(view.center, view2.center)) return NO; // Have same center
    if (!CGAffineTransformEqualToTransform(view.transform, view2.transform)) return NO; // Have same transform
    return YES;
}

- (void)commitCurrentCaption {
    if (self.editableCaptionTextView) {

        CGFloat vw = VIEW_WIDTH, vh = VIEW_HEIGHT;
        
        NSDictionary *eventData;
        
        NSString *oldText = self.serverCaptionTextView.text;
        NSString *newText = self.editableCaptionTextView.text;

        NSDictionary *textData = @{
                                   @"type": @"text",
                                   @"x":[NSNumber numberWithDouble: self.textFieldCenter.x/vw],
                                   @"y":[NSNumber numberWithDouble: self.textFieldCenter.y/vh],
                                   @"username":[YAUser currentUser].username,
                                   @"transform":NSStringFromCGAffineTransform(self.textFieldTransform),
                                   @"text":self.editableCaptionTextView.text
                                   };
       
//        if (![newText length]) {
//            // Caption Deleted
//            textData = nil;
//            if ([oldText length]) {
//                eventData = @{
//                              @"type":@"caption_deleted",
//                              @"username":[YAUser currentUser].username
//                              };
//            }
//        }
//        
//        
//        if ([newText length] && ![oldText length]) {
//            // Caption Created
//            eventData = @{
//                          @"type":@"caption_created",
//                          @"username":[YAUser currentUser].username,
//                          @"text":newText
//                          };
//        }
//        
//        if ([oldText length] && [newText length]) {
//            if ([oldText isEqualToString:newText] && ([self view:self.editableCaptionWrapperView isPositionedEqualTo:self.serverCaptionWrapperView])) {
//                // Nothing changed.
//                eventData = nil;
//            } else if (![oldText isEqualToString:newText]) {
//                // Changed text. In this case, dont care if they moved the caption in terms of event creation.
//                eventData = @{
//                              @"type":@"caption_change",
//                              @"username":[YAUser currentUser].username,
//                              @"text":newText
//                              };
//
//            } else {
//                // Caption repositioned but text is the same
//                eventData = @{
//                              @"type":@"caption_move",
//                              @"username":[YAUser currentUser].username
//                              };
//            }
//        }
        
        [self.editableCaptionWrapperView removeFromSuperview];
        self.editableCaptionWrapperView = nil;
        self.editableCaptionTextView = nil;
        
        [[[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAppendingPath:@"caption"] setValue:textData];
        
//        if (eventData) {
//            self.serverCaptionWrapperView.alpha = 0;
//            [[[[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAppendingPath:@"events"] childByAutoId] setValue:eventData];
//        }
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
                                         recognizer.view.center.y + translation.y);
    
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
//        [self.video rename:textView.text withFont:self.fontIndex];
//        [self updateControls];
//        
        [self doneTyping];
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
    [self doneTyping];
}

- (void)doneTyping {
//    [self.video rename:self.captionField.text withFont:self.fontIndex];
    [self removeGestureRecognizer:self.tapOutGestureRecognizer];
//    [self updateControls];
    
    [self.editableCaptionTextView resignFirstResponder];
    [self.captionBlurOverlay removeFromSuperview];
    
    if (![self.editableCaptionTextView.text length]) {
        [self cancelButtonPressed:nil];
    } else {
        [self moveTextViewBackToSpot];
    }
}

#pragma mark - Liking

- (void)likeButtonPressed {
//    NSString *likeCountSelf = self.likeCount.titleLabel.text;
//    NSNumberFormatter *f = [NSNumberFormatter new];
//    f.numberStyle = NSNumberFormatterDecimalStyle;
//    NSUInteger likeCountNumber = [[f numberFromString:likeCountSelf] integerValue];
//    if (!self.video.like) {
//        if (likeCountNumber == 0) {
//            self.likeCount.hidden = YES;
//            [self.likeCount setTitle:@"0"
//                            forState:UIControlStateNormal];
//        } else {
//            [self.likeCount setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)++likeCountNumber]
//                            forState:UIControlStateNormal];
//        }
//        [[YAServer sharedServer] likeVideo:self.video withCompletion:^(NSNumber* response, NSError *error) {
//            [self.likeCount setTitle:[NSString stringWithFormat:@"%@", response]
//                            forState:UIControlStateNormal];
//        }];
//        [[Mixpanel sharedInstance] track:@"Video liked"];
//    } else {
//        if (likeCountNumber <= 1) {
//            self.likeCount.hidden = YES;
//            [self.likeCount setTitle:@"0"
//                            forState:UIControlStateNormal];
//        } else {
//            [self.likeCount setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)--likeCountNumber]
//                            forState:UIControlStateNormal];
//        }
//        [[YAServer sharedServer] unLikeVideo:self.video withCompletion:^(NSNumber* response, NSError *error) {
//            [self.likeCount setTitle:[response integerValue] == 0 ? @"" : [NSString stringWithFormat:@"%@", response]
//                            forState:UIControlStateNormal];
//        }];
//        [[Mixpanel sharedInstance] track:@"Video unliked"];
//    }
//    
//    [[RLMRealm defaultRealm] beginWriteTransaction];
//    self.video.like = !self.video.like;
//    [[RLMRealm defaultRealm] commitWriteTransaction];
//    
//    [self animateButton:self.likeButton withImageName:self.video.like ? @"Liked" : @"Like" completion:nil];
}

//
//- (void)likeCountPressed {
//    
//    if(self.likesShown){
//        [self hideLikes];
//        self.likesShown = NO;
//        
//        [self removeGestureRecognizer:[self.gestureRecognizers lastObject]];
//    } else {
//        [self showLikes];
//        self.likesShown = YES;
//        
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideLikesTapOut:)];
//        [self addGestureRecognizer:tap];
//    }
//}

//- (void)hideLikesTapOut:(UIGestureRecognizer *) recognizer {
//    [self removeGestureRecognizer:recognizer];
//    [self hideLikes];
//    self.likesShown = NO;
//}

- (void)handleTap:(UITapGestureRecognizer *) recognizer {
    NSLog(@"tapped");
    if (self.editingCaption) return;
    if ([recognizer isEqual:self.likeDoubleTapRecognizer]) {
        [self addLike];
    } else if ([recognizer isEqual:self.captionTapRecognizer]){
        [self toggleEditingCaption:YES];
        CGPoint loc = [recognizer locationInView:self];
        [self beginEditableCaptionAtPoint:loc
                                initalText:@""
                           initalTransform:CGAffineTransformMakeScale(CAPTION_DEFAULT_SCALE, CAPTION_DEFAULT_SCALE)];
    }
}

- (void)addLike {
    
    NSDictionary *heartData = @{
                                @"type": @"comment",
                                @"username": [YAUser currentUser].username,
                                @"comment": @"😍"
                                };
    
    [[[[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAppendingPath:@"events"] childByAutoId] setValue:heartData];
    
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
//
//- (void)showLikes {
//    
//    CGFloat origin = self.likeCount.frame.origin.y;
//    CGFloat height = 24;
//    CGFloat width = 72;
//    
//    self.likeLabels = [[NSMutableArray alloc] init];
//    
//    for(YAContact *cntct in self.video.likers){
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.likeCount.frame.origin.x + self.likeCount.frame.size.width - width, origin + self.likeCount.frame.size.height/2, width, height)];
//        if (cntct.username.length) {
//            [label setText:cntct.username];
//        } else {
//            [label setText:cntct.name];
//        }
//        [label setTextAlignment:NSTextAlignmentRight];
//        [label setTextColor:[UIColor whiteColor]];
//        [label setFont:[UIFont fontWithName:BIG_FONT size:16]];
//        
//        label.layer.shadowColor = [[UIColor blackColor] CGColor];
//        label.layer.shadowRadius = 1.0f;
//        label.layer.shadowOpacity = 1.0;
//        label.layer.shadowOffset = CGSizeZero;
//        [label setAlpha:0.0];
//        
//        [self.likeLabels addObject:label];
//        [self addSubview:label];
//    }
//    
//    CGFloat xRadius = 500;
//    CGFloat yRadius = 3000;
//    
//    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
//        //
//        int i = 0;
//        
//        for(UILabel *label in self.likeLabels){
//            //            [UIView addKeyframeWithRelativeStartTime:(CGFloat) i / (CGFloat) [self.likeLabels count] relativeDuration:2.0f/(CGFloat)[self.likeLabels count] animations:^{
//            //
//            [label setAlpha:1.0];
//            //            [label setFrame:CGRectMake(self.likeCount.frame.origin.x + self.likeCount.frame.size.width - width, origin - (i+1)*(height + margin), width, height)];
//            CGFloat angle = (1.0f * M_PI / 180 * ((CGFloat) i + 1.0f));
//            
//            CGAffineTransform rotate = CGAffineTransformMakeRotation(angle);
//            //            CGAffineTransformMake
//            CGFloat translateX = xRadius - fabs(xRadius*cosf(angle));
//            CGFloat translateY = -fabs(yRadius*sinf(angle));
//            [label setTransform:CGAffineTransformTranslate(rotate, translateX, translateY)];
//            
//            i++;
//            
//        }
//    } completion:^(BOOL finished) {
//        //
//    }];
//}

//- (void)hideLikes {
//    int i = 0;
//    
//    for(UILabel *label in self.likeLabels){
//        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
//            //            [UIView addKeyframeWithRelativeStartTime:(CGFloat) i / (CGFloat) [self.likeLabels count] relativeDuration:2.0f/(CGFloat)[self.likeLabels count] animations:^{
//            //
//            [label setAlpha:0.0];
//            //            [label setFrame:CGRectMake(self.likeCount.frame.origin.x + self.likeCount.frame.size.width - width, origin - margin, width, height)];
//            [label setTransform:CGAffineTransformIdentity];
//            
//        } completion:^(BOOL finished) {
//            [label removeFromSuperview];
//        }];
//        i++;
//    }
//    
//}
//
#pragma mark - ETC

- (void)deleteButtonPressed {
    [self animateButton:self.deleteButton withImageName:nil completion:^{
        [YAUtils deleteVideo:self.video];
    }];
}

//- (void)addEvent:(FDataSnapshot *)event toCommentsSheet:(YACommentsOverlayView *)commentsSheet{
//    if ([event.value[@"type"] isEqualToString:@"comment"]) {
//        [commentsSheet addCommentWithUsername:event.value[@"username"] Title:event.value[@"text"]];
//
//    } else if ([event.value[@"type"] isEqualToString:@"caption_created"]) {
//        [commentsSheet addCaptionCreationWithUsername:event.value[@"username"] caption:event.value[@"text"]];
//    
//    } else if ([event.value[@"type"] isEqualToString:@"caption_change"]) {
//        [commentsSheet addRecaptionWithUsername:event.value[@"username"] newCaption:event.value[@"text"]];
//    
//    } else if ([event.value[@"type"] isEqualToString:@"caption_move"]) {
//        [commentsSheet addCaptionMoveWithUsername:event.value[@"username"]];
//    
//    } else if ([event.value[@"type"] isEqualToString:@"caption_deleted"]) {
//        [commentsSheet addCaptionDeletionWithUsername:event.value[@"username"]];
//    }
//}

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

- (void)updateControls {
    
   
    self.myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
    self.deleteButton.hidden = !self.myVideo;
    
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
    self.captionButton.hidden = !mp4Downloaded;
    self.shareButton.hidden = !mp4Downloaded;

    self.deleteButton.hidden = !mp4Downloaded && !self.myVideo;

//    [self.likeCount setTitle:self.video.likes ? [NSString stringWithFormat:@"%ld", (long)self.video.likes] : @""
//                    forState:UIControlStateNormal];
//
    self.events = [@[@{
                @"type":@"post",
                @"username":self.video.creator,
                @"timestamp":[[YAUser currentUser] formatDate:self.video.createdAt]
                    }] mutableCopy];
    [self.commentsTableView reloadData];
    [self clearFirebase];
    [self initFirebase];
    
    //get likers for video
    
    if(self.video.mp4Filename.length) {
        [self showProgress:NO];
    }
    
}

- (void)XButtonPressed {
    NSLog(@"pressed?");
    
    // close video here
    if([self.presentingVC isKindOfClass:[YASwipingViewController class]]){
        NSLog(@"is class?");
        [((YASwipingViewController *) self.presentingVC) dismissAnimated];
    }
}

- (void)shareButtonPressed {
    [self animateButton:self.shareButton withImageName:@"Share" completion:nil];
    NSString *caption = ![self.video.caption isEqualToString:@""] ? self.video.caption : @"Yaga";
    NSString *detailText = [NSString stringWithFormat:@"%@ — http://getyaga.com", caption];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = NSLocalizedString(@"Exporting", @"");
    hud.mode = MBProgressHUDModeIndeterminate;
    
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURL:[YAUtils urlFromFileName:self.video.mp4Filename]
                                                completion:^(NSURL *filePath, NSError *error) {
    if (error) {
        DLog(@"Error: can't add bumber");
    } else {
        
        NSURL *videoFile = filePath;
        YACopyVideoToClipboardActivity *copyActivity = [YACopyVideoToClipboardActivity new];
        UIActivityViewController *activityViewController =
        [[UIActivityViewController alloc] initWithActivityItems:@[detailText, videoFile]
                                          applicationActivities:@[copyActivity]];
        
        activityViewController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
        [(YASwipingViewController *)self.presentingVC presentViewController:activityViewController
                                        animated:YES
                                      completion:^{
                                          [hud hide:YES];
                                      }];
        
        [activityViewController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                if([activityType isEqualToString:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
                    NSString *message = completed ? NSLocalizedString(@"Video saved to camera roll", @"") : NSLocalizedString(@"Video failed to save to camera roll", @"");
                    [YAUtils showHudWithText:message];
                }
                else if ([activityType isEqualToString:@"yaga.copy.video"]) {
                     NSString *message = completed ? NSLocalizedString(@"Video copied to clipboard", @"") : NSLocalizedString(@"Video failed to copy to clipboard", @"");
                    [YAUtils showHudWithText:message];
                }
            
        }];
        
    }}];
}

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
    if(show && !self.uploadingView) {
        CGRect frame = self.deleteButton.frame;
        frame.origin.x -= self.deleteButton.frame.size.width;
        self.uploadingView = [[YAActivityView alloc] initWithFrame:frame];
        [self addSubview:self.uploadingView];
        [self.uploadingView startAnimating];
    }
    else {
        [self.uploadingView removeFromSuperview];
        self.uploadingView = nil;
    }
}

- (void)didUploadVideo:(NSNotification*)notif {
    if([self.video isEqual:notif.object]) {
        [self showUploadingProgress:NO];
    }
}


- (void)videoChanged:(NSNotification*)notif {
    if([notif.object isEqual:self.video] && !self.playerView.URL && self.shouldPreload && self.video.mp4Filename.length) {
        //setURL will remove playWhenReady flag, so saving it and using later
        BOOL playWhenReady = self.playerView.playWhenReady;
        [self prepareVideoForPlaying];
        self.playerView.playWhenReady = playWhenReady;
        
        [self updateControls];
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

#pragma mark - Observing input mode
- (void)inputModeChanged:(NSNotification*)sender {
    NSString *mode = self.editableCaptionTextView.textInputMode.primaryLanguage;
    //Adding additional "Done" button for emoji keyboard
    if (mode == nil) { //Appears to corespond to emoji
        if (!self.keyBoardAccessoryButton) {
            CGFloat buttonHeight = 40.f;
            CGFloat buttonWidth = 100.f;
            CGFloat buttonMargin = 5.f;
            CGFloat buttonLeftMargin = self.keyboardRect.size.width - buttonWidth - 5.f;
            self.keyBoardAccessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonLeftMargin,
                                                                                      self.keyboardRect.origin.y - buttonHeight - buttonMargin,
                                                                                      buttonWidth,
                                                                                      buttonHeight)];
            self.keyBoardAccessoryButton.layer.cornerRadius = 8.0f;
            [self.keyBoardAccessoryButton setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
            [self.keyBoardAccessoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.keyBoardAccessoryButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:18]];
            self.keyBoardAccessoryButton.layer.borderColor = [UIColor whiteColor].CGColor;
            self.keyBoardAccessoryButton.layer.borderWidth = 2.0f;
            self.keyBoardAccessoryButton.backgroundColor = PRIMARY_COLOR;
            [self.keyBoardAccessoryButton addTarget:self
                                             action:@selector(accessoryButtonTaped:)
                                   forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:self.keyBoardAccessoryButton];
        }
        self.keyBoardAccessoryButton.hidden = NO;
    }
    else
    {
        self.keyBoardAccessoryButton.hidden = YES;
    }
}

- (void)accessoryButtonTaped:(id)sender {
//    [self.video rename:self.captionField.text withFont:self.fontIndex];
    [self removeGestureRecognizer:self.tapOutGestureRecognizer];
    [self updateControls];
    
    [self.editableCaptionTextView resignFirstResponder];
    self.keyBoardAccessoryButton.hidden = YES;
}


@end

