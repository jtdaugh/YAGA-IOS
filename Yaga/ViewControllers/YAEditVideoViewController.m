//
//  YAEditVideoViewController.m
//  Yaga
//
//  Created by valentinkovalski on 7/21/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAEditVideoViewController.h"
#import "YAVideoPage.h"
#import "YAUser.h"
#import "SAVideoRangeSlider.h"

@interface YAEditVideoViewController ()
@property (nonatomic, strong) SAVideoRangeSlider *editControl;
@property (nonatomic, strong) YAVideoPage *videoPage;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) AVAssetExportSession *exportSession;
@end

@implementation YAEditVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.videoPage = [[YAVideoPage alloc] initWithFrame:self.view.bounds];
    self.videoPage.presentingVC = (id<YASuspendableGesturesDelegate>)self;
    [self.videoPage setVideo:self.video shouldPreload:YES];
    self.videoPage.playerView.playWhenReady = YES;
    [self.videoPage showBottomControls:NO];
    [self.view addSubview:self.videoPage];
    
    [self addBottomView];
    
    [self addEditingSlider];
}

- (void)addEditingSlider {
    const CGFloat sliderHeight = 35;
    self.editControl = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(5, self.bottomView.frame.origin.y - sliderHeight - 10 , self.view.bounds.size.width - 10, sliderHeight) videoUrl:[YAUtils urlFromFileName:self.video.mp4Filename]];
    
    self.editControl.delegate = self;
    [self.view addSubview:self.editControl];
}

- (void)addBottomView {
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 60, self.view.bounds.size.width, 60)];
    self.bottomView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bottomView];
    
    UIView *transparentView = [[UIView alloc] initWithFrame:self.bottomView.bounds];
    transparentView.backgroundColor = [UIColor blackColor];
    transparentView.alpha = 0.2;
    [self.bottomView addSubview:transparentView];
    
    UILabel *groupNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, self.view.bounds.size.width - 80, self.bottomView.bounds.size.height/2)];
    groupNameLabel.textColor = [UIColor whiteColor];
    groupNameLabel.font = [UIFont fontWithName:BOLD_FONT size:16];
    NSString *groupName = [YAUser currentUser].currentGroup == 0 ? @"No group" : [YAUser currentUser].currentGroup.name;
    groupNameLabel.text = groupName;
    [self.bottomView addSubview:groupNameLabel];
    
    UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.bottomView.bounds.size.height/2 - 5, self.view.bounds.size.width - 80, self.bottomView.bounds.size.height/2)];
    hintLabel.textColor = [UIColor whiteColor];
    hintLabel.font = [UIFont fontWithName:BIG_FONT size:12];
    hintLabel.text =  @"tap to add more groups";
    [self.bottomView addSubview:hintLabel];
    
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.frame = CGRectMake(self.view.bounds.size.width - self.bottomView.bounds.size.height, 0, self.bottomView.bounds.size.height, self.bottomView.bounds.size.height);
    [sendButton setImage:[[UIImage imageNamed:@"PaperPlane"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    sendButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    sendButton.tintColor = [UIColor whiteColor];
    [sendButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.bottomView addSubview:sendButton];
}

- (void)sendButtonTapped:(id)sender {
    [self dismissAnimated];
}

#pragma mark - YASwipeToDismissViewController

- (void)suspendAllGestures:(id)sender {
    // prevent non-visible pages from sending stray calls
    if ([sender isEqual:self.videoPage]) {
        self.panGesture.enabled = NO;
    }
}

- (void)restoreAllGestures:(id)sender  {
    // prevent non-visible pages from sending stray calls
    if ([sender isEqual:self.videoPage]) {
        self.panGesture.enabled = YES;
    }
}

- (void)dismissAnimated{
    [super dismissAnimated];
    
    [self deleteTrimmedFile];
}

#pragma mark - SAVideoRangeSliderDelegate
- (void)videoRange:(SAVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    //do nothing
}

- (void)videoRange:(SAVideoRangeSlider *)videoRange didGestureStateEndedLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    [self trimVideoWithStartTime:leftPosition andStopTime:rightPosition];
}


#pragma mark - Trimming
-(void)deleteTrimmedFile {
    NSURL *url = [self trimmedFileUrl];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    
    NSError *error;
    if (exist) {
        [fm removeItemAtURL:url error:&error];
        if (error)
            DLog(@"file remove error, %@", error.localizedDescription );
    }
}

- (NSURL*)trimmedFileUrl {
    NSString *pathExtenstion = [self.video.mp4Filename pathExtension];
    NSString *trimmedFilename = [[[self.video.mp4Filename stringByDeletingPathExtension] stringByAppendingString:@"_trimmed"] stringByAppendingPathExtension:pathExtenstion];
    
    NSURL *result = [YAUtils urlFromFileName:trimmedFilename];
    
    return result;
}

- (void)trimVideoWithStartTime:(CGFloat)startTime andStopTime:(CGFloat)stopTime {
    self.videoPage.playerView.URL = nil;
    
    NSURL *videoFileUrl = [YAUtils urlFromFileName:self.video.mp4Filename];
    
    AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:videoFileUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:anAsset presetName:AVAssetExportPresetPassthrough];
        
        NSURL *outputUrl = [self trimmedFileUrl];
        [self deleteTrimmedFile];
        
        self.exportSession.outputURL = outputUrl;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMakeWithSeconds(startTime, anAsset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(stopTime-startTime, anAsset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;
        
        MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:@"Please wait"];
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hide:YES];
                switch ([self.exportSession status]) {
                    case AVAssetExportSessionStatusFailed:
                        DLog(@"Edit video - export failed: %@", [[self.exportSession error] localizedDescription]);
                        break;
                    case AVAssetExportSessionStatusCancelled:
                        DLog(@"Edit video - export canceled");
                        break;
                    default:
                        self.videoPage.playerView.URL = outputUrl;
                        self.videoPage.playerView.playWhenReady = YES;
                    break;
                }
                
            });
            
            
        }];
        
    }
}


@end