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

#define DOWN_MOVEMENT_TRESHHOLD 800.0f

@interface YAVideoPage ();
@property (nonatomic, strong) YAActivityView *activityView;

//overlay controls
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UITextView *captionField;
@property (nonatomic, strong) UILabel *captionerLabel;
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
    [self addSubview:self.userLabel];
    
    CGFloat timeHeight = 24;
    self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(gutter, height + 12, VIEW_WIDTH - gutter*2, timeHeight)];
    [self.timestampLabel setTextAlignment:NSTextAlignmentCenter];
    [self.timestampLabel setTextColor:[UIColor whiteColor]];
    [self.timestampLabel setFont:[UIFont fontWithName:BIG_FONT size:14]];
    self.timestampLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.timestampLabel.layer.shadowRadius = 1.0f;
    self.timestampLabel.layer.shadowOpacity = 1.0;
    self.timestampLabel.layer.shadowOffset = CGSizeZero;
    [self addSubview:self.timestampLabel];
    
    CGFloat captionHeight = 300;
    CGFloat captionGutter = 10;
    self.captionField = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH - captionGutter*2, captionHeight)];
    self.captionField.center = CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT/2);
    self.captionField.alpha = 0.75;
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"." attributes:@{
                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]                                                                                              }];
    [self.captionField setAttributedText:string];
    [self.captionField setBackgroundColor: [UIColor clearColor]]; //[UIColor colorWithWhite:1.0 alpha:0.1]];
    [self.captionField setTextAlignment:NSTextAlignmentCenter];
    [self.captionField setTextColor:PRIMARY_COLOR];
    [self.captionField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.captionField setReturnKeyType:UIReturnKeyDone];
    [self.captionField setScrollEnabled:NO];
    self.captionField.textContainer.lineFragmentPadding = 0;
    self.captionField.textContainerInset = UIEdgeInsetsZero;
    self.captionField.delegate = self;
    
//    [self addSubview:self.captionField];
    
    self.captionerLabel = [[UILabel alloc] initWithFrame:CGRectMake(captionGutter, self.captionField.frame.size.height + self.captionField.frame.origin.y, VIEW_WIDTH - captionGutter*2, 24)];
    [self.captionerLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
    [self.captionerLabel setTextColor:[UIColor whiteColor]];
    [self.captionerLabel setBackgroundColor:[UIColor clearColor]];
    [self.captionerLabel setTextAlignment:NSTextAlignmentCenter];
    self.captionerLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.captionerLabel.layer.shadowRadius = 1.0f;
    self.captionerLabel.layer.shadowOpacity = 1.0;
    self.captionerLabel.layer.shadowOffset = CGSizeZero;

//    [self addSubview:self.captionerLabel];
    
    //    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    //    YASwipingViewController *swipingParent = (YASwipingViewController *) self.presentingVC;
    //    [panGesture requireGestureRecognizerToFail:swipingParent.panGesture];
    //    [panGesture requireGestureRecognizerToFail:((YASwipingViewController *) self.presentingVC).panGesture];
    
    //    [self.captionField addGestureRecognizer:panGesture];
    
    CGFloat tSize = MAX_CAPTION_SIZE;
    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - tSize, 0, tSize, tSize)];
    [self.captionButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    [self.captionButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.captionButton setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
    [self addSubview:self.captionButton];
    
    CGFloat saveSize = 36;
    self.shareButton = [[UIButton alloc] initWithFrame:CGRectMake(/* VIEW_WIDTH - saveSize - */ 15, VIEW_HEIGHT - saveSize - 15, saveSize, saveSize)];
    [self.shareButton setBackgroundImage:[UIImage imageNamed:@"Share"] forState:UIControlStateNormal];
    [self.shareButton addTarget:self action:@selector(shareButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.shareButton];
    
    self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake( VIEW_WIDTH - saveSize - 15, VIEW_HEIGHT - saveSize - 15, saveSize, saveSize)];
    [self.deleteButton setBackgroundImage:[UIImage imageNamed:@"Delete"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.deleteButton];
    
    CGFloat likeSize = 42;
    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - likeSize)/2, VIEW_HEIGHT - likeSize - 12, likeSize, likeSize)];
    [self.likeButton addTarget:self action:@selector(likeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.likeButton];
    
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
    [self addSubview:self.likeCount];
    
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
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [self.video rename:textView.text withFont:self.fontIndex];
        [self updateControls];
        
        [textView resignFirstResponder];
        return NO;
    }
    
    // limit to 100 characters
    return textView.text.length + (text.length - range.length) <= 100;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self resizeText];
}

- (void)resizeText {
    NSString *fontName = self.captionField.font.fontName;
    CGFloat fontSize = MAX_CAPTION_SIZE;
    
    NSStringDrawingOptions option = NSStringDrawingUsesLineFragmentOrigin;
    
    NSString *text = self.captionField.text;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:fontName size:fontSize]};
    CGRect rect = [text boundingRectWithSize:CGSizeMake(self.captionField.frame.size.width, CGFLOAT_MAX)
                                     options:option
                                  attributes:attributes
                                     context:nil];
    
    while(rect.size.height > self.captionField.bounds.size.height){
        
        fontSize = fontSize - 1.0f;
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:fontName size:fontSize]};
        rect = [text boundingRectWithSize:CGSizeMake(self.captionField.frame.size.width, CGFLOAT_MAX)
                                  options:option
                               attributes:attributes
                                  context:nil];
        DLog(@"resizing vert: new font size: %f, new height: %f", fontSize, rect.size.height);
    }
    
    for (NSString *word in [text componentsSeparatedByString:@" "]) {
        float width = [word sizeWithAttributes:attributes].width;
        
        while (width > self.captionField.bounds.size.width && width > 0) {
            fontSize = fontSize - 1.0f;
            NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:fontName size:fontSize]};
            width = [word sizeWithAttributes:attributes].width;
            DLog(@"resizing horizontal: new font size: %f, new width: %f", fontSize, width);
        }
    }
    
    CGFloat finalHeight = [text boundingRectWithSize:CGSizeMake(self.captionField.frame.size.width, CGFLOAT_MAX) options:option attributes:attributes context:nil].size.height;
    
    [self.captionField setFont: [UIFont fontWithName:fontName size:fontSize]];
    CGRect captionerFrame = self.captionerLabel.frame;
    captionerFrame.origin.y = self.captionField.frame.origin.y + finalHeight;
    [self.captionerLabel setFrame:captionerFrame];
}

-(void)panned:(UIPanGestureRecognizer*)recognizer {
    CGPoint translatedPoint = [recognizer translationInView:[[recognizer view] superview]];
    DLog(@"panned? %f", translatedPoint.y);
    
    if([recognizer state] == UIGestureRecognizerStateBegan) {
        _firstX = [self.captionField center].x;
        _firstY = [self.captionField center].y;
    }
    
    translatedPoint = CGPointMake(_firstX+translatedPoint.x, _firstY+translatedPoint.y);
    
    [self.captionField setCenter:translatedPoint];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self doneEditing];
    return YES;
}

- (void)textButtonPressed {
    //    [self animateButton:self.captionButton withImageName:@"Text" completion:nil];
    
    
    if([self.captionField isFirstResponder]){
        if(!self.fontIndex){
            self.fontIndex = self.video.font;
        }
        
        self.fontIndex++;
        
        if(self.fontIndex >= [CAPTION_FONTS count]){
            self.fontIndex = 0;
        }
        
        [self.captionField setFont:[UIFont fontWithName:CAPTION_FONTS[self.fontIndex] size:MAX_CAPTION_SIZE]];
        [self resizeText];
    } else {
        [self.captionField becomeFirstResponder];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.tapOutGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditingTapOut:)];
    [self addGestureRecognizer:self.tapOutGestureRecognizer];
}

- (void)doneEditingTapOut:(id)sender {
    [self doneEditing];
}

- (void)doneEditing {
    [self.video rename:self.captionField.text withFont:self.fontIndex];
    [self removeGestureRecognizer:self.tapOutGestureRecognizer];
    [self updateControls];
    
    [self.captionField resignFirstResponder];
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
    
    self.captionField.hidden = NO;
    self.captionButton.hidden = NO;
    self.shareButton.hidden = NO;
    
    BOOL myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
    self.deleteButton.hidden = !myVideo;
    //    self.shareButton.hidden = !myVideo;
    
    self.userLabel.text = self.video.creator;
    
    self.timestampLabel.text = [[YAUser currentUser] formatDate:self.video.createdAt]; //[[self.video.createdAt formattedAsTimeAgo] lowercaseString];
    [self.likeButton setBackgroundImage:self.video.like ? [UIImage imageNamed:@"Liked"] : [UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
    self.likeCount.hidden = (self.video.like && self.video.likers.count == 1);
    self.captionField.text = self.video.caption;
    self.fontIndex = self.video.font;
    [self.captionField setFont:[UIFont fontWithName:CAPTION_FONTS[self.fontIndex] size:MAX_CAPTION_SIZE]];
    if(![self.video.namer isEqual:@""]){
        [self.captionerLabel setText:[NSString stringWithFormat:@"- %@", self.video.namer]];
    } else {
        [self.captionerLabel setText:@""];
    }
    
    [self resizeText];
    
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
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
    NSString *mode = self.captionField.textInputMode.primaryLanguage;
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
    [self.video rename:self.captionField.text withFont:self.fontIndex];
    [self removeGestureRecognizer:self.tapOutGestureRecognizer];
    [self updateControls];
    
    [self.captionField resignFirstResponder];
    self.keyBoardAccessoryButton.hidden = YES;
}

@end

