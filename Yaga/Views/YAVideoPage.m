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
#import "XYPieChart.h"
#import "OrderedDictionary.h"

#define CAPTION_GUTTER 5.f
#define MAX_CAPTION_WIDTH (VIEW_WIDTH - 2 * CAPTION_GUTTER)
#define DOWN_MOVEMENT_TRESHHOLD 800.0f

@interface YAVideoPage () <XYPieChartDelegate, XYPieChartDataSource>;
@property (nonatomic, strong) YAActivityView *activityView;

//overlay controls
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *likeCount;
@property BOOL likesShown;
@property (nonatomic, strong) NSMutableArray *likeLabels;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UILabel *toolTipLabel;

@property (nonatomic, strong) YAProgressView *progressView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (strong, nonatomic) UITapGestureRecognizer *tapOutGestureRecognizer;
@property (nonatomic) CGRect keyboardRect;
@property (nonatomic, strong) UIButton *keyBoardAccessoryButton;
@property NSUInteger fontIndex;

@property (strong, nonatomic) UITapGestureRecognizer *likeGestureRecognizer;
@property (strong, nonatomic) UILongPressGestureRecognizer *hideGestureRecognizer;

@property (strong, nonatomic) NSMutableArray *rainOptions;
@property (strong, nonatomic) NSArray *options;


@property (strong, nonatomic) UIView *overlay;
@property (strong, nonatomic) UITextView *currentTextField;
@property (nonatomic) CGFloat textFieldHeight;
@property (nonatomic) CGAffineTransform textFieldTransform;
@property (nonatomic) CGPoint textFieldCenter;

@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (strong, nonatomic) UIRotationGestureRecognizer *rotateGestureRecognizer;

@property (nonatomic, strong) UIButton *captionXButton;

@property (nonatomic, strong) XYPieChart *pieChart;
@property (nonatomic, strong) MutableOrderedDictionary *rainData;

@property (nonatomic, strong) UISwitch *likeCaptionToggle;

//@property CGFloat lastScale;
//@property CGFloat lastRotation;
@property CGFloat firstX;
@property CGFloat firstY;

@property (nonatomic, assign) BOOL shouldPreload;
@end

@implementation YAVideoPage

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        //self.activityView = [[YAActivityView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5)];
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
        
        [self initOverlayControls];
        [self initTooltip];
        
        
        [self setBackgroundColor:PRIMARY_COLOR];
    }
    return self;
}

- (void)keyboardDown:(NSNotification*)n
{
    self.keyBoardAccessoryButton.hidden = YES;
}

- (void)keyboardShown:(NSNotification*)n
{
    NSNumber *info = n.userInfo[ UIKeyboardFrameEndUserInfoKey ];
    self.keyboardRect = info.CGRectValue;
    if (self.currentTextField) {
        [self positionTextViewAboveKeyboard];
    }
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.activityView.frame = CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5);
    self.activityView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)setVideo:(YAVideo *)video shouldPreload:(BOOL)shouldPreload {
    if([_video isInvalidated] || ![_video.localId isEqualToString:video.localId]) {
        
        _video = video;

        [self updateControls];
        
        if(!shouldPreload) {
            self.playerView.frame = CGRectZero;
            [self showLoading:YES];
        }
        
        [self initRain];
    }
    
    self.shouldPreload = shouldPreload;
    
    if(shouldPreload) {
        [self prepareVideoForPlaying];
    }
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
    
    //add fullscreen jpg preview
    [self addFullscreenJpgPreview];
}

- (void)addFullscreenJpgPreview {
    if([self.playerView isPlaying])
       return;
       
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
}

- (void)showLoading:(BOOL)show {
    if(show) {
        self.progressView.hidden = NO;
    }
    else {
        self.progressView.hidden = YES;
    }
}

- (void)dealloc {
    [self.playerView removeObserver:self forKeyPath:@"readyToPlay"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION      object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION      object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidFinishNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextInputCurrentInputModeDidChangeNotification object:nil];
}

- (void) initTooltip {
    if(![[NSUserDefaults standardUserDefaults] boolForKey:kTappedToEnlarge]) {
        [[NSUserDefaults standardUserDefaults] setBool:1 forKey:kTappedToEnlarge];
        //first start tooltips
        self.toolTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        
        self.toolTipLabel.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:48];
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Swipe Down\n To Dismiss"
                                                                     attributes:@{
                                                                                  NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                  NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]
                                                                                  }];
        
        self.toolTipLabel.textAlignment = NSTextAlignmentCenter;
        self.toolTipLabel.attributedText = string;
        self.toolTipLabel.numberOfLines = 0;
        self.toolTipLabel.textColor = PRIMARY_COLOR;
        self.toolTipLabel.alpha = 0.0;
        [self addSubview:self.toolTipLabel];
        //warning create varible for all screen sizes
        
        [UIView animateKeyframesWithDuration:0.6 delay:0.3 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
            //
            [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
                //
                self.toolTipLabel.alpha = 1.0;
            }];
            
            for(float i = 0; i < 4; i++){
                [UIView addKeyframeWithRelativeStartTime:i/5.0 relativeDuration:i/(5.0) animations:^{
                    //
                    self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI/18 + M_PI/36 + (int)i%2 * -1* M_PI/18);
                }];
                
            }
            
            [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
                self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI/18);
            }];
            
            
        } completion:^(BOOL finished) {
            self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI/18);
        }];
        
        [UIView animateWithDuration:0.3 delay:0.4 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            //
            self.toolTipLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            //
        }];
    }

}

#pragma mark - Overlay controls

- (void)initOverlayControls {
    CGFloat height = 30;
    CGFloat gutter = 48;
    self.userLabel = [[UILabel alloc] initWithFrame:CGRectMake(gutter, 12, VIEW_WIDTH - gutter*2, height)];
    [self.userLabel setTextAlignment:NSTextAlignmentCenter];
    [self.userLabel setTextColor:[UIColor whiteColor]];
    [self.userLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    self.userLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.userLabel.layer.shadowRadius = 1.0f;
    self.userLabel.layer.shadowOpacity = 1.0;
    self.userLabel.layer.shadowOffset = CGSizeZero;
    [self.overlay addSubview:self.userLabel];
    
    CGFloat timeHeight = 24;
    self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(gutter, height + 12, VIEW_WIDTH - gutter*2, timeHeight)];
    [self.timestampLabel setTextAlignment:NSTextAlignmentCenter];
    [self.timestampLabel setTextColor:[UIColor whiteColor]];
    [self.timestampLabel setFont:[UIFont fontWithName:BIG_FONT size:14]];
    self.timestampLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.timestampLabel.layer.shadowRadius = 1.0f;
    self.timestampLabel.layer.shadowOpacity = 1.0;
    self.timestampLabel.layer.shadowOffset = CGSizeZero;
    [self.overlay addSubview:self.timestampLabel];
    
    CGFloat tSize = MAX_CAPTION_SIZE;
    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - tSize, 0, tSize, tSize)];
    [self.captionButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    [self.captionButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.captionButton setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
//    [self addSubview:self.captionButton];
    
    CGFloat saveSize = 36;
    self.shareButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - saveSize - 15, 15, saveSize, saveSize)];
    [self.shareButton setBackgroundImage:[UIImage imageNamed:@"Share"] forState:UIControlStateNormal];
    [self.shareButton addTarget:self action:@selector(shareButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.shareButton];
    
    self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, saveSize, saveSize)];
    [self.deleteButton setBackgroundImage:[UIImage imageNamed:@"Delete"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.deleteButton];
    
    CGFloat likeSize = 42;
    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - likeSize)/2, VIEW_HEIGHT - likeSize - 12, likeSize, likeSize)];
    [self.likeButton addTarget:self action:@selector(likeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self addSubview:self.likeButton];
    
    CGFloat likeCountWidth = 24, likeCountHeight = 42;
    self.likeCount = [[UIButton alloc] initWithFrame:CGRectMake(self.likeButton.frame.origin.x + self.likeButton.frame.size.width + 8, VIEW_HEIGHT - likeCountHeight - 12, likeCountWidth, likeCountHeight)];
    [self.likeCount addTarget:self action:@selector(likeCountPressed) forControlEvents:UIControlEventTouchUpInside];
    //    [self.likeCount setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self.likeCount.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:16]];
    self.likeCount.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.likeCount.layer.shadowRadius = 1.0f;
    self.likeCount.layer.shadowOpacity = 1.0;
    self.likeCount.layer.shadowOffset = CGSizeZero;
    //    [self.likeCount setBackgroundColor:[UIColor greenColor]];
//    [self addSubview:self.likeCount];
    
    self.captionXButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH*0.05, VIEW_HEIGHT*0.05, 40, 40)];
    [self.captionXButton setImage:[UIImage imageNamed:@"Remove"] forState:UIControlStateNormal];
    [self.captionXButton addTarget:self action:@selector(captionCancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlay addSubview:self.captionXButton];
    self.captionXButton.hidden = YES;
    
    
    self.likeCaptionToggle = [[UISwitch alloc] initWithFrame:CGRectMake(VIEW_WIDTH-100, VIEW_HEIGHT * 0.9, 10, 10)];
    [self.overlay addSubview:self.likeCaptionToggle];
    
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
    
    self.likeGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.likeGestureRecognizer setNumberOfTapsRequired:1];
    [self addGestureRecognizer:self.likeGestureRecognizer];

    self.hideGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hideHold:)];
    [self.hideGestureRecognizer setMinimumPressDuration:0.2f];
    [self addGestureRecognizer:self.hideGestureRecognizer];

    CGFloat pieRadius = 20.0f;
    CGFloat margin = 10.0f;
    self.pieChart = [[XYPieChart alloc] initWithFrame:CGRectMake(margin, VIEW_HEIGHT - margin - pieRadius*2, pieRadius*2, pieRadius*2) Center:CGPointMake(pieRadius,pieRadius) Radius:pieRadius];
    self.pieChart.delegate = self;
    self.pieChart.dataSource = self;
//    [self.pieChart setBackgroundColor:[UIColor redColor]];
    [self.pieChart reloadData];
    [self.pieChart setLabelColor:[UIColor clearColor]];
    
    [self.overlay addSubview:self.pieChart];
    
    [self setupCaptionGestureRecognizers];

//    self.rainOptions = [[NSMutableArray alloc] init];
//    self.options = @[@"rainHeart", @"rainBoo", @"rainText"];
////    int tag = 0;
//    for(NSString *option in self.options){
//        UIImageView *rainOption = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
//        [rainOption setImage:[UIImage imageNamed:option]];
//        [self.overlay addSubview:rainOption];
//    }
//    [self initRain];
}

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart {
    return [self.rainData count];
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index {
    return [[self.rainData objectAtIndex:index] floatValue];
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index {
    return [YAUtils UIColorFromUsernameString:[self.rainData keyAtIndex:index]];
}

- (NSString *)pieChart:(XYPieChart *)pieChart textForSliceAtIndex:(NSUInteger)index {
    return @"";
}

- (void) initRain {
    
    self.rainData = [[MutableOrderedDictionary alloc] init];
    
    NSLog(@"firebase wat");
    
    NSLog(@"serverid: %@", self.video.serverId);
    
    __weak YAVideoPage *weakSelf = self;
    
    __block BOOL initial = NO;
    
    [[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        if(initial){
            [weakSelf newRain:snapshot count:0 total:0];
            [weakSelf.pieChart reloadData];
        }
    }];

    [[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        initial = YES;
        int count = 0;
        int childrenCount = (int) snapshot.childrenCount;
        for(FDataSnapshot *s in snapshot.children){
            [weakSelf newRain:s count:count total:childrenCount];
            count++;
        }
        
        [weakSelf.pieChart reloadData];

    }];
    
}

- (void)newRain:(FDataSnapshot *)snapshot count:(int)count total:(int)total {
    NSLog(@"heart found");
    
    NSString *username;
    if(snapshot.value[@"username"]){
        username = snapshot.value[@"username"];
    } else {
        username = @"yaga";
    }
    
    UIColor *color = [YAUtils UIColorFromUsernameString:username];
    UIImageView *likeHeart = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];// initWith;
    [likeHeart setImage:[UIImage imageNamed:@"rainHeart"]];
    likeHeart.image = [likeHeart.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    likeHeart.tintColor = color;
    
    [likeHeart setAlpha:0.6];
    int lowerBound = -30;
    int upperBound = 30;
    int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI * (rndValue) / 180.0);
    likeHeart.center = CGPointMake([snapshot.value[@"x"] doubleValue] * VIEW_WIDTH, [snapshot.value[@"y"] doubleValue] * VIEW_HEIGHT);
    likeHeart.transform = CGAffineTransformScale(rotation, 0.75, 0.75);
    
    likeHeart.alpha = 0.0;
//#define ARC4RANDOM_MAX      0x100000000
//    double val = ((double)arc4random() / ARC4RANDOM_MAX)/5.0f;
    float delay = (float)count/(float)total * 1.0;
    
    [UIView animateWithDuration:0.1 delay:delay options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        //
        likeHeart.alpha = 0.6;
        likeHeart.transform = CGAffineTransformScale(rotation, 1.0, 1.0);
    } completion:^(BOOL finished) {
        
    }];
    
    [self.overlay addSubview:likeHeart];
    
    if([self.rainData objectForKey:username]){
        NSNumber *inc = [NSNumber numberWithInt:[[self.rainData objectForKey:username] intValue] + 1];
        [self.rainData setObject:inc forKey:username];
    } else {
        [self.rainData setObject:[NSNumber numberWithInt:1] forKey:username];
    }

}

#pragma mark - caption gestures

- (void) setupCaptionGestureRecognizers {
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
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
        finalPoint.x = MIN(MAX(finalPoint.x, self.currentTextField.frame.size.width/4), self.bounds.size.width - self.currentTextField.frame.size.width/4);
        finalPoint.y = MIN(MAX(finalPoint.y, self.currentTextField.frame.size.height/2), self.bounds.size.height - self.currentTextField.frame.size.height/4);
        
        recognizer.view.center = finalPoint;
    }
}

- (void)handleRotate:(UIRotationGestureRecognizer *)recognizer {
    
    recognizer.view.transform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);
    recognizer.rotation = 0;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    recognizer.scale = 1;
}

- (void)captionCancelPressed:(id)sender {
    self.captionXButton.hidden = YES;
    [self.currentTextField removeFromSuperview];
    self.currentTextField = nil;
}


- (void)positionTextViewAboveKeyboard{
    self.currentTextField.transform = CGAffineTransformIdentity;
    [self.currentTextField removeGestureRecognizer:self.panGestureRecognizer];
    [self.currentTextField removeGestureRecognizer:self.rotateGestureRecognizer];
    [self.currentTextField removeGestureRecognizer:self.pinchGestureRecognizer];

    [self resizeTextAboveKeyboardWithAnimation:YES];
}



- (void)moveTextViewBackToSpot {
    CGSize frameSize = [self sizeForTextFieldWithString:self.currentTextField.text];
    
    __weak YAVideoPage *weakSelf = self;

    [UIView animateWithDuration:0.2f animations:^{
        self.currentTextField.frame = CGRectMake(self.textFieldCenter.x - frameSize.width/2.f,
                                                 self.textFieldCenter.y - frameSize.height/2.f,
                                                 frameSize.width,
                                                 frameSize.height);
        
        self.currentTextField.transform = self.textFieldTransform;
    } completion:^(BOOL finished) {
        [weakSelf.currentTextField addGestureRecognizer:self.panGestureRecognizer];
        [weakSelf.currentTextField addGestureRecognizer:self.rotateGestureRecognizer];
        [weakSelf.currentTextField addGestureRecognizer:self.pinchGestureRecognizer];
    }];
}

- (CGSize)sizeForTextFieldWithString:(NSString *)string {
    CGRect frame = [string boundingRectWithSize:CGSizeMake(MAX_CAPTION_WIDTH, CGFLOAT_MAX)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:@{ NSFontAttributeName:[UIFont fontWithName:CAPTION_FONTS[self.fontIndex] size:MAX_CAPTION_SIZE],
                                                 NSStrokeColorAttributeName:[UIColor whiteColor],
                                                 NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0] } context:nil];
    return frame.size;
}

- (void)addCaptionAtPoint:(CGPoint)point {
    // Should also blur first
    self.captionXButton.hidden = NO;
    
    self.textFieldCenter = point;
    self.textFieldTransform = CGAffineTransformMakeScale(0.8, 0.8);
    
    CGSize captionSize = [self sizeForTextFieldWithString:@"A"];
    
    self.currentTextField = [[UITextView alloc] initWithFrame:CGRectMake(VIEW_WIDTH / 2, VIEW_HEIGHT / 2, captionSize.width, captionSize.height)];
    
    self.currentTextField.alpha = 0.75;
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"." attributes:@{
                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-3.0]                                                                                              }];
    [self.currentTextField setAttributedText:string];
    [self.currentTextField replaceRange:[self.currentTextField textRangeFromPosition:[self.currentTextField beginningOfDocument] toPosition:[self.currentTextField endOfDocument]] withText:@""];
    
    [self.currentTextField setFont:[UIFont fontWithName:CAPTION_FONTS[self.fontIndex] size:MAX_CAPTION_SIZE]];

    [self.currentTextField setBackgroundColor: [UIColor clearColor]]; //[UIColor colorWithWhite:1.0 alpha:0.1]];
    [self.currentTextField setTextAlignment:NSTextAlignmentCenter];
    [self.currentTextField setTextColor:PRIMARY_COLOR];
    [self.currentTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.currentTextField setReturnKeyType:UIReturnKeyDone];
    [self.currentTextField setScrollEnabled:NO];
    self.currentTextField.textContainer.lineFragmentPadding = 0;
    self.currentTextField.textContainerInset = UIEdgeInsetsZero;
    self.currentTextField.delegate = self;
    
    [self.overlay addSubview:self.currentTextField];
    
    [self.currentTextField becomeFirstResponder];
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
//        [self.video rename:textView.text withFont:self.fontIndex];
//        [self updateControls];
//        
        [self doneEditing];
        return NO;
    }
    
    return [self doesFit:textView string:text range:range];
    
}


- (float)doesFit:(UITextView*)textView string:(NSString *)myString range:(NSRange) range;
{
    CGSize maxFrame = [self sizeForTextFieldWithString:@"A\nA\nA"];
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
    NSString *captionText = [self.currentTextField.text length] ? self.currentTextField.text : @"A";
    CGSize size = [self sizeForTextFieldWithString:captionText];
    CGRect frameAboveKeyboard = CGRectMake((VIEW_WIDTH / 2.f) - (size.width/ 2.f),
                                           self.keyboardRect.origin.y - size.height,
                                           size.width,
                                           size.height);
    
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^{
            self.currentTextField.frame = frameAboveKeyboard;
        }];
    } else {
        self.currentTextField.frame = frameAboveKeyboard;
    }

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self doneEditing];
    return YES;
}

//- (void)textButtonPressed {
//    //    [self animateButton:self.captionButton withImageName:@"Text" completion:nil];
//    
//    
//    if([self.captionField isFirstResponder]){
//        if(!self.fontIndex){
//            self.fontIndex = self.video.font;
//        }
//        
//        self.fontIndex++;
//        
//        if(self.fontIndex >= [CAPTION_FONTS count]){
//            self.fontIndex = 0;
//        }
//        
//        [self.captionField setFont:[UIFont fontWithName:CAPTION_FONTS[self.fontIndex] size:MAX_CAPTION_SIZE]];
//        [self resizeText];
//    } else {
//        [self.captionField becomeFirstResponder];
//    }
//}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.tapOutGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditingTapOut:)];
    [self addGestureRecognizer:self.tapOutGestureRecognizer];
}

- (void)doneEditingTapOut:(id)sender {
    [self doneEditing];
}

- (void)doneEditing {
//    [self.video rename:self.captionField.text withFont:self.fontIndex];
    [self removeGestureRecognizer:self.tapOutGestureRecognizer];
//    [self updateControls];
    [self.currentTextField resignFirstResponder];
    [self moveTextViewBackToSpot];
}

- (void)likeButtonPressed {
    NSString *likeCountSelf = self.likeCount.titleLabel.text;
    NSNumberFormatter *f = [NSNumberFormatter new];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSUInteger likeCountNumber = [[f numberFromString:likeCountSelf] integerValue];
    if (!self.video.like) {
        if (likeCountNumber == 0) {
            self.likeCount.hidden = YES;
            [self.likeCount setTitle:@"0"
                            forState:UIControlStateNormal];
        } else {
            [self.likeCount setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)++likeCountNumber]
                            forState:UIControlStateNormal];
        }
        [[YAServer sharedServer] likeVideo:self.video withCompletion:^(NSNumber* response, NSError *error) {
            [self.likeCount setTitle:[NSString stringWithFormat:@"%@", response]
                            forState:UIControlStateNormal];
        }];
        [[Mixpanel sharedInstance] track:@"Video liked"];
    } else {
        if (likeCountNumber <= 1) {
            self.likeCount.hidden = YES;
            [self.likeCount setTitle:@"0"
                            forState:UIControlStateNormal];
        } else {
            [self.likeCount setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)--likeCountNumber]
                            forState:UIControlStateNormal];
        }
        [[YAServer sharedServer] unLikeVideo:self.video withCompletion:^(NSNumber* response, NSError *error) {
            [self.likeCount setTitle:[response integerValue] == 0 ? @"" : [NSString stringWithFormat:@"%@", response]
                            forState:UIControlStateNormal];
        }];
        [[Mixpanel sharedInstance] track:@"Video unliked"];
    }
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.video.like = !self.video.like;
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [self animateButton:self.likeButton withImageName:self.video.like ? @"Liked" : @"Like" completion:nil];
}

- (void)likeCountPressed {
    
    if(self.likesShown){
        [self hideLikes];
        self.likesShown = NO;
        
        [self removeGestureRecognizer:[self.gestureRecognizers lastObject]];
    } else {
        [self showLikes];
        self.likesShown = YES;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideLikesTapOut:)];
        [self addGestureRecognizer:tap];
    }
}

- (void)hideLikesTapOut:(UIGestureRecognizer *) recognizer {
    [self removeGestureRecognizer:recognizer];
    [self hideLikes];
    self.likesShown = NO;
}

- (void)handleTap:(UITapGestureRecognizer *) recognizer {
    NSLog(@"tapped");
    if (self.likeCaptionToggle.on) { // some like vs caption state
        [self likeTappedAtPoint:[recognizer locationInView:self]];
    } else {
        [self addCaptionAtPoint:[recognizer locationInView:self]];
    }
}

- (void)likeTappedAtPoint:(CGPoint)point {
    
    CGPoint tapLocation = point;
    
    NSDictionary *heartData = @{
                                @"type": @"heart",
                                @"x":[NSNumber numberWithDouble: tapLocation.x/VIEW_WIDTH],
                                @"y":[NSNumber numberWithDouble: tapLocation.y/VIEW_HEIGHT],
                                @"username":[YAUser currentUser].username
                                };
    
    [[[[YAServer sharedServer].firebase childByAppendingPath:self.video.serverId] childByAutoId] setValue:heartData];
    
//        likeHeart.alpha = 0.0;
//        [UIView animateWithDuration:0.2 animations:^{
//            //
//            likeHeart.alpha = 1.0;
//            likeHeart.transform = CGAffineTransformScale(rotation, 1.0, 1.0);
//        }];
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

- (void)showLikes {
    
    CGFloat origin = self.likeCount.frame.origin.y;
    CGFloat height = 24;
    CGFloat width = 72;
    
    self.likeLabels = [[NSMutableArray alloc] init];
    
    for(YAContact *cntct in self.video.likers){
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.likeCount.frame.origin.x + self.likeCount.frame.size.width - width, origin + self.likeCount.frame.size.height/2, width, height)];
        if (cntct.username.length) {
            [label setText:cntct.username];
        } else {
            [label setText:cntct.name];
        }
        [label setTextAlignment:NSTextAlignmentRight];
        [label setTextColor:[UIColor whiteColor]];
        [label setFont:[UIFont fontWithName:BIG_FONT size:16]];
        
        label.layer.shadowColor = [[UIColor blackColor] CGColor];
        label.layer.shadowRadius = 1.0f;
        label.layer.shadowOpacity = 1.0;
        label.layer.shadowOffset = CGSizeZero;
        [label setAlpha:0.0];
        
        [self.likeLabels addObject:label];
        [self addSubview:label];
    }
    
    CGFloat xRadius = 500;
    CGFloat yRadius = 3000;
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        //
        int i = 0;
        
        for(UILabel *label in self.likeLabels){
            //            [UIView addKeyframeWithRelativeStartTime:(CGFloat) i / (CGFloat) [self.likeLabels count] relativeDuration:2.0f/(CGFloat)[self.likeLabels count] animations:^{
            //
            [label setAlpha:1.0];
            //            [label setFrame:CGRectMake(self.likeCount.frame.origin.x + self.likeCount.frame.size.width - width, origin - (i+1)*(height + margin), width, height)];
            CGFloat angle = (1.0f * M_PI / 180 * ((CGFloat) i + 1.0f));
            
            CGAffineTransform rotate = CGAffineTransformMakeRotation(angle);
            //            CGAffineTransformMake
            CGFloat translateX = xRadius - fabs(xRadius*cosf(angle));
            CGFloat translateY = -fabs(yRadius*sinf(angle));
            [label setTransform:CGAffineTransformTranslate(rotate, translateX, translateY)];
            
            i++;
            
        }
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)hideLikes {
    int i = 0;
    
    for(UILabel *label in self.likeLabels){
        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            //            [UIView addKeyframeWithRelativeStartTime:(CGFloat) i / (CGFloat) [self.likeLabels count] relativeDuration:2.0f/(CGFloat)[self.likeLabels count] animations:^{
            //
            [label setAlpha:0.0];
            //            [label setFrame:CGRectMake(self.likeCount.frame.origin.x + self.likeCount.frame.size.width - width, origin - margin, width, height)];
            [label setTransform:CGAffineTransformIdentity];
            
        } completion:^(BOOL finished) {
            [label removeFromSuperview];
        }];
        i++;
    }
    
}

- (void)deleteButtonPressed {
    [self animateButton:self.deleteButton withImageName:nil completion:^{
        [YAUtils deleteVideo:self.video];
    }];
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
    
//    self.captionField.hidden = NO;
    self.captionButton.hidden = NO;
    self.shareButton.hidden = NO;
    
    BOOL myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
    self.deleteButton.hidden = !myVideo;
    //    self.shareButton.hidden = !myVideo;
    
    self.userLabel.text = self.video.creator;
    
    self.timestampLabel.text = [[YAUser currentUser] formatDate:self.video.createdAt]; //[[self.video.createdAt formattedAsTimeAgo] lowercaseString];
    [self.likeButton setBackgroundImage:self.video.like ? [UIImage imageNamed:@"Liked"] : [UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
    self.likeCount.hidden = (self.video.like && self.video.likers.count == 1);
//    self.captionField.text = self.video.caption;
    self.fontIndex = self.video.font;
//    if(![self.video.namer isEqual:@""]){
//        [self.captionerLabel setText:[NSString stringWithFormat:@"- %@", self.video.namer]];
//    } else {
//        [self.captionerLabel setText:@""];
//    }
    
//    [self resizeText];
    
    [self.likeCount setTitle:self.video.likes ? [NSString stringWithFormat:@"%ld", (long)self.video.likes] : @""
                    forState:UIControlStateNormal];
    
    //get likers for video
    
}

- (void)shareButtonPressed {
    [self animateButton:self.shareButton withImageName:@"Share" completion:nil];
    NSString *caption = ![self.video.caption isEqualToString:@""] ? self.video.caption : @"Yaga";
    NSString *detailText = [NSString stringWithFormat:@"%@ — http://getyaga.com", caption];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
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
        [self.presentingVC presentViewController:activityViewController
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
    self.progressView.backgroundView.hidden = !show;
}

- (void)downloadProgressChanged:(NSNotification*)notif {
    NSString *url = notif.object;
    if(![self.video isInvalidated] && [url isEqualToString:self.video.url]) {
        
        if(self.progressView) {
            NSNumber *value = notif.userInfo[kVideoDownloadNotificationUserInfoKey];
            [self.progressView setProgress:value.floatValue animated:NO];
            [self.progressView setCustomText:self.video.creator];
        }
    }
}

- (void)videoChanged:(NSNotification*)notif {
    if([notif.object isEqual:self.video] && !self.playerView.URL && self.shouldPreload && self.video.mp4Filename.length) {
        //setURL will remove playWhenReady flag, so saving it and using later
        BOOL playWhenReady = self.playerView.playWhenReady;
        [self prepareVideoForPlaying];
        self.playerView.playWhenReady = playWhenReady;
    }
}

#pragma mark - UIPanGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[YAVideoPlayerView class]]) {
        [self showLoading:!((YAVideoPlayerView*)object).readyToPlay];
    }
}

#pragma mark - Observing input mode
- (void)inputModeChanged:(NSNotification*)sender {
    NSString *mode = self.currentTextField.textInputMode.primaryLanguage;
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
    
    [self.currentTextField resignFirstResponder];
    self.keyBoardAccessoryButton.hidden = YES;
}

@end

