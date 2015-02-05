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

@interface YAVideoPage ();
@property (nonatomic, strong) YAActivityView *activityView;

//overlay controls
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *likeCount;
@property BOOL likesShown;
@property (nonatomic, strong) NSMutableArray *likeLabels;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *deleteButton;

@end

@implementation YAVideoPage

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.activityView = [[YAActivityView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5)];
        [self addSubview:self.activityView];
        _playerView = [YAVideoPlayerView new];
        [self addSubview:self.playerView];
        
        [self.playerView addObserver:self forKeyPath:@"readyToPlay" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        
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
            self.playerView.URL = movUrl;
        else
            self.playerView.URL = nil;
        
        self.playerView.frame = self.bounds;
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(YAVideoPlayerView*)vc change:(NSDictionary *)change context:(void *)context{
    [self showLoading:!vc.readyToPlay];
}

- (void)showLoading:(BOOL)show {
    if(show) {
        if(self.activityView.isAnimating)
            return;
        
        [self bringSubviewToFront:self.activityView];
        [UIView animateWithDuration:0.5 animations:^{
            self.activityView.alpha = 1;
        } completion:^(BOOL finished) {
            [self.activityView startAnimating];
        }];
        
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.0 animations:^{
                    self.activityView.alpha = 0;
                    [self.activityView stopAnimating];
                }];
            });
        });
    }
}

- (void)dealloc {
    [self.playerView removeObserver:self forKeyPath:@"readyToPlay"];
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
    
    CGFloat captionHeight = 30;
    CGFloat captionGutter = 2;
    self.captionField = [[UITextField alloc] initWithFrame:CGRectMake(captionGutter, self.timestampLabel.frame.size.height + self.timestampLabel.frame.origin.y, VIEW_WIDTH - captionGutter*2, captionHeight)];
    [self.captionField setBackgroundColor:[UIColor clearColor]];
    [self.captionField setTextAlignment:NSTextAlignmentCenter];
    [self.captionField setTextColor:[UIColor whiteColor]];
    [self.captionField setFont:[UIFont fontWithName:BIG_FONT size:24]];
    self.captionField.delegate = self;
    [self.captionField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.captionField setReturnKeyType:UIReturnKeyDone];
    self.captionField.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.captionField.layer.shadowRadius = 1.0f;
    self.captionField.layer.shadowOpacity = 1.0;
    self.captionField.layer.shadowOffset = CGSizeZero;
    [self addSubview:self.captionField];
    
    CGFloat tSize = 60;
    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - tSize, 0, tSize, tSize)];
    [self.captionButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    [self.captionButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.captionButton setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
    [self addSubview:self.captionButton];
    
    CGFloat saveSize = 36;
    self.shareButton = [[UIButton alloc] initWithFrame:CGRectMake(/* VIEW_WIDTH - saveSize - */ 15, VIEW_HEIGHT - saveSize - 15, saveSize, saveSize)];
    [self.shareButton setBackgroundImage:[UIImage imageNamed:@"Save"] forState:UIControlStateNormal];
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
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSDictionary *attributes = @{NSFontAttributeName: textField.font};
    
    CGFloat width = [text sizeWithAttributes:attributes].width;
    
    if(width <= self.captionField.frame.size.width){
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.video rename:textField.text];
    [self updateControls];
    
    [self.captionField resignFirstResponder];
    return YES;
}

- (void)textButtonPressed {
    [self animateButton:self.captionButton withImageName:@"Text" completion:nil];

    [self.captionField becomeFirstResponder];
}

- (void)likeButtonPressed {
        if (!self.video.like) {
        [[YAServer sharedServer] likeVideo:self.video withCompletion:^(NSNumber* response, NSError *error) {
            [self.likeCount setTitle:[NSString stringWithFormat:@"%@", response]
                            forState:UIControlStateNormal];
        }];
    } else {
        [[YAServer sharedServer] unLikeVideo:self.video withCompletion:^(NSNumber* response, NSError *error) {
            [self.likeCount setTitle:[NSString stringWithFormat:@"%@", response]
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
        NSString *alertMessageText = [NSString stringWithFormat:@"Are you sure you want to delete this video from '%@'?", [YAUser currentUser].currentGroup.name];
        NSString *alertMessage = NSLocalizedString(alertMessageText, nil);
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Delete Video", nil)
                                              message:alertMessage
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                    style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action) {
                                        
                                    }]];
        
        [alertController addAction:[UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"Delete", nil)
                                    style:UIAlertActionStyleDestructive
                                    handler:^(UIAlertAction *action) {
                                        [self.video removeFromCurrentGroup];
                                        _video = nil;
                                    }]];
        
        [[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentedViewController] presentViewController:alertController animated:YES completion:nil];
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
    self.captionField.hidden = !myVideo;
    self.captionButton.hidden = !myVideo || self.video.caption.length;
    self.shareButton.hidden = !myVideo;
    self.deleteButton.hidden = !myVideo;

    
    self.userLabel.text = self.video.creator;
    
    self.timestampLabel.text = [[YAUser currentUser] formatDate:self.video.createdAt]; //[[self.video.createdAt formattedAsTimeAgo] lowercaseString];
    [self.likeButton setBackgroundImage:self.video.like ? [UIImage imageNamed:@"Liked"] : [UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
    self.captionField.text = self.video.caption;
    [self.likeCount setTitle:[NSString stringWithFormat:@"%ld", (long)self.video.likes]
                    forState:UIControlStateNormal];
    
    //get likers for video

}

#pragma mark - UIActionSheetDelegate 
- (void)actionSheet:(UIActionSheet *)popup didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            [self copyToClipboard];
            break;
        case 1:
        {
            [self shareToFacebook];
            break;
        }
        case 2:
            [self shareToTwitter];
            break;
        case 3:
            [self saveToCameraRoll];
            break;
        default:
            break;
    }
}

- (void)shareToFacebook
{
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        [controller setInitialText:NSLocalizedString(@"Check out my new Yaga video", nil)];
        [controller addURL:[NSURL URLWithString:self.video.url]];
        [[self topMostController] presentViewController:controller animated:YES completion:Nil];
    }
}

- (void)shareToTwitter
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:NSLocalizedString(@"Check out my new Yaga video", nil)];
        [tweetSheet addURL:[NSURL URLWithString:self.video.url]];
        [[self topMostController] presentViewController:tweetSheet animated:YES completion:nil];
    }
}

- (void)copyToClipboard
{
    NSURL *gifURL = [NSURL fileURLWithPath:[[YAUtils cachesDirectory] stringByAppendingPathComponent:self.video.gifFilename]];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setData:[[NSData alloc] initWithContentsOfURL:gifURL] forPasteboardType:@"com.compuserve.gif"];
}

- (void)saveToCameraRoll
{
    [UIView animateWithDuration:0.3 animations:^{
        self.shareButton.alpha = 0;
    }];
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURLAndSaveToCameraRoll:[YAUtils urlFromFileName:self.video.movFilename] completion:^(NSError *error) {
        if (error) {
            [YAUtils showNotification:NSLocalizedString(@"Can't save photos", @"") type:AZNotificationTypeError];
        }
        else {
            [YAUtils showNotification:NSLocalizedString(@"Video saved to camera roll successfully", @"") type:AZNotificationTypeMessage];
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            self.shareButton.alpha = 1;
        }];
    }];
}

- (void)shareButtonPressed {
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Select Sharing option:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                            NSLocalizedString(@"Save to clipboard", nil),
                            NSLocalizedString(@"Share on Facebook", nil),
                            NSLocalizedString(@"Share on Twitter", nil),
                            NSLocalizedString(@"Save to Camera Roll", nil),
                            nil];

    [popup showInView:[UIApplication sharedApplication].keyWindow];//    [self animateButton:self.shareButton withImageName:nil completion:^{
}

- (UIViewController*)topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end
