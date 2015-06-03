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
#import "AFURLConnectionOperation.h"
#import "YAServerTransactionQueue.h"
#import "YAEventManager.h"

#define LIKE_HEART_SIDE 40.f


@interface YAVideoCell ()

@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) UIImageView *likeImageView;
@property (nonatomic, assign) YAVideoCellState state;
@property (nonatomic, strong) dispatch_queue_t imageLoadingQueue;

@property (strong, nonatomic) FLAnimatedImageView *loaderView;

@property (strong, nonatomic) UILabel *username;
@property (strong, nonatomic) UILabel *eventCountLabel;
@property (strong, nonatomic) UIImageView *commentIcon;
@property (strong, nonatomic) UITextView *caption;
@property (strong, nonatomic) UIView *captionWrapper;

@property (strong, atomic) NSString *gifFilename;

@property (strong, nonatomic) YAActivityView *uploadingView;

@end

@implementation YAVideoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _gifView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        _gifView.contentMode = UIViewContentModeScaleAspectFill;
        _gifView.clipsToBounds = YES;
        _gifView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:self.gifView];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.imageLoadingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.96 alpha:1.0]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:AFNetworkingOperationDidStartNotification object:nil];
        
        self.loaderView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        static NSData* loaderData = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            loaderData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"loader" withExtension:@"gif"]];
        });

        dispatch_async(dispatch_get_main_queue(), ^{
            self.loaderView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:loaderData];
            [self.loaderView startAnimating];
        });

        self.backgroundView = self.loaderView;
        
        self.username = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width/2, self.bounds.size.height - 30, self.bounds.size.width/2 - 5, 30)];
        [self.username setTextAlignment:NSTextAlignmentRight];
        [self.username setMinimumScaleFactor:0.5];
        [self.username setAdjustsFontSizeToFitWidth:YES];
        [self.username setTextColor:[UIColor whiteColor]];
        [self.username setFont:[UIFont fontWithName:BIG_FONT size:20]];
        self.username.shadowColor = [UIColor blackColor];
        self.username.shadowOffset = CGSizeMake(1, 1);
        [self.contentView addSubview:self.username];

        self.commentIcon = [[UIImageView alloc] initWithFrame:CGRectMake(5, self.bounds.size.height-8-15, 15, 15)];
        [self.commentIcon setImage:[UIImage imageNamed:@"Comment_Filled"]];
        [self.contentView addSubview:self.commentIcon];
        
        self.eventCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5 + 15 + 3, self.bounds.size.height - 25, 40, 20)];
        [self.eventCountLabel setTextColor:[UIColor whiteColor]];
        [self.eventCountLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
        self.eventCountLabel.shadowColor = [UIColor blackColor];
        self.eventCountLabel.shadowOffset = CGSizeMake(1, 1);
        [self.contentView addSubview:self.eventCountLabel];
        
        
        CGRect captionFrame = CGRectMake(0, 0, MAX_CAPTION_WIDTH, CGFLOAT_MAX);
        self.captionWrapper = [[UIView alloc] initWithFrame:captionFrame];
        self.caption = [self textViewWithCaptionAttributes];
        self.caption.backgroundColor = [UIColor clearColor];
        self.caption.userInteractionEnabled = NO;
//        self.caption.backgroundColor = [UIColor redColor];
//        self.captionWrapper.backgroundColor = [UIColor greenColor];
        [self.captionWrapper addSubview:self.caption];
        [self.contentView addSubview:self.captionWrapper];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUploadVideo:) name:VIDEO_DID_UPLOAD object:nil];
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

- (void)setEventCount:(NSUInteger)eventCount {
    if (eventCount > 0) {
        self.eventCountLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long) eventCount];
        self.commentIcon.hidden = NO;
    } else {
        self.eventCountLabel.text = @"";
        self.commentIcon.hidden = YES;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [[YAEventManager sharedManager] killPrefetchForVideo:self.video];
    self.video = nil;
    self.gifView.image = nil;
    self.gifView.animatedImage = nil;
    self.state = YAVideoCellStateLoading;
//    self.commentIcon.hidden = YES;
//    self.commentIcon.image = nil;
//    self.commentIcon = nil;
    self.eventCountLabel.text = @"";
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_UPLOAD object:nil];
}

#pragma mark -

- (void)setVideo:(YAVideo *)video {
    if(_video == video)
        return;

    _video = video;
    
    self.gifFilename = self.video.gifFilename;
    
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
    [self updateCaptionAndUsername];
    
    switch (self.state) {
        case YAVideoCellStateLoading: {
            //[self showLoader:YES];
            break;
        }
        case YAVideoCellStateJPEGPreview: {
            //[self showLoader:YES];
            
            //a quick workaround for https://trello.com/c/AohUflf8/454-loader-doesn-t-show-up-on-your-own-recorded-videos
            [self showImageAsyncFromFilename:self.video.jpgFilename animatedImage:NO];
            break;
        }
        case YAVideoCellStateGIFPreview: {
            //loading is removed when gif is shown in showImageAsyncFromFilename
            [self showImageAsyncFromFilename:self.video.gifFilename animatedImage:YES];
            break;
        }
        default: {
            break;
        }
    }
    
    //uploading progress
    BOOL uploadInProgress = [[YAServerTransactionQueue sharedQueue] hasPendingUploadTransactionForVideo:self.video];
    [self showUploadingProgress:uploadInProgress];
 
}

- (void)showImageAsyncFromFilename:(NSString*)fileName animatedImage:(BOOL)animatedImage {
    if(!fileName.length)
        return;
    
    dispatch_async(self.imageLoadingQueue, ^{
        
        NSURL *dataURL = [YAUtils urlFromFileName:fileName];
        NSData *fileData = [NSData dataWithContentsOfURL:dataURL];
        id image;
        if(animatedImage)
            image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:fileData];
        else
            image = [UIImage imageWithData:fileData];
        
        if(image) {
            if([self.gifFilename isEqualToString:fileName]) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [self showCachedImage:image animatedImage:animatedImage];
                });
            }
            else {
                //invalidated.. no need to redraw and cache.
            }
        }
    });
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
    if(![self.video isInvalidated] && [op.name isEqualToString:self.video.gifUrl]) {
        [self showLoader:YES];
    }
}

- (void)showProgress:(BOOL)show {
    //do nothing, tile loader is used
}

- (void)showLoader:(BOOL)show {
    self.loaderView.hidden = !show;

    if(!self.loaderView.hidden && !self.loaderView.isAnimating)
        [self.loaderView startAnimating];
    
    // self.username.hidden = !show;
    self.captionWrapper.hidden = NO;
    
    [self updateCaptionAndUsername];
}

- (void)showUploadingProgress:(BOOL)show {
    if(show && !self.uploadingView) {
        const CGFloat monkeyWidth = 50;
        self.uploadingView = [[YAActivityView alloc] initWithFrame:CGRectMake(0, 0, monkeyWidth, monkeyWidth)];
        self.uploadingView.center = self.center;
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

- (void)updateCaptionAndUsername {
    NSString *caption = self.video.caption;
    
    if(caption.length) {
        self.captionWrapper.transform = CGAffineTransformIdentity;

        self.caption.text = caption;
        CGSize capSize = [self.caption sizeThatFits:CGSizeMake(MAX_CAPTION_WIDTH, CGFLOAT_MAX)];
        CGSize cellSize = self.bounds.size;

        self.captionWrapper.frame = CGRectMake(0,
                                        0,
                                        capSize.width, capSize.height);
        self.captionWrapper.center = CGPointMake(cellSize.width/2.f, cellSize.height/2.f);
        
        self.caption.frame = CGRectMake(0, 0, capSize.width, capSize.height);
        self.caption.center = CGPointMake(self.captionWrapper.frame.size.width/2.f, self.captionWrapper.frame.size.height/2.f);
        CGFloat scale = self.bounds.size.width / STANDARDIZED_DEVICE_WIDTH;
        self.captionWrapper.transform = CGAffineTransformMakeScale(scale, scale);

        self.captionWrapper.hidden = NO;
    } else {
        self.caption.text = @"";
        self.captionWrapper.hidden = YES;
    }
    self.username.textAlignment = NSTextAlignmentRight;
    self.username.text = self.video.creator;
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

- (NSMutableAttributedString *)attributedStringFromString:(NSString *)input font:(UIFont*)font {
    if (!input.length) return
        [NSMutableAttributedString new];
    
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:input];
    
    [result addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH] range:NSMakeRange(0, result.length)];
    [result addAttribute:NSStrokeColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, result.length)];
    
    if(font)
        [result addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, result.length)];
    
    return result;
}

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
    textView.editable = NO;
    textView.userInteractionEnabled = NO;
    textView.textContainer.lineFragmentPadding = 0;
    textView.textContainerInset = UIEdgeInsetsZero;
    
    return textView;
}

@end

