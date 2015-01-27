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
#import "NSDate+NVTimeAgo.h"
#import "YAAssetsCreator.h"
#import "YAActivityView.h"
#import "YAImageCache.h"
#import "AFURLConnectionOperation.h"
#import "THCircularProgressView.h"

typedef NS_ENUM(NSUInteger, YAVideoCellState) {
    YAVideoCellStateLoading = 0,
    YAVideoCellStateJPEGPreview,
    YAVideoCellStateGIFPreview,
    YAVideoCellStateVideoPreview,
};

@interface YAVideoCell ()


@property (nonatomic, strong) THCircularProgressView *progressView;

@property (nonatomic, readonly) FLAnimatedImageView *gifView;

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
        
        //progress view
        self.progressView = [[THCircularProgressView alloc] initWithCenter:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2) radius:self.bounds.size.width/6 lineWidth:2.0f progressMode:THProgressModeFill progressColor:[UIColor lightGrayColor] progressBackgroundMode:THProgressBackgroundModeNone progressBackgroundColor:[UIColor lightGrayColor] percentage:0.0f];
        self.progressView.alpha = 0;
        [self addSubview:self.progressView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:AFNetworkingOperationDidStartNotification object:nil];

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

    self.progressView.percentage = 0;
    self.progressView.alpha = 0;

    self.video = nil;
    self.gifView.image = nil;
    self.gifView.animatedImage = nil;
    //self.playerVC = nil;
    self.state = YAVideoCellStateLoading;
}

#pragma mark -

- (void)setVideo:(YAVideo *)video {
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
    self.progressView.alpha = show && [[YAAssetsCreator sharedCreator] urlDownloadInProgress:self.video.url] ? 1 : 0;
}

- (void)generationProgressChanged:(NSNotification*)notif {
    NSString *url = notif.object;
    if([url isEqualToString:self.video.url]) {
        
        if(self.progressView) {
            NSNumber *value = notif.userInfo[@"progress"];
            
            self.progressView.percentage = value.floatValue;
            self.progressView.alpha = 1;
        }
    }

}

- (void)downloadProgressChanged:(NSNotification*)notif {
    NSString *url = notif.object;
    if([url isEqualToString:self.video.url]) {
        
        if(self.progressView) {
            NSNumber *value = notif.userInfo[@"progress"];
            
            self.progressView.percentage = value.floatValue;
            self.progressView.alpha = 1;
        }
    }
}
@end

