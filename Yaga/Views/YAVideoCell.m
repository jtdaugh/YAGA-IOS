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
#import "AFDownloadRequestOperation.h"

#define LIKE_HEART_SIDE 40.f


@interface YAVideoCell ()

@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) UIImageView *likeImageView;
@property (nonatomic, assign) YAVideoCellState state;
@property (nonatomic, strong) dispatch_queue_t imageLoadingQueue;

@property (strong, nonatomic) UILabel *username;
@property (strong, nonatomic) UILabel *eventCountLabel;
@property (strong, nonatomic) UIImageView *commentIcon;
@property (strong, nonatomic) UILabel *caption;
@property (strong, nonatomic) UIView *captionWrapper;

@property (strong, atomic) NSString *gifFilename;

@property (strong, nonatomic) FLAnimatedImageView *uploadingView;

@property (nonatomic, assign) BOOL gifWasPaused;
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
        self.caption = [[UILabel alloc] init];
        self.caption.numberOfLines = 0;
        
        self.caption.backgroundColor = [UIColor clearColor];
        self.caption.userInteractionEnabled = NO;
        self.caption.textAlignment = NSTextAlignmentCenter;
        [self.captionWrapper addSubview:self.caption];
        [self.contentView addSubview:self.captionWrapper];

        self.contentView.layer.masksToBounds = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoChanged:) name:VIDEO_CHANGED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:AFNetworkingOperationDidStartNotification object:nil];

        self.shouldPlayGifAutomatically = YES;
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
    if (eventCount >= kMaxEventsFetchedPerVideo) {
        self.eventCountLabel.text = [NSString stringWithFormat:@"%d+",kMaxEventsFetchedPerVideo];
        self.commentIcon.hidden = NO;
    } else if (eventCount > 0) {
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
    
    self.video = nil;

    [self updateState];
    
    self.eventCountLabel.text = @"";
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
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
    
    BOOL showLoader = NO;
    switch (self.state) {
        case YAVideoCellStateLoading: {
            showLoader = self.video != nil;
            break;
        }
        case YAVideoCellStateJPEGPreview: {
            showLoader = self.video != nil;
            
            //a quick workaround for https://trello.com/c/AohUflf8/454-loader-doesn-t-show-up-on-your-own-recorded-videos
            //[self showImageAsyncFromFilename:self.video.jpgFilename animatedImage:NO];
            break;
        }
        case YAVideoCellStateGIFPreview: {
            //loading is removed when gif is shown in showImageAsyncFromFilename
            [self showImageAsyncFromFilename:self.video.gifFilename animatedImage:YES];
            showLoader = NO;
            break;
        }
        default: {
            break;
        }
    }
    
    if(showLoader) {
        static NSData* loaderData = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            loaderData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"loader" withExtension:@"gif"]];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.gifView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:loaderData];
            [self.gifView startAnimating];
        });
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
        self.gifView.shouldPlayGifAutomatically = self.shouldPlayGifAutomatically;
        self.gifView.animatedImage = image;
    } else{
        self.gifView.image = image;
    }
}

#pragma mark - Download progress bar
- (void)downloadStarted:(NSNotification*)notif {
    AFDownloadRequestOperation *op = notif.object;
    
    if(![self.video isInvalidated] && [op.request.URL.absoluteString isEqualToString:self.video.gifUrl]) {
        [self updateCaptionAndUsername];
    }
}

- (void)showProgress:(BOOL)show {
    //do nothing, tile loader is used
}

- (void)showUploadingProgress:(BOOL)show {
    if(show) {
        const CGFloat uploadingWith = 30;
        if (!self.uploadingView) {
            self.uploadingView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(3, self.bounds.size.height - 30, uploadingWith, uploadingWith)];
            [self addSubview:self.uploadingView];
        }
        
        static NSData* uploaderGifData = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            uploaderGifData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"uploading" withExtension:@"gif"]];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.uploadingView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:uploaderGifData];
            [self.uploadingView startAnimating];
            self.commentIcon.alpha = 0;
            self.eventCountLabel.alpha = 0;
        });
    }
    else {
        if(self.uploadingView) {
            [self.uploadingView removeFromSuperview];
            self.uploadingView = nil;
        }
        self.commentIcon.alpha = 1;
        self.eventCountLabel.alpha = 1;
    }
}

- (void)videoChanged:(NSNotification*)notif {
    if([self.video isEqual:notif.object]) {
        //uploading progress
        BOOL uploadInProgress = [[YAServerTransactionQueue sharedQueue] hasPendingUploadTransactionForVideo:self.video];
        [self showUploadingProgress:uploadInProgress];
    }
}

- (void)updateCaptionAndUsername {
    NSString *caption = self.video.caption;
    
    self.captionWrapper.hidden = NO;
    
    if(caption.length) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:caption attributes:@{
                                                                                                         NSStrokeColorAttributeName:[UIColor whiteColor],                                                            NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH],NSForegroundColorAttributeName:PRIMARY_COLOR,                                                    NSBackgroundColorAttributeName:[UIColor clearColor],
                                                                                                          NSFontAttributeName:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE]
                                                                                                         }];


            
            NSDictionary *commentAttributes = @{NSFontAttributeName:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE],
                                                NSStrokeColorAttributeName:[UIColor whiteColor],
                                                NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH]
                                                };
            
            CGSize capSize = [caption boundingRectWithSize:CGSizeMake(MAX_CAPTION_WIDTH, CGFLOAT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:commentAttributes
                                                   context:nil].size;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.caption.attributedText = string;
                CGSize cellSize = self.bounds.size;
                
                CGFloat scale = self.bounds.size.width / STANDARDIZED_DEVICE_WIDTH * .88;
                self.captionWrapper.transform = CGAffineTransformIdentity;
                
                self.captionWrapper.frame = CGRectMake(0, 0, capSize.width, capSize.height);
                self.captionWrapper.center = CGPointMake(cellSize.width/2, cellSize.height/2);
                self.caption.frame = CGRectMake(0, 0, capSize.width, capSize.height);
                self.caption.center = CGPointMake(self.captionWrapper.frame.size.width/2.f, self.captionWrapper.frame.size.height/2.f);
                
                self.captionWrapper.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(self.video.caption_rotation), CGAffineTransformMakeScale(scale, scale));
                
                self.captionWrapper.hidden = NO;

            });
        });

    } else {
        self.caption.text = @"";
        self.captionWrapper.hidden = YES;
    }
    self.username.textAlignment = NSTextAlignmentRight;
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

@end

