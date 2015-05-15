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
#import "YAServerTransactionQueue.h"

#define LIKE_HEART_SIDE 40.f


@interface YAVideoCell ()

@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) UIImageView *likeImageView;
@property (nonatomic, assign) YAVideoCellState state;
@property (nonatomic, strong) dispatch_queue_t imageLoadingQueue;

@property (strong, nonatomic) UIImageView *loader;

@property (strong, nonatomic) UILabel *username;
@property (strong, nonatomic) UILabel *caption;

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
        
        self.loader = [[UIImageView alloc] initWithFrame:self.bounds];
        NSMutableArray *loaderImages = [NSMutableArray new];
        for(NSUInteger loaderImageIndex = 1; loaderImageIndex < 11; loaderImageIndex++) {
            UIImage *loaderImage = [UIImage imageNamed:[NSString stringWithFormat:@"loader%lu.png", (unsigned long)loaderImageIndex]];
            [loaderImages addObject:loaderImage];
        }
        
        self.loader.animationImages = loaderImages;
        self.loader.animationDuration = 1.0;
        [self.loader startAnimating];
        self.backgroundView = self.loader;

        #warning TODO: username isn't shown for now
//        self.username = [[UILabel alloc] initWithFrame:self.bounds];
//        [self.username setTextAlignment:NSTextAlignmentCenter];
//        [self.username setTextColor:PRIMARY_COLOR];
//        [self.username setFont:[UIFont fontWithName:@"AvenirNext-Heavy" size:30]];
//        [self.loader addSubview:self.username];
        
        CGRect captionFrame = CGRectMake(12, 12, self.bounds.size.width - 24, self.bounds.size.height - 24);
        self.caption = [[UILabel alloc] initWithFrame:captionFrame];
        [self.caption setNumberOfLines:3];
        [self.caption setTextAlignment:NSTextAlignmentCenter];
        [self.caption setTextColor:PRIMARY_COLOR];
        [self.contentView addSubview:self.caption];
        
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

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.video = nil;
    self.gifView.image = nil;
    self.gifView.animatedImage = nil;
    self.state = YAVideoCellStateLoading;
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
            //[self showImageAsyncFromFilename:self.video.jpgFilename animatedImage:NO];
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
                if([self.gifFilename isEqualToString:fileName]) {
                    [[YAImageCache sharedCache] setObject:image forKey:fileName];

                    [self showCachedImage:image animatedImage:animatedImage];
                }
                else {
                    //invalidated.. no need to redraw and cache.
                }
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
    if(![self.video isInvalidated] && [op.name isEqualToString:self.video.gifUrl]) {
        [self showLoader:YES];
    }
}

- (void)showProgress:(BOOL)show {
    //do nothing, tile loader is used
}

- (void)showLoader:(BOOL)show {
    self.loader.hidden = !show;

    if(!self.loader.hidden && !self.loader.isAnimating)
        [self.loader startAnimating];
    
    // self.username.hidden = !show;
    self.caption.hidden = show;
    
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
    
    if(caption.length && !self.caption.hidden) {
        self.caption.attributedText = [self attributedStringFromString:caption font:[UIFont fontWithName:CAPTION_FONTS[self.video.font] size:30]];
    } else {
        self.caption.text = @"";
    }
    
//    if(!self.username.hidden)
//        self.username.attributedText = [self attributedStringFromString:self.video.creator font:nil];
//
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
    
    [result addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-5.0] range:NSMakeRange(0, result.length)];
    [result addAttribute:NSStrokeColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, result.length)];
    
    if(font)
        [result addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, result.length)];
    
    return result;
}

@end

