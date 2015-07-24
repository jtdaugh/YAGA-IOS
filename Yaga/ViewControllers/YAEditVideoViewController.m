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
#import "YAServerTransactionQueue.h"

@interface YAEditVideoViewController ()
@property (nonatomic, strong) SAVideoRangeSlider *trimmingView;
@property (nonatomic, strong) YAVideoPage *videoPage;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) AVAssetExportSession *exportSession;

@property CGFloat startTime;
@property CGFloat endTime;

@property BOOL dragging;
@end

typedef void(^trimmingCompletionBlock)(NSError *error);

@implementation YAEditVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.startTime = 0.0f;
    self.endTime = CGFLOAT_MAX;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.videoPage = [[YAVideoPage alloc] initWithFrame:self.view.bounds];
    self.videoPage.presentingVC = (id<YASuspendableGesturesDelegate>)self;
    [self.videoPage setVideo:self.video shouldPreload:YES];
    self.videoPage.playerView.playWhenReady = YES;
    self.videoPage.showBottomControls = NO;
    self.videoPage.playerView.delegate = self;
    [self.view addSubview:self.videoPage];
    
    [self addBottomView];
    
    [self addTrimmingView];
    
}

- (void)addTrimmingView {
    const CGFloat sliderHeight = 35;
    self.trimmingView = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(5, self.bottomView.frame.origin.y - sliderHeight - 10 , self.view.bounds.size.width - 10, sliderHeight) videoUrl:[YAUtils urlFromFileName:self.video.mp4Filename]];
    self.trimmingView.delegate = self;
    [self.view addSubview:self.trimmingView];
}

- (void)addBottomView {
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 60, self.view.bounds.size.width, 60)];
    self.bottomView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bottomView];
    
    UIView *transparentView = [[UIView alloc] initWithFrame:self.bottomView.bounds];
    transparentView.backgroundColor = [UIColor blackColor];
    transparentView.alpha = 0.42;
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
    hintLabel.text =  @"Tap to add more groups";
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
    
    [self trimVideoWithStartTime:self.startTime andStopTime:self.endTime completion:^(NSError *error) {
        if(!error) {
            NSError *replaceError;
            NSURL *resultingUrl;
            [[NSFileManager defaultManager] replaceItemAtURL:[YAUtils urlFromFileName:self.video.mp4Filename] withItemAtURL:[self trimmedFileUrl] backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&resultingUrl error:&replaceError];
            if(replaceError) {
                [YAUtils showNotification:@"Can not save video" type:YANotificationTypeError];
                return;
            }
            [self deleteTrimmedFile];
            
            if([YAUser currentUser].currentGroup) {
                [[RLMRealm defaultRealm] beginWriteTransaction];
                
                [[YAUser currentUser].currentGroup.videos insertObject:self.video atIndex:0];
                self.video.group = [YAUser currentUser].currentGroup;
                [[RLMRealm defaultRealm] commitWriteTransaction];
                
                
                //start uploading while generating gif
                [[YAServerTransactionQueue sharedQueue] addUploadVideoTransaction:self.video toGroup:[YAUser currentUser].currentGroup];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_DID_REFRESH_NOTIFICATION object:[YAUser currentUser].currentGroup userInfo:@{kNewVideos:@[self.video]}];
                
                [self dismissAnimated];
            }
            else {
                self.bottomView.hidden = YES;
                self.trimmingView.hidden = YES;
                [self.videoPage showSharingOptions];
            }
        }
        else {
            [YAUtils showNotification:@"Error: can't trim video" type:YANotificationTypeError];
        }
    }];
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
- (void)rangeSliderDidMoveLeftSlider:(SAVideoRangeSlider *)rangeSlider {
    
    NSLog(@"left position: %f", rangeSlider.leftPosition);

    self.dragging = YES;
    
    if(self.videoPage.playerView.player.rate == 1.0){
        [self.videoPage.playerView.player pause];
    }
    
    [self.videoPage.playerView.player seekToTime:CMTimeMakeWithSeconds(rangeSlider.leftPosition, self.videoPage.playerView.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
    }];
    
//    [self.trimmingView setPlayerProgress:0.0f];
}

- (void)rangeSliderDidMoveRightSlider:(SAVideoRangeSlider *)rangeSlider {
    
    self.dragging = YES;
    
    if(self.videoPage.playerView.player.rate == 1.0){
        [self.videoPage.playerView.player pause];
    }
    
    [self.videoPage.playerView.player seekToTime:CMTimeMakeWithSeconds(rangeSlider.rightPosition, self.videoPage.playerView.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
    }];
    
//    [self.trimmingView setPlayerProgress:0.0f];
}

- (void)rangeSliderDidEndMoving:(SAVideoRangeSlider *)rangeSlider {
    self.startTime = rangeSlider.leftPosition;
    self.endTime = rangeSlider.rightPosition;
    
    [self.videoPage.playerView.player seekToTime:CMTimeMakeWithSeconds(self.startTime, self.videoPage.playerView.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
        NSLog(@"hello?");
        
        self.dragging = NO;
        self.videoPage.playerView.playWhenReady = YES;
    }];
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

- (void)trimVideoWithStartTime:(CGFloat)startTime andStopTime:(CGFloat)stopTime completion:(trimmingCompletionBlock)completion {
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
        
        __weak typeof(self) weakSelf = self;
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                switch ([weakSelf.exportSession status]) {
                    case AVAssetExportSessionStatusFailed:
                        DLog(@"Edit video - export failed: %@", [[weakSelf.exportSession error] localizedDescription]);
                        if(completion)
                            completion([weakSelf.exportSession error]);
                        break;
                    case AVAssetExportSessionStatusCancelled:
                        DLog(@"Edit video - export canceled");
                        if(completion)
                            completion([weakSelf.exportSession error]);
                        break;
                    default:
                        if(completion)
                            completion(nil);
                        break;
                }
                
            });
        }];
        
    }
}

#pragma mark - YAVideoPlayerDelegate
- (void)playbackProgressChanged:(CGFloat)progress duration:(CGFloat)duration {
    if(!self.dragging){
        
        // if is end time, loop back to the start time
        if(progress < .02){
            NSLog(@"progress: %f", progress);
            NSLog(@"duration: %f", duration);
            NSLog(@"progress/duration: %f", progress/duration);
            
        }
        
        if(progress > self.endTime){
            
            [self.videoPage.playerView.player seekToTime:CMTimeMakeWithSeconds(self.startTime, self.videoPage.playerView.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            }];
        } else {
            if((progress - self.startTime) > 0){
                CGFloat end = (self.endTime == CGFLOAT_MAX) ? duration : self.endTime;
                CGFloat normalizedProgress = (progress - self.startTime)/(end - self.startTime);
                [self.trimmingView setPlayerProgress:normalizedProgress];
                
            } else {
                [self.trimmingView setPlayerProgress:0.0];
            }
            
        }

    }
}

@end
