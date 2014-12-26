//
//  TiCell.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YAVideoCell.h"
#import "YAUtils.h"
#import "YAUser.h"
#import "AZNotification.h"

@interface YAVideoCell ()
@property (nonatomic, strong) NSMutableArray *controls;
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UIButton *saveButton;
@end

@implementation YAVideoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _gifView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        _gifView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:self.gifView];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)dealloc {
}

- (void)setPlayerVC:(AVPlaybackViewController *)playerVC {
    if(_playerVC == playerVC)
        return;
    
    if(playerVC) {
        self.gifView.alpha = 0;
        playerVC.view.alpha = 0;
        
        playerVC.view.frame = self.bounds;
        [self.contentView addSubview:playerVC.view];
        
        // playerVC.view.transform = CGAffineTransformMakeScale(1.1, 1.1);
        [UIView animateWithDuration:0.3 animations:^{
            //playerVC.view.transform = CGAffineTransformIdentity;
            
            playerVC.view.alpha = 1;
        }];
        
        if(!self.controls.count)
            [self performSelector:@selector(initOverlayControls) withObject:nil afterDelay:0.1];
        else {
            [self performSelector:@selector(updateControls) withObject:nil afterDelay:0.1];
        }
    }
    else {
        [self showControls:NO];
        [_playerVC.view removeFromSuperview];
        [self.contentView addSubview:self.gifView];
        [UIView animateWithDuration:0.3 animations:^{
            self.gifView.alpha = 1;
        }];
    }
    
    _playerVC = playerVC;
} 


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.playerVC = nil;
    self.video = nil;
    [self showControls:NO];
}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//    
//    //going to grid
//   // [self showControls:self.playerVC != nil];
//}
//
//- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
//{
//    [super applyLayoutAttributes:layoutAttributes];
//    [self layoutIfNeeded];
//}

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
    
    CGFloat likeSize = 42;
    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - likeSize)/2, VIEW_HEIGHT - likeSize - 12, likeSize, likeSize)];
    [self.likeButton addTarget:self action:@selector(likeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.controls addObject:self.likeButton];
    
    CGFloat tSize = 60;
    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - tSize - 12, 12, tSize, tSize)];
    [self.captionButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    [self.captionButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.captionButton setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
    [self.controls addObject:self.captionButton];
    [self.contentView addSubview:self.captionButton];
    
    CGFloat saveSize = 36;
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(/* VIEW_WIDTH - saveSize - */ 15, VIEW_HEIGHT - saveSize - 15, saveSize, saveSize)];
    [self.saveButton setBackgroundImage:[UIImage imageNamed:@"Save"] forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.controls addObject:self.saveButton];
    
    if(self.video)
        [self updateControls];
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

- (void)saveButtonPressed {
    [self animateButton:self.saveButton withImageName:@"Save" completion:^{
        NSString *path = [YAUtils urlFromFileName:self.video.movFilename].path;
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError: contextInfo:), nil);
    }];
}

- (void)animateButton:(UIButton*)button withImageName:(NSString*)imageName completion:(void (^)(void))completion {
    [UIView animateKeyframesWithDuration:0.3 delay:0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
            button.transform = CGAffineTransformMakeScale(1.5, 1.5);
        }];
        
        if([button backgroundImageForState:UIControlStateNormal])
            [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        else
            [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.4 animations:^{
            button.transform = CGAffineTransformIdentity;
        }];
        
    } completion:^(BOOL finished) {
        if(completion)
            completion();
    }];

}

-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [AZNotification showNotificationWithTitle:NSLocalizedString(@"Video saved to the camera roll successfully", @"")controller:[UIApplication sharedApplication].keyWindow.rootViewController
                             notificationType:AZNotificationTypeSuccess
                                 startedBlock:nil];
}

- (void)showControls:(BOOL)show {
    if(show) {
        for(UIView *v in self.controls){
            if(!v.superview)
                [self addSubview:v];
            
            v.alpha = 0;
            [self bringSubviewToFront:v];
        }

        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView animateWithDuration:0.3 animations:^{
            for(UIView *v in self.controls){
                v.alpha = 1;
            }
        }];
    }
    else {
        for(UIView *v in self.controls){
            [v removeFromSuperview];
        }
        
    }
}

- (void)setVideo:(YAVideo *)video {
    if(_video == video)
        return;
    
    _video = video;
    
    if(!_video)
        return;
    
    [self updateControls];
}

- (void)updateControls {
    if(!self.controls)
        return;
    
    self.userLabel.text = self.video.creator;
    self.timestampLabel.text = [[YAUser currentUser] formatDate:self.video.createdAt];
    self.captionField.text = @"";
    [self.likeButton setBackgroundImage:self.video.like ? [UIImage imageNamed:@"Liked"] : [UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
    self.captionField.text = self.video.caption;
    
    if(self.video && self.playerVC)
        [self showControls:YES];
}

@end

