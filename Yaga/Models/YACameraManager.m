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

@implementation YACameraView
@end

@interface YACameraManager () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) YACameraView *currentCameraView;
@property (strong, nonatomic) NSURL *currentlyRecordingUrl;
@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;
@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchZoomGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panZoomGesture;
@property (nonatomic, assign) CGFloat zoomFactor;
@property (nonatomic, assign) CGFloat beginGestureScale;


@property (nonatomic, strong) dispatch_semaphore_t recordingSemaphore;
@property (nonatomic) BOOL isInitialized;

@property (strong, nonatomic) GPUImageFilter *previewImageFilter;


@property (strong, nonatomic) GPUImageFilter *filter;
@property NSUInteger filterIndex;
@property (strong, nonatomic) UILabel *filterLabel;
@property (strong, nonatomic) NSArray *filters;
@property (strong, nonatomic) GPUImageFilter *currentFilter;
@property (nonatomic) NSTimer *doozyTimer;
@property (nonatomic) CGFloat doozyProgress;

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
        self.isInitialized = NO;
        self.filters = @[@"#nofilter", @"Bulge", @"Doozy", @"Trippy", @"#YAGA", ];
        self.filterIndex = 0;
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

        DLog(@"starting camera capture");
        [self.videoCamera startCameraCapture];
        
        NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];;
        [videoSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [videoSettings setObject:[NSNumber numberWithInteger:480] forKey:AVVideoWidthKey];
        [videoSettings setObject:[NSNumber numberWithInteger:640] forKey:AVVideoHeightKey];
        
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@recording.mp4", NSTemporaryDirectory()];
        self.currentlyRecordingUrl = [[NSURL alloc] initFileURLWithPath:outputPath];
        unlink([[self.currentlyRecordingUrl path] UTF8String]); // If a file already exists
        
//        [GPUImageMovieWriter alloc] initWith
        self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.currentlyRecordingUrl size:CGSizeMake(480.0, 640.0) fileType:AVFileTypeMPEG4 outputSettings:videoSettings];
        //        [self.movieWriter setHasAudioTrack:TRUE audioSettings:audioSettings];
        self.videoCamera.audioEncodingTarget = self.movieWriter;
        
        [self startRecording];
        YARecordingCompletionBlock comp = ^(NSURL *recordedURL) {
            DLog(@"Recorded and discarded video to kill laggy cam");
        };
        [self performSelector:@selector(stopRecordingWithCompletion:) withObject:comp afterDelay:0.05];
        
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
            [self.currentCameraView removeGestureRecognizer:self.panZoomGesture];
            self.panZoomGesture = nil;
        }
        if (cameraView) {
            [cameraView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
            [cameraView setContentMode:UIViewContentModeScaleAspectFill];
            [self.videoCamera addTarget:cameraView];
            self.pinchZoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchZoom:)];
            self.pinchZoomGesture.delegate = self;
            [cameraView addGestureRecognizer:self.pinchZoomGesture];
            self.panZoomGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanZoom:)];
            self.panZoomGesture.delegate = self;
            self.panZoomGesture.enabled = NO;
            [cameraView addGestureRecognizer:self.panZoomGesture];

        }

    }
    self.currentCameraView = cameraView;
}

- (void)pauseCamera {
    if (self.isInitialized){
        DLog(@"pausing camera capture");
        [self.videoCamera pauseCameraCapture];
        [self.delegate setFrontFacingFlash:NO];
        [self.videoCamera stopCameraCapture];
        runSynchronouslyOnVideoProcessingQueue(^{
            glFinish();
        });
    }
}

- (void)resumeCamera {
    if (self.isInitialized) {
        DLog(@"resuming camera capture");
        [self.videoCamera resumeCameraCapture];
        [self.videoCamera startCameraCapture];
    }
}

- (void)startRecording {
    if (!self.isInitialized) return;
    self.panZoomGesture.enabled = YES;
    self.pinchZoomGesture.enabled = NO;
    
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
        
        if(self.currentFilter){
            [self.currentFilter addTarget:self.movieWriter];
        } else {
            [self.videoCamera addTarget:self.movieWriter];
        }
        
        self.movieWriter.encodingLiveVideo = YES;
        self.movieWriter.shouldPassthroughAudio = NO; // default YES
        self.movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
        //        [self.movieWriter setHasAudioTrack:TRUE audioSettings:audioSettings];
        self.videoCamera.audioEncodingTarget = self.movieWriter;
        
        [self.movieWriter startRecording];
        
        self.capturePreviewImage = nil;
        self.previewImageFilter = [GPUImageFilter new];
        
        if (self.currentFilter) {
            [self.currentFilter addTarget:self.previewImageFilter];
        } else {
            [self.videoCamera addTarget:self.previewImageFilter];
        }
        
        [self.previewImageFilter useNextFrameForImageCapture];
        self.capturePreviewImage = [self.previewImageFilter imageFromCurrentFramebufferWithOrientation:UIImageOrientationUp];
    });
    
    
    //    [self performSelector:@selector(gpuSwitchCamera) withObject:self afterDelay:3.0];
    
    
    DLog(@"start recording video?!?!?!");
}

- (void)stopRecordingWithCompletion:(YARecordingCompletionBlock)completion {
    if (!self.isInitialized) return;
    self.panZoomGesture.enabled = NO;
    self.pinchZoomGesture.enabled = YES;

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

- (void)handlePanZoom:(UIPanGestureRecognizer *)recognizer {
    CGFloat translation = [recognizer translationInView:self.currentCameraView].y; // negative for up, pos for down
    NSLog(@"Translation y:%f",translation);
    if (translation >= 0) {
        CGFloat scaleZeroToOne = 1 - (translation / (VIEW_HEIGHT/2));
        [self setZoomFactor:self.beginGestureScale * scaleZeroToOne];
    } else {
        CGFloat scaleOneToFour = 1 + (ABS(translation) / (VIEW_HEIGHT/4));
        [self setZoomFactor:self.beginGestureScale * scaleOneToFour];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isEqual:self.pinchZoomGesture]) {
        self.beginGestureScale = self.zoomFactor;
    }
    if ([gestureRecognizer isEqual:self.panZoomGesture]) {
        self.beginGestureScale = self.zoomFactor;
    }
    return YES;
}


- (NSString *)nextFilter {
    
    [self removeFilterAtIndex:self.filterIndex];
    
    self.filterIndex++;
    if(self.filterIndex > ([self.filters count] - 1)){
        self.filterIndex = 0;
    }
    
    [self addFilterAtIndex:self.filterIndex];
    
    NSLog(@"%@", self.filters[self.filterIndex]);
    
    return self.filters[self.filterIndex];
}

- (NSString *)previousFilter {
    [self removeFilterAtIndex:self.filterIndex];
    
    self.filterIndex--;
    if(self.filterIndex == -1){
        self.filterIndex = [self.filters count] - 1;
    }
    
    [self addFilterAtIndex:self.filterIndex];
    
    return self.filters[self.filterIndex];
}

- (NSString *)removeAllFilters {
    return @"#nofilter";
}

- (void)removeFilterAtIndex:(NSUInteger)index {
    switch (index) {
        case 0: {
            // #nofilter
            break;
        }
        default: {
            [self.doozyTimer invalidate];
            [self.currentFilter removeTarget:self.currentCameraView];
            [self.videoCamera removeTarget:self.currentFilter];
            [self.videoCamera addTarget:self.currentCameraView];
            self.currentFilter = nil;
            break;
        }
    }
    
}

- (void)addFilterAtIndex:(NSUInteger)index {
    switch (index) {
        case 0: {
            // #nofilter
            NSLog(@"case 0");
            break;
            
        }
        case 2: {
            // toon
            GPUImageSwirlFilter *swirl = [[GPUImageSwirlFilter alloc] init];
            [swirl setRadius:0.8];
            [swirl setAngle:0.06];
            
            self.currentFilter = swirl;
            self.doozyProgress = 0;
            self.doozyTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(changeDoozy) userInfo:nil repeats:YES];
            
            [self.currentFilter addTarget:self.currentCameraView];
            [self.videoCamera removeTarget:self.currentCameraView];
            [self.videoCamera addTarget:self.currentFilter];
            break;
        }
//        case 3: {
//            GPUImageMosaicFilter *filter = [[GPUImageMosaicFilter alloc] init];
//            [filter setColorOn:NO];
//            [filter setDisplayTileSize:CGSizeMake(0.005, 0.005)];
//            [filter setTileSet:@"squares.png"];
//            self.currentFilter = filter;
//            [self.currentFilter addTarget:self.currentCameraView];
//            [self.videoCamera removeTarget:self.currentCameraView];
//            [self.videoCamera addTarget:self.currentFilter];
//            break;
//        }
        case 1: {
            GPUImageBulgeDistortionFilter *filter = [[GPUImageBulgeDistortionFilter alloc] init];
            [filter setRadius:0.4];
            self.currentFilter = filter;
            [self.currentFilter addTarget:self.currentCameraView];
            [self.videoCamera removeTarget:self.currentCameraView];
            [self.videoCamera addTarget:self.currentFilter];
            break;
            
            
        }
        case 3: {
            GPUImageLowPassFilter *filter =[[GPUImageLowPassFilter alloc] init];
            [filter setFilterStrength:0.82];
            self.currentFilter = filter;
            [self.currentFilter addTarget:self.currentCameraView];
            [self.videoCamera removeTarget:self.currentCameraView];
            [self.videoCamera addTarget:self.currentFilter];
            
            break;
        }
        case 4: {
            GPUImageRGBFilter *filter = [[GPUImageRGBFilter alloc] init];
            // Pink RGB
            [filter setRed:1.60];
            [filter setGreen:0];
            [filter setBlue:1.1];
            self.currentFilter = filter;
            [self.currentFilter addTarget:self.currentCameraView];
            [self.videoCamera removeTarget:self.currentCameraView];
            [self.videoCamera addTarget:self.currentFilter];
            
            break;
        }
            
        default:
            break;
    }
}

- (void)changeDoozy {
    if ([self.currentFilter isKindOfClass:[GPUImageSwirlFilter class]]) {
        self.doozyProgress += .0168;
        [(GPUImageSwirlFilter *)self.currentFilter setCenter:CGPointMake(.5 + (cosf(self.doozyProgress) * 0.3), .5 + (sinf(self.doozyProgress) * 0.3))];
    }
}



@end
