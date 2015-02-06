//
//  TiCell.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//
#import "YAServer.h"
#import "YAVideoCell.h"
#import "YAUtils.h"
#import "YAUser.h"
#import "AZNotification.h"
#import "NSDate+NVTimeAgo.h"
#import "YAAssetsCreator.h"
#import "YAActivityView.h"
#import "YAImageCache.h"
#import "AFURLConnectionOperation.h"
#import "YAProgressView.h"
#import "YADownloadManager.h"

#define LIKE_HEART_SIDE 40.f

typedef NS_ENUM(NSUInteger, YAVideoCellState) {
    YAVideoCellStateLoading = 0,
    YAVideoCellStateJPEGPreview,
    YAVideoCellStateGIFPreview,
    YAVideoCellStateVideoPreview,
};

@interface YAVideoCell ()


@property (nonatomic, strong) YAProgressView *progressView;
@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) UIImageView *likeImageView;
@property (nonatomic, assign) YAVideoCellState state;

@property (nonatomic, strong) dispatch_queue_t imageLoadingQueue;
@end

@implementation YAVideoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        
        
        _gifView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        _gifView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:self.gifView];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.imageLoadingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.96 alpha:1.0]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:AFNetworkingOperationDidStartNotification object:nil];
        
        const CGFloat radius = 40;
        self.progressView = [[YAProgressView alloc] initWithFrame:self.bounds];
        self.progressView.radius = radius;
        UIView *progressBkgView = [[UIView alloc] initWithFrame:self.bounds];
        progressBkgView.backgroundColor = [UIColor clearColor];
        self.progressView.backgroundView = progressBkgView;
        self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.progressView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_progressView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_progressView]-0-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_progressView]-0-|" options:0 metrics:nil views:views]];
        
        self.progressView.indeterminate = NO;
        self.progressView.showsText = YES;
        self.progressView.lineWidth = 2;
        self.progressView.tintColor = PRIMARY_COLOR;
        
        // Add gesture recognizer for double tap like or change title
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        tapRecognizer.numberOfTapsRequired = 2;
        tapRecognizer.delaysTouchesBegan = YES;
        [self addGestureRecognizer:tapRecognizer];
        
        self.likeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, LIKE_HEART_SIDE, LIKE_HEART_SIDE)];
        self.likeImageView.layer.opacity = 0.0f;
        self.likeImageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [self addSubview:self.likeImageView];
        
        CGFloat captionHeight = 30;
        self.captionField = [[UITextField alloc] initWithFrame:CGRectMake(0.f, 0.f, self.bounds.size.width*0.7f, captionHeight)];
        self.captionField.center = self.likeImageView.center;
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
        self.captionField.enabled = NO;
        [self addSubview:self.captionField];
    }
    return self;
}

- (void)animateGifView:(BOOL)animate {
    if(animate) {
        if(!self.gifView.isAnimating) {
            [self.gifView startAnimating];
        }
    }
    else {
        if(self.gifView.isAnimating) {
            [self.gifView stopAnimating];
        }
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_GENERATE_PART_NOTIFICATION object:nil];
    
    self.progressView.progress = 0;
    [self.progressView setCustomText:@""];
    
    self.video = nil;
    self.gifView.image = nil;
    self.gifView.animatedImage = nil;
    self.state = YAVideoCellStateLoading;
}

#pragma mark -

- (void)setVideo:(YAVideo *)video {
    
    [self.progressView setCustomText:video.creator];
    
    if(_video == video)
        return;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressChanged:) name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generationProgressChanged:) name:VIDEO_DID_GENERATE_PART_NOTIFICATION object:nil];
    
    _video = video;
    
    [self setNeedsLayout];
}

- (void)updateState {
    if(self.video.gifFilename.length)
        self.state = YAVideoCellStateGIFPreview;
    else if(self.video.jpgFilename.length)
        self.state = YAVideoCellStateJPEGPreview;
    else
        self.state = YAVideoCellStateLoading;
    
    
    [self updateCell];
}

- (void)updateCell {
    switch (self.state) {
        case YAVideoCellStateLoading: {
            [self showProgress:YES];
            break;
        }
        case YAVideoCellStateJPEGPreview: {
            [self showProgress:YES];
            [self showImageAsyncFromFilename:self.video.jpgFilename animatedImage:NO];
            break;
        }
        case YAVideoCellStateGIFPreview: {
            //loading is removed when gif is shown in showImageAsyncFromFilename
            [self showProgress:NO];
            [self showImageAsyncFromFilename:self.video.gifFilename animatedImage:YES];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)showImageAsyncFromFilename:(NSString*)fileName animatedImage:(BOOL)animatedImage {
    id cachedImage = [[YAImageCache sharedCache] objectForKey:fileName];
    if(cachedImage) {
        [self showCachedImage:cachedImage animatedImage:animatedImage];
    }
    else {
        dispatch_async(self.imageLoadingQueue, ^{
            
            NSURL *dataURL = [YAUtils urlFromFileName:fileName];
            NSData *fileData = [NSData dataWithContentsOfURL:dataURL];
            id image;
            if(animatedImage)
                image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:fileData];
            else
                image = [UIImage imageWithData:fileData];
            
            [[YAImageCache sharedCache] setObject:image forKey:fileName];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showCachedImage:image animatedImage:animatedImage];
            });
        });
    }
}

- (void)showCachedImage:(id)image animatedImage:(BOOL)animatedImage {
    
    if(animatedImage) {
        self.gifView.animatedImage = image;
        [self.gifView startAnimating];
        
    } else{
        self.gifView.image = image;
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateState];
}

#pragma mark - Download progress bar
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
            [self.progressView setCustomText:self.video.creator];
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

#pragma mark - UITapGestureRecognizer actions 

- (void)doubleTap:(UIGestureRecognizer *)sender {
    BOOL myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
    if (!myVideo) {
        if (!self.video.like) {
            [[YAServer sharedServer] likeVideo:self.video withCompletion:^(NSNumber* response, NSError *error) {

            }];
        } else {
            [[YAServer sharedServer] unLikeVideo:self.video withCompletion:^(NSNumber* response, NSError *error) {
            }];
        }
        
        [[RLMRealm defaultRealm] beginWriteTransaction];
        self.video.like = !self.video.like;
        [[RLMRealm defaultRealm] commitWriteTransaction];
        
        UIImage *likeImage = self.video.like ? [UIImage imageNamed:@"Liked"] : [UIImage imageNamed:@"Like"];
        self.likeImageView.image = likeImage;

        CABasicAnimation *theAnimation;
        theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
        theAnimation.duration=0.4;
        theAnimation.autoreverses = YES;
        theAnimation.fromValue=[NSNumber numberWithFloat:0.0];
        theAnimation.toValue=[NSNumber numberWithFloat:1.0];
        
        [self.likeImageView.layer addAnimation:theAnimation forKey:@"animateOpacity"];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:SCROLL_TO_CELL_INDEXPATH_NOTIFICATION object:self];
        self.captionField.enabled = YES;
        [self.captionField becomeFirstResponder];
    }
}

#pragma mark - UITextFieldDelegate 
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
    [self.captionField resignFirstResponder];
    self.captionField.enabled = NO;
    return YES;
}

@end

