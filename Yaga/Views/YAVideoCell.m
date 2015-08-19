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
#define COMMENTS_ICON_BOTTOM_MARGIN 8
#define COMMENT_COUNT_BOTTOM_MARGIN 5
#define USERNAME_BOTTOM_MARGIN 0

@interface YAVideoCell ()

@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, readonly) FLAnimatedImageView *gifView;
@property (nonatomic, strong) UIImageView *likeImageView;
@property (nonatomic, assign) YAVideoCellState state;
@property (nonatomic, strong) dispatch_queue_t imageLoadingQueue;

@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UILabel *username;
@property (strong, nonatomic) UILabel *eventCountLabel;
@property (strong, nonatomic) UIImageView *commentIcon;
@property (strong, nonatomic) UILabel *caption;
@property (strong, nonatomic) UIView *captionWrapper;
@property (strong, nonatomic) UIView *groupView;
@property (strong, nonatomic) UIButton *groupButton;

@property (strong, atomic) NSString *gifFilename;

@property (strong, nonatomic) FLAnimatedImageView *uploadingView;

@property (nonatomic, assign) BOOL gifWasPaused;

@property (nonatomic, assign) BOOL lightWeightContentRendered;
@property (nonatomic, assign) BOOL heavyWeightContentRendered;
@end

@implementation YAVideoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _showsGroupLabel = NO;
        
        self.containerView = [[UIView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:self.containerView];

        _gifView = [[FLAnimatedImageView alloc] initWithFrame:self.containerView.bounds];
        _gifView.contentMode = UIViewContentModeScaleAspectFill;
        _gifView.clipsToBounds = YES;
        
        [self.containerView addSubview:self.gifView];

        self.imageLoadingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.96 alpha:1.0]];
        
        self.username = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width/2, self.bounds.size.height - 30 - USERNAME_BOTTOM_MARGIN, self.bounds.size.width/2 - 5, 30)];
        [self.username setTextAlignment:NSTextAlignmentRight];
        [self.username setMinimumScaleFactor:0.5];
        [self.username setAdjustsFontSizeToFitWidth:YES];
        [self.username setTextColor:[UIColor whiteColor]];
        [self.username setFont:[UIFont fontWithName:BIG_FONT size:20]];
        self.username.shadowColor = [UIColor blackColor];
        self.username.shadowOffset = CGSizeMake(1, 1);
        [self.containerView addSubview:self.username];

        CGFloat iconSize = 15;
        self.commentIcon = [[UIImageView alloc] initWithFrame:CGRectMake(5, self.bounds.size.height-iconSize - COMMENTS_ICON_BOTTOM_MARGIN, iconSize, iconSize)];
        [self.commentIcon setImage:[UIImage imageNamed:@"Comment_Filled"]];
        [self.containerView addSubview:self.commentIcon];
        
        self.eventCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5 + 15 + 3, self.bounds.size.height - 20 - COMMENT_COUNT_BOTTOM_MARGIN, 40, 20)];
        [self.eventCountLabel setTextColor:[UIColor whiteColor]];
        [self.eventCountLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
        self.eventCountLabel.shadowColor = [UIColor blackColor];
        self.eventCountLabel.shadowOffset = CGSizeMake(1, 1);
        [self.containerView addSubview:self.eventCountLabel];
        
        self.groupView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height/4)];
        self.groupView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
        self.groupView.hidden = YES;
        
        [self.contentView addSubview:self.groupView];
        
        self.groupButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, self.groupView.frame.size.width - 20, self.groupView.frame.size.height)];
        
        self.groupButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.groupButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.groupButton.titleLabel.textColor = [UIColor whiteColor];
        [self.groupButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:20]];
        [self.groupButton addTarget:self action:@selector(groupButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.groupView addSubview:self.groupButton];
        
        
        CGRect captionFrame = CGRectMake(0, 0, MAX_CAPTION_WIDTH, CGFLOAT_MAX);
        self.captionWrapper = [[UIView alloc] initWithFrame:captionFrame];
        self.caption = [[UILabel alloc] init];
        self.caption.numberOfLines = 0;
        
        self.caption.backgroundColor = [UIColor clearColor];
        self.caption.userInteractionEnabled = NO;
        self.caption.textAlignment = NSTextAlignmentCenter;
        [self.captionWrapper addSubview:self.caption];
        [self.containerView addSubview:self.captionWrapper];

        self.contentView.layer.masksToBounds = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoChanged:) name:VIDEO_CHANGED_NOTIFICATION object:nil];
        self.lightWeightContentRendered = NO;
        self.heavyWeightContentRendered = NO;
    }
    
    return self;
}

- (void)animateGifView:(BOOL)animate {
    if (!self.gifView.animatedImage) return;
    
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
    self.gifView.animatedImage = nil;
    self.eventCountLabel.text = @"";
    self.username.text = @"";
    self.captionWrapper.hidden = YES;
    self.lightWeightContentRendered = NO;
    self.heavyWeightContentRendered = NO;
    [self updateState];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION object:nil];
}

// This will get called right when the cell is re-used. Dont clog things up.
- (void)renderInitialContent {
//    DLog(@"Rendering INITIAL cell content");
    [self renderUsername];
    [self loadAndShowPreviewGifIfReady];
}

// This will get called when scrolling slows down. Render things that are expensive but critical. (like captions)
- (void)renderLightweightContent {
//    DLog(@"Rendering LIGHT cell content");
    if (self.lightWeightContentRendered) return;
    self.lightWeightContentRendered = YES;
    
    [self showLoaderGifIfNeeded];
    [self renderCaption];
}

// This will get called when scrolling stops. Render things that aren't critical to the UI
- (void)renderHeavyWeightContent {
//    DLog(@"Rendering HEAVY cell content");
    if (self.heavyWeightContentRendered) return;
    self.heavyWeightContentRendered = YES;
    

    //uploading progress
    if (self.video) {
        BOOL uploadInProgress = [[YAServerTransactionQueue sharedQueue] hasPendingUploadTransactionForVideo:self.video];
        [self showUploadingProgress:uploadInProgress];
    } else {
        [self showUploadingProgress:NO];
    }
}

#pragma mark -

- (void)setShowsGroupLabel:(BOOL)showsGroupLabel {
    if (_showsGroupLabel == showsGroupLabel) return;
    _showsGroupLabel = showsGroupLabel;
    if (showsGroupLabel) {
        CGFloat prop = self.groupLabelHeightProportion;
        self.groupView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.width * prop); // purposely used width not height for header proportion
        self.groupButton.frame = CGRectMake(10, 0, self.groupView.frame.size.width - 20, self.groupView.frame.size.height);
        self.groupView.hidden = NO;
        CGRect frame = self.containerView.frame;
        frame.origin.y = self.groupView.frame.size.height;
        frame.size.height = self.contentView.frame.size.height - frame.origin.y;
        self.containerView.frame = frame;
        
        CGRect userFrame = self.username.frame;
        userFrame.origin.y = frame.size.height - userFrame.size.height - USERNAME_BOTTOM_MARGIN;
        self.username.frame = userFrame;
        
        CGRect eventCountFrame = self.eventCountLabel.frame;
        eventCountFrame.origin.y = frame.size.height - eventCountFrame.size.height - COMMENT_COUNT_BOTTOM_MARGIN;
        self.eventCountLabel.frame = eventCountFrame;
        
        CGRect commentFrame = self.commentIcon.frame;
        commentFrame.origin.y = frame.size.height - commentFrame.size.height - COMMENTS_ICON_BOTTOM_MARGIN;
        self.commentIcon.frame = commentFrame;
    }
}

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
    
    if (self.video) {
        // RENDER INITIAL CONTENT HERE
        [self renderInitialContent];
    }
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
        self.gifView.shouldPlayGifAutomatically = YES;
        self.gifView.animatedImage = image;
    } else{
        self.gifView.image = image;
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

- (void)renderUsername {
    self.username.text = self.video.pending && self.video.group.publicGroup ? @"Pending" : self.video.creator;
    [self.groupButton setTitle:self.video.group.name forState:UIControlStateNormal];
}

- (void)renderCaption {
    NSString *caption = self.video.caption;
    
    if(caption.length) {
        NSString *videoId = [self.video.localId copy];
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
                if (self.video && !self.video.invalidated && [self.video.localId isEqualToString:videoId]) {
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
                    self.captionWrapper.layer.shouldRasterize = YES;
                    self.captionWrapper.layer.rasterizationScale = [UIScreen mainScreen].scale;
                }
            });
        });

    } else {
        self.caption.text = @"";
        self.captionWrapper.hidden = YES;
    }
}

- (void)loadAndShowPreviewGifIfReady {
    if (self.state == YAVideoCellStateGIFPreview) {
        [self showImageAsyncFromFilename:self.video.gifFilename animatedImage:YES];
    }
}

- (void)showLoaderGifIfNeeded {
    if ((self.state == YAVideoCellStateLoading) && !self.gifView.isAnimating) {
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
}

- (void)groupButtonPressed {
    if (self.groupOpener) {
        [self.groupOpener openGroupForVideo:self.video];
    }
}

@end

