//
//  YACameraManager.m
//  Yaga
//
//  Created by Jesse on 6/21/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACameraManager.h"
#import "YAAssetsCreator.h"
#import "YAUser.h"

#define MAX_ZOOM_SCALE 4.f

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
@property (nonatomic, strong) NSDate *currentRecordingBeginDate;

@property (nonatomic, strong) NSMutableArray *recordingSequenceUrls; // Array of NSURLs
@property (nonatomic, strong) NSMutableArray *recordingSequenceDurations; // Array of CMTimes or NSTimeIntervals (dunno yet)

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
    }
    return self;
}

- (void)initCamera {
    if (self.isInitialized) {
        return;
    }
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.zoomFactor = 1.0;
    [self setupCameraSettings];
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

- (void)setupCameraSettings {
    if ([self.videoCamera inputCamera]) {
        NSError *error = nil;
        if ([[self.videoCamera inputCamera] lockForConfiguration:&error]) {
            if([[self.videoCamera inputCamera] isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
                [[self.videoCamera inputCamera] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            
            if([[self.videoCamera inputCamera] isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
                [[self.videoCamera inputCamera] setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            [[self.videoCamera inputCamera] unlockForConfiguration];
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

- (void)pauseCameraAndStop:(BOOL)stop {
    if (self.isInitialized){
        DLog(@"pausing camera capture");
        [self stopContiniousRecordingAndPrepareOutput:NO completion:^(NSURL *outputUrl, NSTimeInterval duration, UIImage *firstFrameImage) {
            // discard
        }];
        
        [self.videoCamera pauseCameraCapture];
        [self toggleFlash:NO];
        self.isPaused = YES;
        if (stop) {
            [self.videoCamera stopCameraCapture];
            runSynchronouslyOnVideoProcessingQueue(^{
                glFinish();
            });
        }
    }
}

- (void)resumeCameraAndNeedsRestart:(BOOL)restart {
    if (self.isInitialized && self.isPaused) {
        DLog(@"resuming camera capture");
        self.isPaused = NO;
        [self.videoCamera resumeCameraCapture];
        if (restart) {
            [self.videoCamera startCameraCapture];
        }
        
        self.recordingSequenceDurations = [NSMutableArray array];
        self.recordingSequenceUrls = [NSMutableArray array];
        
        [self startContiniousRecording];
    }
}

- (void)startContiniousRecording {
    [self startRecording];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recordingBackupTimer invalidate];
        self.recordingBackupTimer = [NSTimer scheduledTimerWithTimeInterval:RECORDING_BACKUP_INTERVAL target:self selector:@selector(createBackupAndProceedRecording) userInfo:nil repeats:NO];
    });
}

- (void)createBackupAndProceedRecording {
    __weak typeof(self) weakSelf = self;
    [self stopRecordingWithCompletion:^(NSURL *recordedURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf startContiniousRecording];
        });
    }];

}

- (void)startRecording {
    if (!self.isInitialized) return;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        
        NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"file.mp4"];
        self.currentlyRecordingUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
        
//        NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];;
//        [videoSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
//        [videoSettings setObject:[NSNumber numberWithInteger:480] forKey:AVVideoWidthKey];
//        [videoSettings setObject:[NSNumber numberWithInteger:640] forKey:AVVideoHeightKey];
        
//        AudioChannelLayout channelLayout;
//        memset(&channelLayout, 0, sizeof(AudioChannelLayout));
//        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
        
        //        NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
        //                                       [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
        //                                       [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
        //                                       [ NSNumber numberWithFloat: 16000.0 ], AVSampleRateKey,
        //                                       [ NSData dataWithBytes:&channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
        //                                       [ NSNumber numberWithInt: 32000 ], AVEncoderBitRateKey,
        //                                       nil];
        //
        
        
        self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.currentlyRecordingUrl size:[UIScreen mainScreen].bounds.size fileType:AVFileTypeMPEG4 outputSettings:nil];
        self.movieWriter.encodingLiveVideo = YES;
        self.movieWriter.shouldPassthroughAudio = NO; // default YES
        self.movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
        self.videoCamera.audioEncodingTarget = self.movieWriter;
        
        [self.videoCamera addTarget:self.movieWriter];
        
        self.currentRecordingBeginDate = [NSDate date];
        [self.movieWriter startRecording];
    });
    
    
    //    [self performSelector:@selector(gpuSwitchCamera) withObject:self afterDelay:3.0];
    
    
    DLog(@"start recording video?!?!?!");
}

- (void)stopRecordingWithCompletion:(YARecordingCompletionBlock)completion {
    if (!self.isInitialized) return;
    [self.recordingSequenceUrls addObject:self.currentlyRecordingUrl];
    [self.recordingSequenceDurations addObject:@([[NSDate date] timeIntervalSinceDate:self.currentRecordingBeginDate])];
    
    DLog(@"Finish recording?");
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        DLog(@"Finish recording 2?");
        DLog(@"recording path: %@ ?", self.currentlyRecordingUrl.path);
        
        [self.videoCamera removeTarget:self.movieWriter];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.videoCamera startCameraCapture];
        });
        completion(self.currentlyRecordingUrl);
    }];
}

- (void)deleteRecordingData {
    NSError *error = nil;
    for (NSURL *url in self.recordingSequenceUrls) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    }
    [self.recordingSequenceUrls removeAllObjects];
    [self.recordingSequenceDurations removeAllObjects];
}

- (void)stopContiniousRecordingAndPrepareOutput:(BOOL)prepareOutput completion:(YAPostCaptureCompletionBlock)completion {
    __weak typeof(self) weakSelf = self;
    
    [self.recordingBackupTimer invalidate];
    
    [self stopRecordingWithCompletion:^(NSURL *recordingUrl) {
        if (!prepareOutput) {
            [weakSelf deleteRecordingData];
            completion(nil, 0, nil);
            return;
        }
        
        NSTimeInterval estimatedDuration = 0;
        NSMutableArray *urlsToConcat = [NSMutableArray array];
        UIImage *previewFrameImage = nil;
        for (int i = (int)[weakSelf.recordingSequenceUrls count] - 1; i >= 0; i--) {
            // Go thru recordings from recent to old, appending until time is >= MAX_INTERVAL
            estimatedDuration += [(NSNumber *)self.recordingSequenceDurations[i] doubleValue];
            [urlsToConcat insertObject:weakSelf.recordingSequenceUrls[i] atIndex:0];
            if (estimatedDuration >= MAXIMUM_TRIM_TOTAL_LENGTH) break;
        }
        
        NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"file.mp4"];
        NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
        
        [[YAAssetsCreator sharedCreator] concatenateAssetsAtURLs:urlsToConcat
                                                   withOutputURL:fileURL
                                                   exportQuality:AVAssetExportPresetPassthrough
                                               limitedToDuration:MAXIMUM_TRIM_TOTAL_LENGTH
                                                      completion:^(NSURL *filePath, NSTimeInterval totalDuration, NSError *error) {
            [weakSelf deleteRecordingData];
            completion(filePath, totalDuration, previewFrameImage);
        }];
        
        [[YACameraManager sharedManager] setZoomFactor:1];
    }];
}

- (void)switchCamera {
    self.zoomFactor = 1;
    [self.videoCamera rotateCamera];
    // Do the change during/immediately after blip. If we swithed immediately audio may be out of sync
    
#warning crashes if u tap 2x within 0.1s i think.
    [self performSelector:@selector(createBackupAndProceedRecording) withObject:nil afterDelay:0.07];
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

@end
