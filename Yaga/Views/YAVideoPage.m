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

#define DOWN_MOVEMENT_TRESHHOLD 800.0f

@interface YAVideoPage ();
@property (nonatomic, strong) YAActivityView *activityView;

//overlay controls
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UITextView *captionField;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *likeCount;
@property BOOL likesShown;
@property (nonatomic, strong) NSMutableArray *likeLabels;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) YAProgressView *progressView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

@property NSUInteger fontIndex;
@property (strong, nonatomic) NSArray *fonts;

//@property CGFloat lastScale;
//@property CGFloat lastRotation;
@property CGFloat firstX;
@property CGFloat firstY;

@end

@implementation YAVideoPage

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        //self.activityView = [[YAActivityView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5)];
        [self addSubview:self.activityView];
        _playerView = [YAVideoPlayerView new];
        [self addSubview:self.playerView];
        
        self.fonts = @[@"ArialRoundedMTBold", @"AmericanTypewriter-Bold", @"Chalkduster",
                           @"ChalkboardSE-Bold", @"CourierNewPS-BoldItalicMT", @"MarkerFelt-Wide",
                           @"Futura-CondensedExtraBold", @"SnellRoundhand-Black", @"AvenirNext-HeavyItalic"];

        if(!self.fontIndex){
            self.fontIndex = 0;
        }
        
        [self.playerView addObserver:self forKeyPath:@"readyToPlay" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:AFNetworkingOperationDidStartNotification object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressChanged:) name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generationProgressChanged:) name:VIDEO_DID_GENERATE_PART_NOTIFICATION object:nil];
        
        [self initOverlayControls];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.activityView.frame = CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5);
    self.activityView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)setVideo:(YAVideo *)video shouldPlay:(BOOL)shouldPlay {
    if([_video isInvalidated] || ![_video.localId isEqualToString:video.localId]) {
        _video = video;
        
        [self updateControls];
        
        if(!shouldPlay) {
            self.playerView.frame = CGRectZero;
            [self showLoading:YES];
        }
    }
    
    if(shouldPlay) {
        NSURL *movUrl = [YAUtils urlFromFileName:self.video.movFilename];
        [self showLoading:![movUrl.absoluteString isEqualToString:self.playerView.URL.absoluteString]];
        
        if(self.video.movFilename.length)
        {
            self.playerView.URL = movUrl;
        }
        else
        {
            self.playerView.URL = nil;
        }
        
        self.playerView.frame = self.bounds;
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(YAVideoPlayerView*)vc change:(NSDictionary *)change context:(void *)context{
    [self showLoading:!vc.readyToPlay];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_GENERATE_PART_NOTIFICATION      object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
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
    CGFloat captionGutter = 2;
    self.captionField = [[UITextView alloc] initWithFrame:CGRectMake(captionGutter, self.timestampLabel.frame.size.height + self.timestampLabel.frame.origin.y, VIEW_WIDTH - captionGutter*2, 72)];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"." attributes:@{
                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]                                                                                              }];
    [self.captionField setAttributedText:string];
    [self.captionField setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.1]];
    [self.captionField setTextAlignment:NSTextAlignmentCenter];
    [self.captionField setTextColor:PRIMARY_COLOR];
    [self.captionField setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:72]];
    self.captionField.delegate = self;
    [self.captionField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.captionField setReturnKeyType:UIReturnKeyDone];
    
    [self addSubview:self.captionField];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    YASwipingViewController *swipingParent = (YASwipingViewController *) self.presentingVC;
    [panGesture requireGestureRecognizerToFail:swipingParent.panGesture];
//    [panGesture requireGestureRecognizerToFail:((YASwipingViewController *) self.presentingVC).panGesture];
    
    [self.captionField addGestureRecognizer:panGesture];
    
    NSLog(@"adding gesture recognizers?");
    
    CGFloat tSize = 60;
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
    self.progressView.showsText = YES;
    self.progressView.lineWidth = 2;
    self.progressView.tintColor = PRIMARY_COLOR;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [self.video rename:textView.text];
        [self updateControls];
        
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

-(void)panned:(UIPanGestureRecognizer*)recognizer {
    CGPoint translatedPoint = [recognizer translationInView:[[recognizer view] superview]];
    NSLog(@"panned? %f", translatedPoint.y);
    
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
        if(!self.fontIndex || (self.fontIndex >= [self.fonts count])){
            self.fontIndex = 0;
        }

        [self.captionField setFont:[UIFont fontWithName:self.fonts[self.fontIndex] size:72]];
        self.fontIndex++;
    } else {
        [self.captionField becomeFirstResponder];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditingTapOut:)];
    [self addGestureRecognizer:tap];
}

- (void)doneEditingTapOut:(id)sender {
    [self removeGestureRecognizer:(UIGestureRecognizer *)sender];
    [self doneEditing];

}

- (void)doneEditing {
    [self.video rename:self.captionField.text];
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
            CGFloat translateX = xRadius - fabsf(xRadius*cosf(angle));
            CGFloat translateY = -fabsf(yRadius*sinf(angle));
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
    BOOL myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
    myVideo = YES;
    self.captionField.hidden = !myVideo;
    self.captionButton.hidden = !myVideo;
    self.shareButton.hidden = !myVideo;
    self.deleteButton.hidden = !myVideo;
    
    self.userLabel.text = self.video.creator;
    
    self.timestampLabel.text = [[YAUser currentUser] formatDate:self.video.createdAt]; //[[self.video.createdAt formattedAsTimeAgo] lowercaseString];
    [self.likeButton setBackgroundImage:self.video.like ? [UIImage imageNamed:@"Liked"] : [UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
    self.likeCount.hidden = (self.video.like && self.video.likers.count == 1);
    self.captionField.text = self.video.caption;
    [self.likeCount setTitle:self.video.likes ? [NSString stringWithFormat:@"%ld", (long)self.video.likes] : @""
                    forState:UIControlStateNormal];
    
    //get likers for video
    
}

- (void)shareButtonPressed {
    [self animateButton:self.shareButton withImageName:@"Share" completion:nil];
    [YAUtils showVideoOptionsForVideo:self.video];
}

#pragma mark - YAProgressView
- (void)downloadStarted:(NSNotification*)notif {
    NSOperation *op = notif.object;
    if(![self.video isInvalidated] && [op.name isEqualToString:self.video.url]) {
        [self showProgress:YES];
    }
}

- (void)showProgress:(BOOL)show {
    self.progressView.backgroundView.hidden = !show;
}

- (void)generationProgressChanged:(NSNotification*)notif {
    NSString *url = notif.object;
    if(![self.video isInvalidated] && [url isEqualToString:self.video.url]) {
        
        if(self.progressView) {
            NSNumber *value = notif.userInfo[kVideoDownloadNotificationUserInfoKey];
            [self.progressView setProgress:value.floatValue animated:NO];
            if (value.floatValue == 1.f) {
                [self setVideo:self.video shouldPlay:YES];
            }
        }
    }
    
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
@end

