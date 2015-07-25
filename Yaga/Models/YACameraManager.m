//
//  YACameraManager.m
//  Yaga
//
//  Created by Jesse on 6/21/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACameraManager.h"
#import "YAUser.h"

#define MAX_ZOOM_SCALE 4.f

#define BACKUP_RECORDING_SECONDS 20

@implementation YACameraView
@end

@interface YACameraManager () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) YACameraView *currentCameraView;
@property (strong, nonatomic) NSURL *currentlyRecordingUrl;
@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;
@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchZoomGesture;
@property (nonatomic, assign) CGFloat zoomFactor;
@property (nonatomic, assign) CGFloat beginGestureScale;


@property (nonatomic, strong) dispatch_semaphore_t recordingSemaphore;
@property (nonatomic) BOOL isInitialized;
@property (nonatomic) BOOL isPaused;

@property (nonatomic, strong) NSTimer *recordingBackupTimer;

@property (nonatomic, readonly) NSString *backupPath;
@end

@implementation YACameraManager

+ (instancetype)sharedManager {
    static YACameraManager *sharedInstance = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isInitialized = NO;
        _isPaused = YES;
        _backupPath = [[NSString alloc] initWithFormat:@"%@backup_recording.mp4", NSTemporaryDirectory()];
        
        //remove old backup
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:_backupPath])
        {
            NSError *error;
            if (![fileManager removeItemAtPath:_backupPath error:&error])
                DLog(@"Error removing backup recording: %@", error);
        }

    }
    return self;
}

- (void)initCamera {
    if (self.isInitialized) {
        return;
    }
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.zoomFactor = 1.0;
    self.isInitialized = YES;
    
    // only init camera if not simulator
    if(TARGET_IPHONE_SIMULATOR){
        DLog(@"no camera, simulator");
    } else {
        
        DLog(@"init camera");
        
        if (self.currentCameraView) {
            if (![[self.videoCamera targets] containsObject:self.currentCameraView]) {
                [self.videoCamera addTarget:self.currentCameraView];
            }
        }
    }
}

- (void)adjustZoomLevel {
    if ([self.videoCamera inputCamera]) {
        NSError *error = nil;
        if ([[self.videoCamera inputCamera] lockForConfiguration:&error]) {
            [[self.videoCamera inputCamera] setVideoZoomFactor:self.zoomFactor];
            [[self.videoCamera inputCamera] unlockForConfiguration];
        }
    }
}

- (void)setZoomFactor:(CGFloat)zoomFactor{
    if (zoomFactor == _zoomFactor) return;
    _zoomFactor = MAX(MIN(MAX_ZOOM_SCALE, zoomFactor), 1);
    [self adjustZoomLevel];
}

- (void)setCameraView:(YACameraView *)cameraView {
    if (![cameraView isEqual:self.currentCameraView] ) {
        if (self.currentCameraView) {
            [self.videoCamera removeTarget:self.currentCameraView];
            [self.currentCameraView removeGestureRecognizer:self.pinchZoomGesture];
            self.pinchZoomGesture = nil;
        }
        if (cameraView) {
            [cameraView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
            [cameraView setContentMode:UIViewContentModeScaleAspectFill];
            [self.videoCamera addTarget:cameraView];
            
            self.pinchZoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchZoom:)];
            self.pinchZoomGesture.delegate = self;
            [cameraView addGestureRecognizer:self.pinchZoomGesture];
        }

    }
    self.currentCameraView = cameraView;
}

- (void)pauseCamera {
    if (self.isInitialized){
        DLog(@"pausing camera capture");
        [self stopContiniousRecordingWithCompletion:^(NSURL *outputUrl) {
            // discard
        }];
        
        [self.videoCamera pauseCameraCapture];
        self.isPaused = YES;
        [self.delegate setFrontFacingFlash:NO];
        
        
        
        [self.videoCamera stopCameraCapture];
        runSynchronouslyOnVideoProcessingQueue(^{
            glFinish();
        });
    }
}

- (void)resumeCamera {
    if (self.isInitialized && self.isPaused) {
        DLog(@"resuming camera capture");
        self.isPaused = NO;
        [self.videoCamera resumeCameraCapture];
        [self.videoCamera startCameraCapture];
        
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@recording.mp4", NSTemporaryDirectory()];
        self.currentlyRecordingUrl = [[NSURL alloc] initFileURLWithPath:outputPath];
        unlink([[self.currentlyRecordingUrl path] UTF8String]); // If a file already exists
        
        if ([self.backupPath length])
            unlink([self.backupPath UTF8String]); // If a file already exists
        
        [self startContiniousRecording];
    }
}

- (void)startContiniousRecording {
    [self startRecording];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recordingBackupTimer = [NSTimer scheduledTimerWithTimeInterval:BACKUP_RECORDING_SECONDS target:self selector:@selector(createBackupAndProceedRecording) userInfo:nil repeats:NO];
    });
}

- (void)createBackupAndProceedRecording {
    __weak typeof(self) weakSelf = self;
    [self stopRecordingWithCompletion:^(NSURL *recordedURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            unlink([self.backupPath UTF8String]); // If a file already exists
            
            NSError *error;
            NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:recordedURL.path error:&error];
            DLog(@"recording size: %@", fileAttrs[@"NSFileSize"]);
            
            [[NSFileManager defaultManager] copyItemAtPath:recordedURL.path toPath:self.backupPath error:&error];
            if(error) {
                DLog(@"can't create recording backup");
                return;
            }
            
            DLog(@"%d seconds backup created, proceeding recording", BACKUP_RECORDING_SECONDS);
            
            [weakSelf startContiniousRecording];
        });
    }];

}

- (void)startRecording {
    if (!self.isInitialized) return;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //Create temporary URL to record to
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@recording.mp4", NSTemporaryDirectory()];
        self.currentlyRecordingUrl = [[NSURL alloc] initFileURLWithPath:outputPath];
        unlink([[self.currentlyRecordingUrl path] UTF8String]); // If a file already exists
        
        NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];;
        [videoSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [videoSettings setObject:[NSNumber numberWithInteger:480] forKey:AVVideoWidthKey];
        [videoSettings setObject:[NSNumber numberWithInteger:640] forKey:AVVideoHeightKey];
        
        AudioChannelLayout channelLayout;
        memset(&channelLayout, 0, sizeof(AudioChannelLayout));
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
        
        //        NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
        //                                       [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
        //                                       [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
        //                                       [ NSNumber numberWithFloat: 16000.0 ], AVSampleRateKey,
        //                                       [ NSData dataWithBytes:&channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
        //                                       [ NSNumber numberWithInt: 32000 ], AVEncoderBitRateKey,
        //                                       nil];
        //
        
        
        self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.currentlyRecordingUrl size:CGSizeMake(480.0, 640.0) fileType:AVFileTypeMPEG4 outputSettings:videoSettings];
        self.movieWriter.encodingLiveVideo = YES;
        self.movieWriter.shouldPassthroughAudio = NO; // default YES
        self.movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
        //        [self.movieWriter setHasAudioTrack:TRUE audioSettings:audioSettings];
        self.videoCamera.audioEncodingTarget = self.movieWriter;
        
        [self.videoCamera addTarget:self.movieWriter];
        [self.movieWriter startRecording];
        
        self.capturePreviewImage = nil;
        GPUImageFilter *imgFilter = [GPUImageFilter new];
        [self.videoCamera addTarget:imgFilter];
        
        [imgFilter useNextFrameForImageCapture];
        self.capturePreviewImage = [imgFilter imageFromCurrentFramebufferWithOrientation:UIImageOrientationUp];
    });
    
    
    //    [self performSelector:@selector(gpuSwitchCamera) withObject:self afterDelay:3.0];
    
    
    DLog(@"start recording video?!?!?!");
}

- (void)stopRecordingWithCompletion:(YARecordingCompletionBlock)completion {
    if (!self.isInitialized) return;
    
    DLog(@"Finish recording?");
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        DLog(@"Finish recording 2?");
        DLog(@"recording path: %@ ?", self.currentlyRecordingUrl.path);
        
        [self.videoCamera removeTarget:self.movieWriter];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.videoCamera startCameraCapture];
        });
        completion(self.currentlyRecordingUrl);
        [[YACameraManager sharedManager] setZoomFactor:1];
    }];
}

- (void)stopContiniousRecordingWithCompletion:(YARecordingCompletionBlock)completion {
    __weak typeof(self) weakSelf = self;
    
    [self.recordingBackupTimer invalidate];
    
    [self stopRecordingWithCompletion:^(NSURL *recordingUrl) {
        
        if([[NSFileManager defaultManager] fileExistsAtPath:self.backupPath]) {
            DLog(@"Stopped recording with secondURL");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                NSURL *backupURL = [NSURL fileURLWithPath:self.backupPath];
                
                [weakSelf mergeAssetsAtUrls:@[backupURL, recordingUrl] withCompletion:^(NSURL *mergedUrl) {
                    completion(mergedUrl);
                    
                }];
            });
        }
        else {
            DLog(@"Stopped recording and NO secondURL");
            completion(recordingUrl);
        }
        
    }];
}

- (void)switchCamera {
    self.zoomFactor = 1;
    [self.videoCamera rotateCamera];
}

- (void)forceFrontFacingCamera {
    AVCaptureDevicePosition position = [self.videoCamera cameraPosition];
    if (position == AVCaptureDevicePositionBack) {
        [self switchCamera];
    }
}

- (void)toggleFlash:(BOOL)flashOn {
    
    DLog(@"switching flash mode");
    AVCaptureDevice *currentVideoDevice = self.videoCamera.inputCamera;
    
    if([currentVideoDevice position] == AVCaptureDevicePositionBack){
        // back camera
        [currentVideoDevice lockForConfiguration:nil];
        
        if(!flashOn){
            //turn flash off
            if([currentVideoDevice isTorchModeSupported:AVCaptureTorchModeOff]){
                [currentVideoDevice setTorchMode:AVCaptureTorchModeOff];
            }
        } else {
            //turn flash on
            NSError *error = nil;
            if([currentVideoDevice isTorchModeSupported:AVCaptureTorchModeOn]){
                [currentVideoDevice setTorchModeOnWithLevel:0.8 error:&error];
            }
            if(error){
                DLog(@"error: %@", error);
            }
        }
        [currentVideoDevice unlockForConfiguration];
        
    } else if([currentVideoDevice position] == AVCaptureDevicePositionFront) {
        [self.delegate setFrontFacingFlash:flashOn];
    }
}

- (void)handlePinchZoom:(UIPinchGestureRecognizer *)pinchZoomGesture {
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [pinchZoomGesture numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [pinchZoomGesture locationOfTouch:i inView:self.currentCameraView];
        CGPoint convertedLocation = [self.currentCameraView.layer convertPoint:location fromLayer:self.currentCameraView.layer.superlayer];
        if ( ! [self.currentCameraView.layer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        NSLog(@"Pinch scale %f", pinchZoomGesture.scale);
        [self setZoomFactor:self.beginGestureScale * pinchZoomGesture.scale];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isEqual:self.pinchZoomGesture]) {
        self.beginGestureScale = self.zoomFactor;
    }
    return YES;
}

- (void)mergeAssetsAtUrls:(NSArray*)urls withCompletion:(YARecordingCompletionBlock)completion {
    //can only merge from two NSURLs
    if(urls.count != 2){
        completion(nil);
        return;
    }
    
    //creating composition
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *mutableCompVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *mutableCompAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //creating video/audio tracks
    AVAsset *videoAsset1 = [AVAsset assetWithURL:urls[0]];
    AVAsset *videoAsset2 = [AVAsset assetWithURL:urls[1]];
    
    //exporting merged video file
    NSString *mergedPath = [[NSString alloc] initWithFormat:@"%@recording_merged.mp4", NSTemporaryDirectory()];
    unlink([mergedPath UTF8String]); // If a file already exists
    NSURL *mergedURL = [NSURL fileURLWithPath:mergedPath];
    
    //get videoAsset2 duration
    NSArray *requestedKeys = @[@"playable"];
    [videoAsset2 loadValuesAsynchronouslyForKeys:requestedKeys completionHandler: ^{
        Float64 asset1DurationSeconds = CMTimeGetSeconds(videoAsset1.duration);
        Float64 asset2DurationSeconds = CMTimeGetSeconds(videoAsset2.duration);
        
        //do not proceed if second asset is zero length(has just started recording)
        if(asset2DurationSeconds == 0) {
            NSDictionary *d = [[NSFileManager defaultManager] attributesOfItemAtPath:[(NSURL*)[urls objectAtIndex:1] path] error:nil];
            DLog(@"%@", d);
            //copy is required as first asset can be used again, but YAAssetsCreator will delete the recording_backup.mp4 file
            NSError *error;

            [[NSFileManager defaultManager] copyItemAtURL:urls[0] toURL:mergedURL error:&error];
            if(error) {
                DLog(@"Critical error: can't copy file, can not proceed.");
                return;
            }
            else {
                completion(mergedURL);
                return;
            }
        }
        
        Float64 asset1StartSeconds = asset2DurationSeconds;
        Float64 asset1TotalSecondsToAdd = asset1DurationSeconds - asset1StartSeconds;
        
        CMTime asset1From = CMTimeMakeWithSeconds(asset1StartSeconds, videoAsset1.duration.timescale);
        CMTime asset1DurationToAdd = CMTimeMakeWithSeconds(asset1TotalSecondsToAdd, videoAsset1.duration.timescale);
        
        [mutableCompVideoTrack insertTimeRange:CMTimeRangeMake(asset1From, asset1DurationToAdd) ofTrack:[[videoAsset1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        [mutableCompAudioTrack insertTimeRange:CMTimeRangeMake(asset1From, asset1DurationToAdd) ofTrack:[[videoAsset1 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        
        CMTime insertSecondAssetAt = CMTimeMakeWithSeconds(asset1TotalSecondsToAdd, videoAsset1.duration.timescale);
        
        [mutableCompVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset2.duration) ofTrack:[[videoAsset2 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:insertSecondAssetAt error:nil];
        [mutableCompAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset2.duration) ofTrack:[[videoAsset2 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:insertSecondAssetAt error:nil];
        

        
        NSURL *mergedUrl = [NSURL fileURLWithPath:mergedPath];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset640x480];
        exportSession.outputFileType=AVFileTypeQuickTimeMovie;
        exportSession.outputURL = mergedUrl;
        
        CMTimeValue val = mixComposition.duration.value;
        CMTime start = CMTimeMake(0, 1);
        CMTime duration = CMTimeMake(val, 1);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        exportSession.timeRange = range;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                {
                    DLog(@"Export during merge failed: %@ %@", [[exportSession error] localizedDescription],[[exportSession error]debugDescription]);
                    break;
                }
                case AVAssetExportSessionStatusCancelled:
                {
                    DLog(@"Export during merge canceled");
                    break;
                }
                case AVAssetExportSessionStatusCompleted:
                {
                    completion(mergedUrl);
                    break;
                }
                default:
                {
                    DLog(@"Export during merge unexpected error");
                    break;
                }
            }
        }];
    }];
}

@end
