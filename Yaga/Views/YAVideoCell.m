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
#import "NSDate+NVTimeAgo.h"
#import "YAAssetsCreator.h"
#import "YAActivityView.h"
#import "YAImageCache.h"
#import "AFURLConnectionOperation.h"
#import "YAProgressView.h"
#import "YADownloadManager.h"

#define LIKE_HEART_SIDE 40.f


@interface YAVideoCell ()


@property (nonatomic, strong) YAProgressView *progressView;
@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) UIImageView *likeImageView;
@property (nonatomic, assign) YAVideoCellState state;
@property (nonatomic, strong) dispatch_queue_t imageLoadingQueue;

@property (strong, nonatomic) UIView *loader;
@property (strong, nonatomic) NSTimer *loaderTimer;
@property (strong, nonatomic) NSMutableArray *loaderTiles;

@property (strong, nonatomic) UILabel *username;
@property (strong, nonatomic) UILabel *caption;

@end

@implementation YAVideoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        
        
        _gifView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        _gifView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:self.gifView];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.imageLoadingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.96 alpha:1.0]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:AFNetworkingOperationDidStartNotification object:nil];
        
        self.loader = [[UIView alloc] initWithFrame:self.bounds];
//        [self.loader setBackgroundColor:PRIMARY_COLOR];
        self.loaderTiles = [[NSMutableArray alloc] init];
        CGFloat lwidth = self.loader.frame.size.width/((float)LOADER_WIDTH);
        CGFloat lheight = self.loader.frame.size.height/((float)LOADER_HEIGHT);
        
        NSLog(@"lwidth: %f, lheight: %f", lwidth, lheight);
        
        for(int i = 0; i < LOADER_WIDTH*LOADER_HEIGHT; i++){
            
            int xPos = i%LOADER_WIDTH;
            int yPos = i/LOADER_HEIGHT;
            
            UIView *loaderTile = [[UIView alloc] initWithFrame:CGRectMake(xPos * lwidth, yPos*lheight, lwidth, lheight)];
            [self.loader addSubview:loaderTile];
            [self.loaderTiles addObject:loaderTile];
        }
        
        [self addSubview:self.loader];
        
        self.username = [[UILabel alloc] initWithFrame:self.bounds];
        
        [self.username setTextAlignment:NSTextAlignmentCenter];
        [self.username setTextColor:PRIMARY_COLOR];
        [self.username setFont:[UIFont fontWithName:@"AvenirNext-Heavy" size:30]];
        [self addSubview:self.username];
        
        CGRect captionFrame = CGRectMake(12, 12, self.bounds.size.width - 24, self.bounds.size.height - 24);
        self.caption = [[UILabel alloc] initWithFrame:captionFrame];
        [self.caption setNumberOfLines:0];
        [self.caption setTextColor:PRIMARY_COLOR];
        [self.caption setTextAlignment:NSTextAlignmentCenter];
        
        [self addSubview:self.caption];

//        const CGFloat radius = 40;
//        self.progressView = [[YAProgressView alloc] initWithFrame:self.bounds];
//        self.progressView.radius = radius;
//        UIView *progressBkgView = [[UIView alloc] initWithFrame:self.bounds];
//        progressBkgView.backgroundColor = [UIColor clearColor];
//        self.progressView.backgroundView = progressBkgView;
//        self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
//        [self.contentView addSubview:self.progressView];
//        
//        NSDictionary *views = NSDictionaryOfVariableBindings(_progressView);
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_progressView]-0-|" options:0 metrics:nil views:views]];
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_progressView]-0-|" options:0 metrics:nil views:views]];
//        
//        self.progressView.indeterminate = YES;
//        self.progressView.showsText = YES;
//        self.progressView.lineWidth = 2;
//        self.progressView.tintColor = PRIMARY_COLOR;
        
//        // Add gesture recognizer for double tap like or change title
//        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
//        tapRecognizer.numberOfTapsRequired = 2;
//        tapRecognizer.delaysTouchesBegan = YES;
//        // Unkoment this for double tap gesture recognizer
//        //[self addGestureRecognizer:tapRecognizer];
//        
//        self.likeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, LIKE_HEART_SIDE, LIKE_HEART_SIDE)];
//        self.likeImageView.layer.opacity = 0.0f;
//        self.likeImageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
//        [self addSubview:self.likeImageView];
//        
//        CGFloat captionHeight = 30;
//        self.captionField = [[UITextField alloc] initWithFrame:CGRectMake(0.f, 0.f, self.bounds.size.width*0.7f, captionHeight)];
//        self.captionField.center = self.likeImageView.center;
//        [self.captionField setBackgroundColor:[UIColor clearColor]];
//        [self.captionField setTextAlignment:NSTextAlignmentCenter];
//        [self.captionField setTextColor:[UIColor whiteColor]];
//        [self.captionField setFont:[UIFont fontWithName:BIG_FONT size:24]];
//        self.captionField.delegate = self;
//        [self.captionField setAutocorrectionType:UITextAutocorrectionTypeNo];
//        [self.captionField setReturnKeyType:UIReturnKeyDone];
//        self.captionField.layer.shadowColor = [[UIColor blackColor] CGColor];
//        self.captionField.layer.shadowRadius = 1.0f;
//        self.captionField.layer.shadowOpacity = 1.0;
//        self.captionField.layer.shadowOffset = CGSizeZero;
//        self.captionField.enabled = NO;
//        [self addSubview:self.captionField];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressChanged:) name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generationProgressChanged:) name:VIDEO_DID_GENERATE_PART_NOTIFICATION object:nil];
        
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
    
    self.progressView.progress = 0;
    [self.progressView setCustomText:@""];
    
    self.video = nil;
    self.gifView.image = nil;
    self.gifView.animatedImage = nil;
    self.state = YAVideoCellStateLoading;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_GENERATE_PART_NOTIFICATION object:nil];
}

#pragma mark -

- (void)setVideo:(YAVideo *)video {
    [self.progressView setCustomText:video.creator];
    NSString *creator = video.creator;
    if (!creator.length) {
        self.username.attributedText = [NSAttributedString new];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSAttributedString *str = [self myLabelAttributes:creator];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.username.attributedText = str;
            });
        });
    }
    NSString *caption = video.caption;
    if(caption){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSAttributedString *str = [self myLabelAttributes:caption];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.caption.attributedText = str;
                [self.caption setFont:[UIFont fontWithName:CAPTION_FONTS[video.font] size:30]];
            });
        });
    } else {
        self.caption.attributedText = [NSAttributedString new];
    }
    
    if(_video == video)
        return;

    _video = video;
    
    [self updateState];
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
            [self showLoader:YES];
            break;
        }
        case YAVideoCellStateJPEGPreview: {
            [self showLoader:YES];
            [self showImageAsyncFromFilename:self.video.jpgFilename animatedImage:NO];
            break;
        }
        case YAVideoCellStateGIFPreview: {
            //loading is removed when gif is shown in showImageAsyncFromFilename
            [self showLoader:NO];
            [self showImageAsyncFromFilename:self.video.gifFilename animatedImage:YES];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)showImageAsyncFromFilename:(NSString*)fileName animatedImage:(BOOL)animatedImage {
    if(!fileName.length)
        return;
    
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
            
            if(image) {
                [[YAImageCache sharedCache] setObject:image forKey:fileName];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showCachedImage:image animatedImage:animatedImage];
                });
            }
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

#pragma mark - Download progress bar
- (void)downloadStarted:(NSNotification*)notif {
    NSOperation *op = notif.object;
    if(![self.video isInvalidated] && [op.name isEqualToString:self.video.url]) {
        [self showLoader:YES];
    }
}

- (void)showProgress:(BOOL)show {
    self.progressView.backgroundView.hidden = !show;
}

- (void)showLoader:(BOOL)show {
    self.loader.hidden = !show;
    self.username.hidden = !show;
    self.caption.hidden = show;
    if(show){
        if(!self.loaderTimer){
            self.loaderTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                                                target: self
                                                              selector:@selector(loaderTick:)
                                                              userInfo: nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.loaderTimer forMode:NSRunLoopCommonModes];
        }
    } else {
        if([self.loaderTimer isValid]){
            NSLog(@"valid?!?!");
            [self.loaderTimer invalidate];
        }
        self.loaderTimer = nil;
    }
    
}

- (void)loaderTick:(NSTimer *)timer {
    dispatch_async(dispatch_get_main_queue(), ^{
        //Your main thread code goes in here
        for(UIView *v in self.loaderTiles){
            UIColor *p = PRIMARY_COLOR;
            p = [p colorWithAlphaComponent:(arc4random() % 128 / 256.0)];
//            CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
//            CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
//            CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
//            UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
//            
            [v setBackgroundColor:p];
        }

    });
//    NSLog(@"loader tick!");
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

- (NSMutableAttributedString *)myLabelAttributes:(NSString *)input
{
    NSMutableAttributedString *labelAttributes = [[NSMutableAttributedString alloc] initWithString:input];

    [labelAttributes addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-5.0] range:NSMakeRange(0, labelAttributes.length)];
    [labelAttributes addAttribute:NSStrokeColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, labelAttributes.length)];
    
    return labelAttributes;
}

@end

