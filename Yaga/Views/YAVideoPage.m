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

@interface YAVideoPage ();
@property (nonatomic, strong) YAActivityView *activityView;
@property (nonatomic, assign) BOOL observingPlayer;

//overlay controls
@property (nonatomic, strong) NSMutableArray *controls;
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *likeCount;
@property BOOL likesShown;
@property (nonatomic, strong) NSMutableArray *likeLabels;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *deleteButton;

@end

@implementation YAVideoPage

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.activityView = [[YAActivityView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5)];
        [self addSubview:self.activityView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.activityView.frame = CGRectMake(0, 0, self.bounds.size.width/5, self.bounds.size.width/5);
    self.activityView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)willRemoveSubview:(UIView *)subview {
    if([subview class] == [YAVideoPlayerView class])
        [self showLoading:YES];
}

- (void)setVideo:(YAVideo *)video {
    _video = video;
    
    [self initOverlayControls];
    [self showControls:YES];
}

- (void)setPlayerView:(YAVideoPlayerView *)newPlayerView {
    if(self.playerView == newPlayerView && self.playerView.superview == self)
        return;
    
    if(!newPlayerView) {
        if(self.observingPlayer) {
            [_playerView removeObserver:self forKeyPath:@"readyToPlay"];
        }
        [self.playerView removeFromSuperview];
    }
    else {
        if(newPlayerView.superview) {
            YAVideoPage *page = (YAVideoPage*)newPlayerView.superview;
            page.playerView = nil;
        }
        newPlayerView.frame = self.bounds;
        [self insertSubview:newPlayerView belowSubview:self.activityView];
        
        if(self.observingPlayer) {
            [_playerView removeObserver:self forKeyPath:@"readyToPlay"];
        }
        
        if(!newPlayerView.readyToPlay) {
            [newPlayerView addObserver:self forKeyPath:@"readyToPlay" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            self.observingPlayer = YES;
            [self showLoading:YES];
        }
        else {
            self.observingPlayer = NO;
            [self showLoading:NO];
        }
    }
    
    _playerView = newPlayerView;
    
    [self showControls:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(YAVideoPlayerView*)vc change:(NSDictionary *)change context:(void *)context{
    [self showLoading:!vc.readyToPlay];
}

- (void)showLoading:(BOOL)show {
    
   // NSLog(@"showLoading: %d, page: %@, url: %@", show, self, self.playerView.URL.lastPathComponent);
    
    if(show) {
        [self.activityView startAnimating];
        
        [self bringSubviewToFront:self.activityView];
        [UIView animateWithDuration:0.5 animations:^{
            self.activityView.alpha = 1;
        }];
        
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.5 animations:^{
                    self.activityView.alpha = 0;
                    [self.activityView stopAnimating];
                }];
            });
        });
    }
}

- (void)dealloc {
    if(self.observingPlayer) {
        [self.playerView removeObserver:self forKeyPath:@"readyToPlay"];
    }
}

#pragma mark - Overlay controls

- (void)initOverlayControls {
    self.controls = [[NSMutableArray alloc] init];
    
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
    [self.controls addObject:self.userLabel];
    
    CGFloat timeHeight = 24;
    self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(gutter, height + 12, VIEW_WIDTH - gutter*2, timeHeight)];
    [self.timestampLabel setTextAlignment:NSTextAlignmentCenter];
    [self.timestampLabel setTextColor:[UIColor whiteColor]];
    [self.timestampLabel setFont:[UIFont fontWithName:BIG_FONT size:14]];
    self.timestampLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.timestampLabel.layer.shadowRadius = 1.0f;
    self.timestampLabel.layer.shadowOpacity = 1.0;
    self.timestampLabel.layer.shadowOffset = CGSizeZero;
    [self.controls addObject:self.timestampLabel];
    
    if([self.video.creator isEqualToString:[[YAUser currentUser] username]]) {
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
        [self.controls addObject:self.captionField];
        
        CGFloat tSize = 60;
        self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - tSize, 0, tSize, tSize)];
        [self.captionButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
        [self.captionButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.captionButton setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
        [self.controls addObject:self.captionButton];
        [self addSubview:self.captionButton];
        
        CGFloat saveSize = 36;
        self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(/* VIEW_WIDTH - saveSize - */ 15, VIEW_HEIGHT - saveSize - 15, saveSize, saveSize)];
        [self.saveButton setBackgroundImage:[UIImage imageNamed:@"Save"] forState:UIControlStateNormal];
        [self.saveButton addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.controls addObject:self.saveButton];
        
        self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake( VIEW_WIDTH - saveSize - 15, VIEW_HEIGHT - saveSize - 15, saveSize, saveSize)];
        [self.deleteButton setBackgroundImage:[UIImage imageNamed:@"Delete"] forState:UIControlStateNormal];
        [self.deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.controls addObject:self.deleteButton];
    }
    
    CGFloat likeSize = 42;
    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - likeSize)/2, VIEW_HEIGHT - likeSize - 12, likeSize, likeSize)];
    [self.likeButton addTarget:self action:@selector(likeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.controls addObject:self.likeButton];
    
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
    [self.controls addObject:self.likeCount];
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
    
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.video.caption = textField.text;
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [self.captionField resignFirstResponder];
    return YES;
}

- (void)textButtonPressed {
    [self animateButton:self.captionButton withImageName:@"Text" completion:nil];
    
    [self.captionField becomeFirstResponder];
}

- (void)likeButtonPressed {
    
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
    // TODO: insert realm code here to get correct likes; hardcoded for now
    NSArray *likes = @[@"ninajvir", @"rjvir", @"chriwend", @"a_j_r"];//, @"b9speed", @"dlg", @"valentin", @"iegor", @"victor", @"kyle"];
    
    CGFloat origin = self.likeCount.frame.origin.y;
    CGFloat height = 24;
    CGFloat width = 72;
    
    self.likeLabels = [[NSMutableArray alloc] init];
    
    for(NSString *like in likes){
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.likeCount.frame.origin.x + self.likeCount.frame.size.width - width, origin + self.likeCount.frame.size.height/2, width, height)];
        [label setText:like];
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

- (void)saveButtonPressed {
    __block UIActivityIndicatorView *savingActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    savingActivityView.frame = self.saveButton.frame;
    savingActivityView.alpha = 0;
    [self addSubview:savingActivityView];
    [savingActivityView startAnimating];
    
    [self animateButton:self.saveButton withImageName:nil completion:^{
        [UIView animateWithDuration:0.3 animations:^{
            self.saveButton.alpha = 0;
            savingActivityView.alpha = 1;
        }];
        [[YAAssetsCreator sharedCreator] addBumberToVideoAtURLAndSaveToCameraRoll:[YAUtils urlFromFileName:self.video.movFilename] completion:^(NSError *error) {
            if (error) {
                [YAUtils showNotification:NSLocalizedString(@"Can't save photos", @"") type:AZNotificationTypeError];
            }
            else {
                [YAUtils showNotification:NSLocalizedString(@"Video saved to camera roll successfully", @"") type:AZNotificationTypeMessage];
            }
            
            [UIView animateWithDuration:0.3 animations:^{
                self.saveButton.alpha = 1;
                savingActivityView.alpha = 0;
                
            } completion:^(BOOL finished) {
                [savingActivityView removeFromSuperview];
            }];
        }];
    }];
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
                                    }]];
        
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
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
- (void)showControls:(BOOL)show {
    if(show) {
        for(UIView *v in self.controls){
            if(!v.superview) {
                [self addSubview:v];
            }
            
            [self bringSubviewToFront:v];
        }
    }
    else {
        for(UIView *v in self.controls){
            [v removeFromSuperview];
        }
    }
    
    if(show)
        [self updateControls];
}

- (void)updateControls {
    if(!self.controls)
        return;
    
    self.userLabel.text = self.video.creator;
    
    self.timestampLabel.text = [[YAUser currentUser] formatDate:self.video.createdAt]; //[[self.video.createdAt formattedAsTimeAgo] lowercaseString];
    self.captionField.text = @"";
    [self.likeButton setBackgroundImage:self.video.like ? [UIImage imageNamed:@"Liked"] : [UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
    self.captionField.text = self.video.caption;
    [self.likeCount setTitle:@"4" forState:UIControlStateNormal]; //TODO: make real number from realm
}

@end
