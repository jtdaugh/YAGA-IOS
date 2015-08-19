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
#import "YAViewCountManager.h"
#import "RCounter.h"
#import "YAApplyCaptionView.h"

#import "YASharingView.h"

#define DOWN_MOVEMENT_TRESHHOLD 800.0f

static NSString *commentCellID = @"CommentCell";


@interface YAVideoPage ()  <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, YAVideoPlayerViewDelegate>

@property (nonatomic, strong) YAActivityView *activityView;

//overlay controls
@property (strong, nonatomic) UIButton *XButton;
@property (strong, nonatomic) UIButton *TButton;
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) RCounter *viewCounter;
@property (nonatomic, strong) UIImageView *viewCountImageView;
@property BOOL likesShown;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *heartButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *commentButton;

@property (nonatomic, strong) UIView *viewingAccessories;

@property (nonatomic, strong) UIButton *approveButton;
@property (nonatomic, strong) UIButton *rejectButton;

@property (nonatomic, strong) UIView *adminAccessories;

@property BOOL loading;
@property (strong, nonatomic) UIView *loader;
@property (nonatomic, strong) YAProgressView *progressView;
@property (nonatomic) CGRect keyboardRect;

@property (nonatomic, strong) UILabel *debugLabel;
@property NSUInteger fontIndex;

@property (strong, nonatomic) UITapGestureRecognizer *likeDoubleTapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *captionTapRecognizer;
@property (strong, nonatomic) UILongPressGestureRecognizer *hideGestureRecognizer;

@property (strong, nonatomic) CAGradientLayer *commentsViewMask;

@property (strong, nonatomic) UIView *overlay;

@property (strong, nonatomic) UIView *serverCaptionWrapperView;
@property (strong, nonatomic) UITextView *serverCaptionTextView;
@property (strong, nonatomic) FDataSnapshot *currentCaptionSnapshot;

@property (nonatomic, strong) NSMutableArray *events;

@property (nonatomic, strong) UIButton *textButton;
@property (nonatomic) BOOL editingCaption;

@property (nonatomic, strong) UIVisualEffectView *commentsBlurOverlay;

@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) BOOL previousKeyboardLocation;

@property (strong, nonatomic) UIView *commentsGradient;
@property (nonatomic, strong) UIView *commentsWrapperView;
@property (nonatomic, strong) UITableView *commentsTableView;
@property (nonatomic, strong) UITextField *commentsTextField;
@property (nonatomic, strong) UIView *commentsTextBoxView;
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

@property (nonatomic) CGFloat lastPlaybackProgress;

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
        _playerView.delegate = self;
        [_playerView setSmoothLoopingComposition:YES];
        [self addSubview:self.playerView];
        
        // So captions dont spread between videos.
        self.layer.masksToBounds = YES;
        
        self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self addSubview:self.overlay];
        
        self.viewingAccessories = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        self.adminAccessories = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];

        if(self.showAdminControls){
            [self.overlay addSubview:self.adminAccessories];
        } else {
            [self.overlay addSubview:self.viewingAccessories];
        }
        
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
        
        [self setBackgroundColor:[UIColor blackColor]];
        
        self.showBottomControls = YES;
    }
    return self;
}

#pragma mark - YAEventReceiver

- (void)videoWithServerId:(NSString *)serverId
                  localId:(NSString *)localId
       didReceiveNewEvent:(YAEvent *)event {
    if (!self.video.invalidated) {
        if ([serverId isEqualToString:self.video.serverId] || [localId isEqualToString:self.video.localId]) {
            [self.events insertObject:event atIndex:0];
            [self.commentsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        }
    }
}

- (void)videoWithServerId:(NSString *)serverId localId:(NSString *)localId didRemoveEvent:(YAEvent *)event {
    if (!self.video.invalidated) {
        if ([serverId isEqualToString:self.video.serverId] || [localId isEqualToString:self.video.localId]) {
            YAEvent *eventToRemove;
            NSInteger eventIndex = 0;
            for (YAEvent *videoEvent in self.events) {
                if ([videoEvent.key isEqualToString:event.key]) {
                    eventToRemove = videoEvent;
                    break;
                }
                eventIndex++;
            }
            if (eventToRemove) {
                [self.events removeObject:eventToRemove];
                [self.commentsTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:eventIndex inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)videoWithServerId:(NSString *)serverId
                  localId:(NSString *)localId
    receivedInitialEvents:(NSArray *)events {
    if (!self.video.invalidated) {
        if ([serverId isEqualToString:self.video.serverId] || [localId isEqualToString:self.video.localId]) {
            if ([events count]) {
                [self refreshWholeTableWithEventsArray:[events reversedArray]];
            }
        }
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

#pragma mark - YAVideoPlayerViewDelegate

- (void)playbackProgressChanged:(CGFloat)progress duration:(CGFloat)duration {
    if (progress < self.lastPlaybackProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[YAViewCountManager sharedManager] addViewToVideoWithId:self.video.serverId groupId:self.video.group.serverId user:self.video.creator];
        });
    }
    self.lastPlaybackProgress = progress;
}

#pragma mark - YAViewCountDelegate

- (void)videoUpdatedWithMyViewCount:(NSUInteger)myViewCount otherViewCount:(NSUInteger)othersViewCount {
    if ((myViewCount + othersViewCount) > 0) {
        if (self.viewCounter.hidden) {
            self.viewCounter.alpha = 0;
            self.viewCountImageView.alpha = 0;
            self.viewCounter.hidden = NO;
            self.viewCountImageView.hidden = NO;
            [UIView animateWithDuration:0.5f animations:^{
                self.viewCounter.alpha = 1;
                self.viewCountImageView.alpha = 0.7;
            }];
        }
        [self.viewCounter updateValue:(int)(othersViewCount + myViewCount) animate:YES];
    } else {
        self.viewCounter.hidden = YES;
        self.viewCountImageView.hidden = YES;
    }
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
    self.playerView.player.volume = PLAYER_TURNED_DOWN_AUDIO;
    self.commentsTapOutRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentsTapOut:)];
    [self addGestureRecognizer:self.commentsTapOutRecognizer];
    [self moveControls:notification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if (self.editingCaption) return;

    [self setGesturesEnabled:YES];
    
    self.playerView.player.volume = 1.0;

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
    CGRect commentsFrame = self.commentsTableView.frame;
    CGRect commentsTextBoxFrame = self.commentsTextBoxView.frame;
    
    self.commentsBlurOverlay.hidden = !up;
    
    if (up) {
        wrapperFrame.size.height = VIEW_HEIGHT - kbHeight;
        wrapperFrame.origin.y = 0;
        commentsFrame.size.height = VIEW_HEIGHT - kbHeight - commentsTextBoxFrame.size.height;
        commentsTextBoxFrame.origin.y = CGRectGetHeight(commentsFrame);
        gradientFrame.origin.y -= self.previousKeyboardLocation ? delta : kbHeight;
    } else {
        // just set the view back to the bottom
        wrapperFrame.size.height = VIEW_HEIGHT*COMMENTS_HEIGHT_PROPORTION;
        wrapperFrame.origin.y = VIEW_HEIGHT - COMMENTS_BOTTOM_MARGIN - wrapperFrame.size.height;
        gradientFrame.origin.y = VIEW_HEIGHT - gradientFrame.size.height;
        commentsFrame.size.height = VIEW_HEIGHT*COMMENTS_HEIGHT_PROPORTION;
        commentsTextBoxFrame.origin.y =  VIEW_HEIGHT*COMMENTS_HEIGHT_PROPORTION;
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
    
    self.commentsWrapperView.layer.mask = up ? nil : self.commentsViewMask;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.commentsWrapperView.frame = wrapperFrame;
                         self.commentsTextBoxView.frame = commentsTextBoxFrame;
                         self.commentsTableView.frame = commentsFrame;
                         self.commentsGradient.frame = gradientFrame;
                         self.commentsTextBoxView.alpha = up ? 1.0 : 0.0;
                         if (up) {
                             self.commentsTableView.contentOffset = CGPointZero;
                         }
                     }
                     completion:^(BOOL finished){
                         if ([self.events count] && !up) {
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
        self.lastPlaybackProgress = CGFLOAT_MAX; // So that any initial player progress adds viewCount
        
//        self.debugLabel.text = video.serverId;
        
        [self updateControls];
        
        if(!shouldPreload) {
            self.playerView.frame = CGRectZero;
            [self showLoading:YES];
        }
        self.viewCounter.hidden = YES;
        self.viewCountImageView.hidden = YES;
        NSArray *events = [[YAEventManager sharedManager] getEventsForVideoWithServerId:video.serverId localId:video.localId serverIdStatus:[YAVideo serverIdStatusForVideo:video]];
        [self refreshWholeTableWithEventsArray:[events reversedArray]];
    }
    
    self.shouldPreload = shouldPreload;
    
    [self addFullscreenJpgPreview];
    
    if(shouldPreload) {
        [self prepareVideoForPlaying];
    }
    
    [self updateUploadingProgress];
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
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
    [self.viewingAccessories addSubview:self.commentsGradient];
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    _commentsBlurOverlay = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    self.commentsBlurOverlay.frame = self.bounds;
    self.commentsBlurOverlay.hidden = YES;
    [self.viewingAccessories addSubview:self.commentsBlurOverlay];
    
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
    
    CGSize viewCountSize = CGSizeMake(200, 23);
    
    
    UIView *viewCountView = [[UIView alloc] initWithFrame:CGRectMake((VIEW_WIDTH-viewCountSize.width)/2, VIEW_HEIGHT - viewCountSize.height - 11, viewCountSize.width, viewCountSize.height)];
    viewCountView.backgroundColor = [UIColor clearColor];
    [self.viewingAccessories addSubview:viewCountView];
    
    self.viewCounter = [[RCounter alloc] initWithValue:0 origin:CGPointMake(viewCountSize.width/2, 0)];
                        
    self.viewCounter.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.viewCounter.layer.shadowRadius = 0.0f;
    self.viewCounter.layer.shadowOpacity = 1.0;
    self.viewCounter.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    [viewCountView addSubview:self.viewCounter];

    CGSize viewCountImgSize = CGSizeMake(25, 20);
    self.viewCountImageView = [[UIImageView alloc]initWithFrame:CGRectMake(viewCountSize.width/2 - 1 - viewCountImgSize.width,
                                                                           1,
                                                                           viewCountImgSize.width, viewCountImgSize.height)];
    self.viewCountImageView.image = [UIImage imageNamed:@"Views"];
    self.viewCountImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.viewCountImageView.layer.shadowRadius = 0.0f;
    self.viewCountImageView.layer.shadowOpacity = 1.0;
    self.viewCountImageView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    [viewCountView addSubview:self.viewCountImageView];
    
    //    CGFloat tSize = CAPTION_FONT_SIZE;

    self.XButton = [YAUtils circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(30, 30)];
    self.XButton.transform = CGAffineTransformMakeScale(0.85, 0.85);
    self.XButton.alpha = 0.7;
    [self.XButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.XButton];
    
    self.TButton = [YAUtils circleButtonWithImage:@"Text" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding, padding + buttonRadius)];
    self.TButton.transform = CGAffineTransformMakeScale(0.85, 0.85);
    self.TButton.alpha = 0.7;
    [self.TButton addTarget:self action:@selector(captionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.TButton];
    
    CGFloat approveButtonWidth = VIEW_WIDTH * .4;
    CGFloat approveButtonHeight = VIEW_HEIGHT * .1;
    CGFloat approveButtonMargin = (VIEW_WIDTH - approveButtonWidth*2)/3;
    
    self.approveButton = [[UIButton alloc] initWithFrame:CGRectMake(approveButtonMargin, VIEW_HEIGHT - approveButtonHeight - approveButtonMargin, approveButtonWidth, approveButtonHeight)];
    [self.approveButton setTitle:@"Approve" forState:UIControlStateNormal];
    [self.approveButton addTarget:self action:@selector(approvePressed) forControlEvents:UIControlEventTouchUpInside];
    self.approveButton.backgroundColor = [PRIMARY_COLOR colorWithAlphaComponent:0.5];;
    [self.approveButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:22]];
//    [self.approveButton.titleLabel setTextColor:PRIMARY_COLOR];
    self.approveButton.layer.masksToBounds = YES;
    self.approveButton.layer.cornerRadius = approveButtonHeight/2;
    self.approveButton.layer.borderWidth = 5.0f;
    self.approveButton.layer.borderColor = PRIMARY_COLOR.CGColor;
    [self.adminAccessories addSubview:self.approveButton];
    
    self.rejectButton = [[UIButton alloc] initWithFrame:CGRectMake(approveButtonMargin*2 + approveButtonWidth, VIEW_HEIGHT - approveButtonHeight - approveButtonMargin, approveButtonWidth, approveButtonHeight)];
    [self.rejectButton setTitle:@"Reject" forState:UIControlStateNormal];
    [self.rejectButton addTarget:self action:@selector(rejectPressed) forControlEvents:UIControlEventTouchUpInside];
    self.rejectButton.backgroundColor = [SECONDARY_COLOR colorWithAlphaComponent:0.5];
    [self.rejectButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:22]];
//    [self.rejectButton.titleLabel setTextColor:SECONDARY_COLOR];
    self.rejectButton.layer.masksToBounds = YES;
    self.rejectButton.layer.cornerRadius = approveButtonHeight/2;
    self.rejectButton.layer.borderWidth = 5.0f;
    self.rejectButton.layer.borderColor = SECONDARY_COLOR.CGColor;
    [self.adminAccessories addSubview:self.rejectButton];

    self.moreButton = [YAUtils circleButtonWithImage:@"Share" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding,
                                                                                                 VIEW_HEIGHT - buttonRadius - padding)];
    [self.moreButton addTarget:self action:@selector(moreButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewingAccessories addSubview:self.moreButton];
//    self.shareButton.layer.zPosition = 100;
    
//    self.deleteButton = [self circleButtonWithImage:@"Delete" diameter:buttonRadius*2 center:CGPointMake(padding + buttonRadius, padding*2 + buttonRadius)];
//    [self.deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.overlay addSubview:self.deleteButton];
//    self.deleteButton.layer.zPosition = 100;
    
    self.commentButton = [YAUtils circleButtonWithImage:@"comment" diameter:buttonRadius*2 center:CGPointMake(buttonRadius + padding, VIEW_HEIGHT - buttonRadius - padding)];
    [self.commentButton addTarget:self action:@selector(commentButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.viewingAccessories addSubview:self.commentButton];

    self.heartButton = [YAUtils circleButtonWithImage:@"Like" diameter:buttonRadius*2 center:CGPointMake(buttonRadius*3 + padding*3, VIEW_HEIGHT - buttonRadius - padding)];
    [self.heartButton setBackgroundImage:[UIImage imageNamed:@"Liked"] forState:UIControlStateHighlighted];
    [self.heartButton addTarget:self action:@selector(addLike) forControlEvents:UIControlEventTouchUpInside];
    [self.viewingAccessories addSubview:self.heartButton];
    
    [self setupCommentsContainer];

    const CGFloat radius = 40;
    self.progressView = [[YAProgressView alloc] initWithFrame:self.bounds];
    self.progressView.radius = radius;
    UIView *progressBkgView = [[UIView alloc] initWithFrame:self.bounds];
    progressBkgView.backgroundColor = [UIColor clearColor];
    self.progressView.backgroundView = progressBkgView;
    
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.progressView];
    
    UIButton *progressXButton = [YAUtils circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(30, 30)];
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
    
    [self.overlay bringSubviewToFront:self.moreButton];
    [self.overlay bringSubviewToFront:self.commentButton];
    [self.overlay bringSubviewToFront:self.heartButton];
    
    [self.overlay setAlpha:0.0];
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        [self.overlay setAlpha:1.0];
    } completion:^(BOOL finished) {
        //
    }];

}

- (void)approvePressed {
//    void (^success)() = ^{
//        UILabel *tempApproveLabel = [UILabel new];
//        tempApproveLabel.font = [UIFont systemFontOfSize:100];
//        tempApproveLabel.text = @"✓";
//        [tempApproveLabel sizeToFit];
//        tempApproveLabel.center = [self.approveButton.superview convertPoint:self.approveButton.center toView:self];
//        
//        tempApproveLabel.textColor = [self.approveButton.backgroundColor colorWithAlphaComponent:1.0];
//        [self addSubview:tempApproveLabel];
//        [UIView animateWithDuration:0.3 animations:^{
//            tempApproveLabel.transform = CGAffineTransformMakeScale(8, 8);
//            // animate to center
//            tempApproveLabel.center = CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT/2);
//            tempApproveLabel.alpha = 0.1;
//        } completion:^(BOOL finished) {
//            [tempApproveLabel removeFromSuperview];
//            [self.presentingVC currentVideoRemovedFromList];
//        }];
//    };

//    MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:@""]
    MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:@"Approving video..."];
    [[YAServer sharedServer] approveVideo:self.video withCompletion:^(id response, NSError *error) {
        if (error) {
            DLog(@"Approve Video failed with error: %@", error);
            [hud hide:NO];
            [YAUtils showHudWithText:@"Couldn't approve video.\nTry again later"];
            
        } else {
            DLog(@"Approve Video success");
            [hud hide:NO];
            [YAUtils showHudWithText:@"Video approved"];
            [self.presentingVC currentVideoRemovedFromList];
        }
    }];
    
    
}

- (void)rejectPressed {
    MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:@"Rejecting video..."];
    [[YAServer sharedServer] rejectVideo:self.video withCompletion:^(id response, NSError *error) {
        if (error) {
            [hud hide:NO];
            [YAUtils showHudWithText:@"Couldn't reject video.\nTry again later"];
            DLog(@"Reject Video failed with error: %@", error);
        } else {
            [hud hide:NO];
            [YAUtils showHudWithText:@"Video rejected"];
            [self.presentingVC currentVideoRemovedFromList];

            DLog(@"Reject Video success");
            // SHOW SUCCESSFUL REJECT ANIMATION
        }
    }];
//    
//    UILabel *tempRejectLabel = [UILabel new];
//    tempRejectLabel.font = [UIFont systemFontOfSize:100];
//    tempRejectLabel.text = @"x";
//    [tempRejectLabel sizeToFit];
//    tempRejectLabel.center = [self.rejectButton.superview convertPoint:self.rejectButton.center toView:self];
//    tempRejectLabel.textColor = [self.rejectButton.backgroundColor colorWithAlphaComponent:1.0];
//    [self addSubview:tempRejectLabel];
//    [UIView animateWithDuration:0.3 animations:^{
//        tempRejectLabel.transform = CGAffineTransformMakeScale(8, 8);
//        // animate toward opposite top corner
////        tempRejectLabel.center = CGPointMake(tempRejectLabel.center.x > VIEW_WIDTH/2 ? 0 : VIEW_WIDTH, 0);
//        tempRejectLabel.center = CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT/2);
//        tempRejectLabel.alpha = 0.1;
//    } completion:^(BOOL finished) {
//        [tempRejectLabel removeFromSuperview];
//    }];
}

#pragma mark - Comments Table View

- (void)setupCommentsContainer {
    CGFloat height = VIEW_HEIGHT*COMMENTS_HEIGHT_PROPORTION;
    self.commentsWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - COMMENTS_BOTTOM_MARGIN - height, VIEW_WIDTH, height)];
    self.commentsTableView = [[UITableView alloc] initWithFrame:CGRectMake(COMMENTS_SIDE_MARGIN, 0, VIEW_WIDTH - (2*COMMENTS_SIDE_MARGIN), height)];
    self.commentsTableView.transform = CGAffineTransformMakeRotation(-M_PI);

    self.commentsTableView.backgroundColor = [UIColor clearColor];
    [self.commentsTableView registerClass:[YAEventCell class] forCellReuseIdentifier:commentCellID];
    
    _commentsViewMask = [CAGradientLayer layer];
    CGRect maskFrame = self.commentsWrapperView.bounds;
    maskFrame.size.height += COMMENTS_TEXT_FIELD_HEIGHT;
    self.commentsViewMask.frame = maskFrame;
    self.commentsViewMask.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[UIColor whiteColor].CGColor, nil];
    self.commentsViewMask.startPoint = CGPointMake(0.5f, 0.0f);
    self.commentsViewMask.endPoint = CGPointMake(0.5f, 0.22f);
    self.commentsWrapperView.layer.mask = self.commentsViewMask;
    
    self.commentsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.commentsTableView.allowsSelection = NO;
    self.commentsTableView.showsVerticalScrollIndicator = NO;
    self.commentsTableView.contentInset = UIEdgeInsetsMake(0, 0, 30, 0);
    self.commentsTableView.delegate = self;
    self.commentsTableView.dataSource = self;
    
    UILabel *leftUsernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    leftUsernameLabel.font = [UIFont boldSystemFontOfSize:COMMENTS_FONT_SIZE];
    leftUsernameLabel.text = [NSString stringWithFormat:@"%@", [YAUser currentUser].username];
    leftUsernameLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    leftUsernameLabel.shadowOffset = CGSizeMake(0.5, 0.5);
    leftUsernameLabel.userInteractionEnabled = NO;
    leftUsernameLabel.textColor = PRIMARY_COLOR;
    [leftUsernameLabel sizeToFit];
    CGRect usernameFrame = leftUsernameLabel.frame;
    usernameFrame.origin.x = COMMENTS_SIDE_MARGIN;
    usernameFrame.origin.y = (COMMENTS_TEXT_FIELD_HEIGHT - usernameFrame.size.height)/2;
    leftUsernameLabel.frame = usernameFrame;

    self.commentsTextBoxView = [[UIView alloc] initWithFrame:CGRectMake(0, height, VIEW_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    self.commentsTextBoxView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    [self.commentsTextBoxView addSubview:leftUsernameLabel];
    [self.commentsWrapperView addSubview:self.commentsTextBoxView];
    
    CGFloat textFieldLeftInset = 3;
    
    self.commentsTextField = [[UITextField alloc] initWithFrame:CGRectMake(leftUsernameLabel.frame.size.width + COMMENTS_SIDE_MARGIN + (COMMENTS_SPACE_AFTER_USERNAME - textFieldLeftInset),
                                                                           0,
                                                                           VIEW_WIDTH-COMMENTS_SEND_WIDTH - leftUsernameLabel.frame.size.width - (COMMENTS_SPACE_AFTER_USERNAME - textFieldLeftInset),
                                                                           COMMENTS_TEXT_FIELD_HEIGHT)];
    self.commentsTextField.autocorrectionType = UITextAutocorrectionTypeYes;
    self.commentsTextField.returnKeyType = UIReturnKeySend;
    self.commentsTextField.backgroundColor = [UIColor clearColor];
    
    self.commentsTextField.textColor = [UIColor whiteColor];
    self.commentsTextField.font = [UIFont systemFontOfSize:COMMENTS_FONT_SIZE];
    self.commentsTextField.layer.shadowColor = [UIColor blackColor].CGColor;
    self.commentsTextField.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    self.commentsTextField.layer.shadowOpacity = 1.0;
    self.commentsTextField.layer.shadowRadius = 0.0f;
    [self.commentsTextBoxView addSubview:self.commentsTextField];
    self.commentsTextField.delegate = self;
    
    self.commentsSendButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - COMMENTS_SEND_WIDTH, 0, COMMENTS_SEND_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    [self.commentsSendButton addTarget:self action:@selector(commentsSendPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.commentsSendButton setBackgroundImage:[UIImage imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:1.f]] forState:UIControlStateNormal];
    [self.commentsSendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.commentsSendButton setTitle:@"Send" forState:UIControlStateNormal];
    self.commentsSendButton.enabled = NO;
    [self.commentsTextBoxView addSubview:self.commentsSendButton];

    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - COMMENTS_SEND_WIDTH, 0, COMMENTS_SEND_WIDTH, COMMENTS_TEXT_FIELD_HEIGHT)];
    [self.likeButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.likeButton addTarget:self action:@selector(addLike) forControlEvents:UIControlEventTouchUpInside];
    [self.likeButton setBackgroundImage:[UIImage imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:1.f]] forState:UIControlStateNormal];
    [self.likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.likeButton setImage:[UIImage imageNamed:@"Liked"] forState:UIControlStateNormal];
    [self.likeButton setImage:[UIImage imageNamed:@"Liked"] forState:UIControlStateNormal];
//    [self.commentsTextBoxView addSubview:self.likeButton];
    
    [self.commentsWrapperView addSubview:self.commentsTableView];
    [self.commentsWrapperView addSubview:self.commentsTextBoxView];
    self.commentsWrapperView.layer.masksToBounds = YES;
    [self.viewingAccessories addSubview:self.commentsWrapperView];
    
}

- (void)commentsSendPressed:(id)sender {
    NSString *text = self.commentsTextField.text;
    if ([text length]) {
        // post the comment
        YAEvent *event = [YAEvent new];
        event.eventType = YAEventTypeComment;
        event.comment = text;
        event.username = [YAUser currentUser].username;
        [[YAEventManager sharedManager] addEvent:event toVideoWithServerId:self.video.serverId localId:self.video.localId serverIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
        
        self.commentsTextField.text = @"";
//        self.commentsSendButton.hidden = YES;
//        self.likeButton.hidden = NO;
//        [self.commentsTextField resignFirstResponder]; // do we want to hide the keyboard after each comment?
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *replaced = [textField.text stringByReplacingCharactersInRange:range withString:string];
    self.commentsSendButton.enabled = [replaced length];
//    self.commentsSendButton.hidden = ![replaced length];
//    self.likeButton.hidden = [replaced length];
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YAEventCell *cell = [tableView dequeueReusableCellWithIdentifier:commentCellID forIndexPath:indexPath];
    cell.containingVideoPage = self;
    cell.transform = cell.transform = CGAffineTransformMakeRotation(M_PI);
    
    YAEvent *event = self.events[indexPath.row];
    [cell configureCellWithEvent:event];

    if (event.eventType == YAEventTypePost) {
        [cell setVideoState:self.uploadInProgress ? YAEventCellVideoStateUploading : (self.video.pending ? YAEventCellVideoStateUnapproved : YAEventCellVideoStateApproved)];
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

// initial adding of caption. modifications will instead call -updateCaptionFromSnapshot
- (void)insertCaption {
    UIView *textWrapper = [[UIView alloc] initWithFrame:CGRectInfinite];
    UITextView *textView = [YAApplyCaptionView textViewWithCaptionAttributes];
    textView.delegate = self;
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


//- (void)textButtonPressed:(id)sender {
//    [self addCaptionAtPoint:CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT/2)];
//    [self toggleEditingCaption:YES];
//}

- (void)setGesturesEnabled:(BOOL)enabled {
    if ([self.video isInvalidated]) {
        self.hideGestureRecognizer.enabled = enabled;
        self.captionTapRecognizer.enabled = NO;
        self.likeDoubleTapRecognizer.enabled = NO;
        if (enabled) {
            [self.presentingVC restoreAllGestures:self];
        } else {
            [self.presentingVC suspendAllGestures:self];
        }
    } else {
        self.hideGestureRecognizer.enabled = enabled;
        self.captionTapRecognizer.enabled = enabled;
        self.likeDoubleTapRecognizer.enabled = enabled;
        if (enabled) {
            [self.presentingVC restoreAllGestures:self];
        } else {
            [self.presentingVC suspendAllGestures:self];
        }
    }
}

- (void)toggleEditingCaption:(BOOL)editing {
    if (!self.video.group) {
        // Toggle sharing view and caption editing for unposted video state
        self.sharingView.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.sharingView.alpha = editing ? 0.0 : 1.0;
        } completion:^(BOOL finished) {
            self.sharingView.hidden = editing;
        }];
    }
    
    self.editingCaption = editing;
    if (editing) {
        [self setGesturesEnabled:NO];
        self.serverCaptionWrapperView.hidden = YES;
//        self.textButton.hidden = YES;
        self.deleteButton.hidden = YES;
        self.moreButton.hidden = YES;
        self.commentsWrapperView.hidden = YES;
        self.XButton.hidden = YES;
        self.commentButton.hidden = YES;
        self.heartButton.hidden = YES;
        self.viewCounter.superview.alpha = 0.0;
        self.viewCountImageView.alpha = 0.0;
    } else {
        [self setGesturesEnabled:YES];
        
        self.serverCaptionWrapperView.hidden = NO;

        // could be prettier if i fade all of this
//        self.textButton.hidden = NO;
        self.deleteButton.hidden = NO;
        self.moreButton.hidden = !self.showBottomControls;
        self.commentsWrapperView.hidden = !self.showBottomControls;
        self.XButton.hidden = NO;
        
        self.commentButton.hidden = !self.showBottomControls;
        self.heartButton.hidden = !self.showBottomControls;
        self.viewCounter.superview.alpha = 1.0;
        self.viewCountImageView.alpha = 1.0;
    }
}

- (BOOL)view:(UIView *)view isPositionedEqualTo:(UIView *)view2 {
    if (!(view && view2)) return NO; // Neither are nil
    if (!CGPointEqualToPoint(view.center, view2.center)) return NO; // Have same center
    if (!CGAffineTransformEqualToTransform(view.transform, view2.transform)) return NO; // Have same transform
    return YES;
}

- (void)beginEditableCaptionAtPoint:(CGPoint)point initalText:(NSString *)text initalTransform:(CGAffineTransform)transform {
    YAApplyCaptionView *applyCaptionView = [[YAApplyCaptionView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT) captionPoint:point initialText:text initialTransform:transform];
    
    __weak YAApplyCaptionView *weakApplyCaptionView = applyCaptionView;
    
    applyCaptionView.completionHandler = ^(BOOL completed, UIView *captionView, UITextView *captionTextView, NSString *text, CGFloat x, CGFloat y, CGFloat scale, CGFloat rotation){
        self.serverCaptionWrapperView = captionView;
        self.serverCaptionTextView = captionTextView;
        self.serverCaptionTextView.editable = NO;
        [self.overlay addSubview:self.serverCaptionWrapperView];
        [self toggleEditingCaption:NO];
        
        if (completed) {
            [self.video updateCaption:text withXPosition:x yPosition:y scale:scale rotation:rotation];
        }
        
        [weakApplyCaptionView removeFromSuperview];
    };
    
    [self addSubview:applyCaptionView];
}

- (void)handleTap:(UITapGestureRecognizer *) recognizer {
    if (self.editingCaption) return;
    if ([recognizer isEqual:self.likeDoubleTapRecognizer]) {
        [self addLike];
    } else if ([recognizer isEqual:self.captionTapRecognizer] ||
               [recognizer isEqual:self.sharingView.crosspostTapOutRecognizer]) {
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
//    if(self.video.group){
//        
//    }
    if (self.video.group) {
        [self collapseCrosspost];
    }
    
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
    event.likeCount = @(1);
    event.username = [YAUser currentUser].username;
    
    BOOL userHasLiked = NO;
    for (YAEvent *videoEvent in self.events) {
        if ([videoEvent.username isEqualToString:[YAUser currentUser].username] && videoEvent.eventType == YAEventTypeLike) {
            userHasLiked = YES;
            [[YAEventManager sharedManager] removeEvent:videoEvent toVideoWithServerId:self.video.serverId localId:self.video.localId serverIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
            event = videoEvent;
            event.likeCount = @([event.likeCount integerValue] + 1);
            break;
        }
    }
    
    [[YAEventManager sharedManager] addEvent:event toVideoWithServerId:self.video.serverId localId:self.video.localId serverIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
    
    // Scroll to bottom
    [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)hideHold:(UILongPressGestureRecognizer *) recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan){
        [UIView animateWithDuration:0.2 animations:^{
            [self.overlay setAlpha:0.0];
        }];
        
//        self.playerView.player.rate = 0.5;
        
    } else if(recognizer.state == UIGestureRecognizerStateEnded){
        [UIView animateWithDuration:0.2 animations:^{
            //
            [self.overlay setAlpha:1.0];
        }];
//        self.playerView.player.rate = 1.0;
    }
}

#pragma mark - ETC

- (void)commentButtonPressed {
    // Set the content offset to make the table view frame animation less glitchy
    [self.commentsTableView setContentOffset:CGPointMake(0, self.commentsTableView.contentSize.height) animated:NO];
    
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
    
    self.TButton.hidden = [self.video.caption length] != 0;
    
    if ([self.video.caption length]) {
         [self insertCaption];
    } else if (self.myVideo) {
        if (![self.captionTapRecognizer.view isEqual:self]) {
#warning COMMENTED JUST FOR TESTING. uncomment.
//            [self addGestureRecognizer:self.captionTapRecognizer];
        }
    }
}

- (void)updateControls {
    DLog(@"update controls");
   
    self.myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
    self.deleteButton.hidden = !self.myVideo;
//    self.moreButton.hidden = !self.myVideo;

    [self initializeCaption];
    
    BOOL mp4Downloaded = [self.video.mp4Filename length] > 0;

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
    self.heartButton.enabled = mp4Downloaded;
    self.moreButton.enabled = mp4Downloaded;

    [self showProgress:!mp4Downloaded];
    
}

- (void)closeButtonPressed:(id)sender {
    // close video here
    [self closeAnimated];
}

- (void)closeAnimated {
    [self.commentsTextField resignFirstResponder];
    [self.presentingVC dismissAnimated];
}

- (void)moreButtonPressed:(id)sender {
    
    [self shareButtonPressed:nil];
    
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"✌🏾"
//                                                             delegate:self
//                                                    cancelButtonTitle:@"Cancel"
//                                               destructiveButtonTitle:nil
//                                                    otherButtonTitles:@"Post to other groups", @"Share", @"Add Caption", @"Save to Camera Roll", @"Delete", nil];
//    actionSheet.destructiveButtonIndex = 4;
//    actionSheet.cancelButtonIndex = 5;
//    [actionSheet showInView:self];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    DLog(@"button index: %lu", buttonIndex);
    switch (buttonIndex) {
        case 0: {
            // Post to other groups
            [self shareButtonPressed:nil];
            break;
        } case 1: {
            // export and share
            [self externalShareButtonPressed];
            break;
        } case 2: {
            // Add Caption
            [self captionButtonPressed];
            break;
        } case 3: {
            // save to camera roll
            [self saveToCameraRollPressed];
            break;
        } case 4: {
            // delete
            [YAUtils confirmDeleteVideo:self.video withConfirmationBlock:^{
                if(self.video.realm)
                    [self.video removeFromGroupAndStreamsWithCompletion:nil removeFromServer:self.video.group != nil];
                else
                    [self closeAnimated];
            }];
            
            break;
        } default: {
            DLog(@"no switch case for button with index: %lu", (unsigned long)buttonIndex);
        }
    }
}


# pragma saving stuff
- (void)externalShareButtonPressed {
    //    [self animateButton:self.shareButton withImageName:@"Share" completion:nil];
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
                                                        //            YACopyVideoToClipboardActivity *copyActivity = [YACopyVideoToClipboardActivity new];
                                                        UIActivityViewController *activityViewController =
                                                        [[UIActivityViewController alloc] initWithActivityItems:@[detailText, videoFile]
                                                                                          applicationActivities:@[]];
                                                        
                                                        //        activityViewController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
                                                        
                                                        
                                                        YASwipingViewController *presentingVC = (YASwipingViewController *) self.presentingVC;
                                                        [presentingVC presentViewController:activityViewController
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
                                                            if(completed){
//                                                                [self.page collapseCrosspost];
                                                            }
                                                        }];
                                                    }
                                                }];
}


#pragma mark - Sharing
- (void)saveToCameraRollPressed {
    /*
     if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
     UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
     }
     */
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = NSLocalizedString(@"Saving", @"");
    hud.mode = MBProgressHUDModeIndeterminate;
    
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURL:[YAUtils urlFromFileName:self.video.mp4Filename]
                                                completion:^(NSURL *filePath, NSError *error) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                                        
                                                        [hud hide:YES];
                                                        [self collapseCrosspost];
                                                        //Your code goes in here
                                                        DLog(@"Main Thread Code");
                                                        
                                                    }];
                                                    if (error) {
                                                        DLog(@"Error: can't add bumber");
                                                    } else {
                                                        
                                                        if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([filePath path])) {
                                                            UISaveVideoAtPathToSavedPhotosAlbum([filePath path], self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                                                        }
                                                        
                                                    }
                                                }];
}

- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        NSString *message = @"Video Saving Failed";
        [YAUtils showHudWithText:message];
    } else {
        NSString *message = @"Saved! ✌️";
        [YAUtils showHudWithText:message];
    }
}

- (void)shareButtonPressed:(id)sender {
    DLog(@"two thirds: %f", VIEW_HEIGHT * 2 / 3);
    self.sharingView = [[YASharingView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT) video:self.video];
    self.sharingView.page = self;
    [self setGesturesEnabled:NO];
    if (!self.video.group) {
        [self.presentingVC restoreAllGestures:self];
    }
    
    [self addSubview:self.sharingView];
    
    [self.sharingView setTransform:CGAffineTransformMakeTranslation(0, VIEW_HEIGHT/2)];

    [UIView animateWithDuration:0.2 animations:^{
        self.viewCounter.superview.alpha = 0.0;
        self.commentsWrapperView.alpha = 0.0;
        self.commentButton.alpha = 0.0;
        self.heartButton.alpha = 0.0;
        self.moreButton.alpha = 0.0;
        self.XButton.alpha = 0.0;
        [self.sharingView setTransform:CGAffineTransformIdentity];
    } completion:^(BOOL finished) {
        [self.sharingView setTopButtonsHidden:NO animated:YES];
    }];
    
    SEL target = self.video.group ? @selector(doneCrosspostingTapOut:) : @selector(handleTap:);
    [self.sharingView.crosspostTapOutRecognizer addTarget:self action:target];
}

- (void)collapseCrosspost {
    DLog(@"collapsing...");
    [self setGesturesEnabled:YES];
    [self.sharingView setTopButtonsHidden:YES animated:NO];

    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        //
        self.viewCounter.superview.alpha = 1.0;
//        self.commentsGradient.frame = gradientFrame;
        self.commentsWrapperView.alpha = 1.0;
        self.commentButton.alpha = 1.0;
        self.heartButton.alpha = 1.0;
        self.moreButton.alpha = 1.0;
        self.XButton.alpha = 1.0;
        [self.sharingView setTransform:CGAffineTransformMakeTranslation(0, self.sharingView.frame.size.height)];
    } completion:^(BOOL finished) {
        //
        [self.sharingView removeFromSuperview];
        self.sharingView = nil;

    }];
}

- (void)doneCrosspostingTapOut:(UITapGestureRecognizer *)recognizer {
    DLog(@"rec");
    [self collapseCrosspost];
}

#pragma mark - UITableView delegate methods (groups list)


#pragma mark - YAProgressView
- (void)downloadDidStart:(NSNotification*)notif {
    AFDownloadRequestOperation *op = notif.object;
    if(![self.video isInvalidated] && [op.request.URL.absoluteString isEqualToString:self.video.url]) {
        [self showProgress:YES];
    }
}

- (void)downloadDidFinish:(NSNotification*)notif {
    AFDownloadRequestOperation *op = notif.object;
    if(![self.video isInvalidated] && [op.request.URL.absoluteString isEqualToString:self.video.url]) {
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

- (void)updateUploadingProgress {
    self.uploadInProgress = !self.video.uploadedToAmazon;

    YAEventCell *postCell = (YAEventCell *)[self.commentsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.events count] - 1 inSection:0]];
    if (postCell) {
        [postCell setVideoState:self.uploadInProgress ? YAEventCellVideoStateUploading : (self.video.pending ? YAEventCellVideoStateUnapproved : YAEventCellVideoStateApproved)];
    }
}

- (void)videoChanged:(NSNotification*)notif {
    if([notif.object isEqual:self.video] && self.shouldPreload && self.video.mp4Filename.length) {
        DLog(@"Video changed recd for correct video on YAVideoPage");
        //setURL will remove playWhenReady flag, so saving it and using later
        if (!self.playerView.URL) {
            BOOL playWhenReady = self.playerView.playWhenReady;
            [self prepareVideoForPlaying];
            self.playerView.playWhenReady = playWhenReady;
            
            [self updateControls];
        }
        [self updateUploadingProgress];
        
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

// Ignore like tap if in trash button, share button, or caption button, or a tap in the caption field.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.deleteButton.superview != nil) {
        if ([touch.view isDescendantOfView:self.deleteButton]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }
    if (self.moreButton.superview != nil) {
        if ([touch.view isDescendantOfView:self.moreButton]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }
    if (self.XButton.superview != nil) {
        if ([touch.view isDescendantOfView:self.XButton]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }

    return YES; // handle the touch
}

- (void)setShowBottomControls:(BOOL)showBottomControls {
    _showBottomControls = showBottomControls;
     self.commentsWrapperView.hidden = self.commentButton.hidden = self.likeButton.hidden = self.heartButton.hidden = self.moreButton.hidden  = !_showBottomControls;
}

- (void)showSharingOptions {
    [self shareButtonPressed:nil];
}

- (void)setShowAdminControls:(BOOL)showAdminControls {
    _showAdminControls = showAdminControls;
    
    if(showAdminControls){
        [self.viewingAccessories removeFromSuperview];
        [self.overlay addSubview:self.adminAccessories];
    } else {
        [self.adminAccessories removeFromSuperview];
        [self.overlay addSubview:self.viewingAccessories];
    }

}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[YAVideoPlayerView class]]) {
        [self showLoading:!((YAVideoPlayerView*)object).readyToPlay];
    }
}

@end
