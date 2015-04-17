//
//  YACaptureSession.m
//  Yaga
//
//  Created by Iegor Shapanov on 4/17/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACaptureSession.h"
#import "YAAssetsCreator.h"
#import "YAUser.h"
@interface YACaptureSession ()

@property (strong, nonatomic) NSNumber *recording;
@property (strong, nonatomic) NSDate *recordingTime;
@property (nonatomic, strong) dispatch_semaphore_t recordingSemaphore;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;
@end

@implementation YACaptureSession
+ (YACaptureSession*)captureSession
{
    static dispatch_once_t _singletonPredicate;
    static YACaptureSession *_session = nil;
    
    dispatch_once(&_singletonPredicate, ^{
        _session = [[YACaptureSession alloc] init];
    });
    if (![_session.captureSession isRunning])
        [_session initCaptureSession];
    
    return _session;
}

- (instancetype)init
{
    if (self = [super init])
    {
        [self initCaptureSession];
    }
    return self;
}

- (void)initCaptureSession {
    self.captureSession = [[AVCaptureSession alloc] init];
    
    [self.captureSession beginConfiguration];
    
    self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    
    //  [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
    //  [(AVCaptureVideoPreviewLayer *)(self.cameraView.layer) setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self setupVideoInputForSession:self.captureSession];
    });
    
    [self.captureSession commitConfiguration];
}

- (void)setupVideoInputForSession:(AVCaptureSession*)session {
    NSError *error = nil;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionBack)
        {
            captureDevice = device;
            break;
        }
    }
    
    if([captureDevice lockForConfiguration:nil]){
        if([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        [captureDevice unlockForConfiguration];
    }
    
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (error)
    {
        DLog(@"add video input error: %@", error);
    }
    
    if ([session canAddInput:self.videoInput])
    {
        [session addInput:self.videoInput];
    }
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if ([session canAddOutput:self.movieFileOutput])
    {
        [session addOutput:self.movieFileOutput];
    }
    
    AVAuthorizationStatus audioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioStatus == AVAuthorizationStatusAuthorized) {
        [self setupAudioInputForSession:session];
        [session startRunning];
    } else {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
                                     if (granted) {
                                         [self setupAudioInputForSession:session];
                                         [session startRunning];
                                     }
                                 }];
    }
    
}

- (void)setupAudioInputForSession:(AVCaptureSession*)session {
    NSError *error = nil;
    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if (error)
    {
        DLog(@"add audio input error: %@", error);
    }
    //Don't add just now to allow bg audio to play
    //self.audioInputAdded = NO;
    if ([session canAddInput:audioInput])
    {
        [session addInput:audioInput];
    }
    
}

- (void)closeCamera {
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    // Don't try to configure anything if no permissions are granted. This would be rare anyway.
    if (videoStatus == AVAuthorizationStatusAuthorized) {
        if (self.captureSession) {
            [self.captureSession beginConfiguration];
            for(AVCaptureDeviceInput *input in self.captureSession.inputs){
                [self.captureSession removeInput:input];
            }
            [self.captureSession commitConfiguration];
            
            if ([self.captureSession isRunning])
                [self.captureSession stopRunning];
        }
        self.captureSession = nil;
    }
}

- (void)switchCamera
{
    AVCaptureDevice *currentVideoDevice = [[self videoInput] device];
    AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
    AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
    
    switch (currentPosition)
    {
        case AVCaptureDevicePositionUnspecified:
            preferredPosition = AVCaptureDevicePositionFront;
            break;
        case AVCaptureDevicePositionBack:
            preferredPosition = AVCaptureDevicePositionFront;
            break;
        case AVCaptureDevicePositionFront:
            preferredPosition = AVCaptureDevicePositionBack;
            break;
    }
    
    //[self addAudioInput];
    
    AVCaptureDevice *videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    
    if([videoDevice lockForConfiguration:nil]){
        if([videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            [videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if([videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            [videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        [videoDevice unlockForConfiguration];
    }
    
    
    [[self captureSession] beginConfiguration];
    
    [[self captureSession] removeInput:[self videoInput]];
    if ([[self captureSession] canAddInput:videoDeviceInput])
    {
        [[self captureSession] addInput:videoDeviceInput];
        [self setVideoInput:videoDeviceInput];
    }
    else
    {
        [[self captureSession] addInput:[self videoInput]];
    }
    
    [[self captureSession] commitConfiguration];
}

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}



- (void) startRecordingVideo {
    if(!self.captureSession.outputs.count)
        return;
    
    //    AVCaptureMovieFileOutput *aMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    //Create temporary URL to record to
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
        {
            //Error - handle if requried
        }
    }
    //Start recording
    
    self.recordingSemaphore = dispatch_semaphore_create(0);
    [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}

- (void) stopRecordingVideo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(self.recordingSemaphore)
            dispatch_semaphore_wait(self.recordingSemaphore, DISPATCH_TIME_FOREVER);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.movieFileOutput stopRecording];
            DLog(@"stop recording video");
        });
    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    dispatch_semaphore_signal(self.recordingSemaphore);
    
    DLog(@"didStartRecordingToOutputFileAtURL");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    DLog(@"didFinishRecordingToOutputFileAtURL");
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            RecordedSuccessfully = [value boolValue];
        }
    }
    NSDate *recordingFinished = [NSDate date];
    NSTimeInterval executionTime = [recordingFinished timeIntervalSinceDate:self.recordingTime];
    
    
    if (RecordedSuccessfully) {
        
        if(error) {
            [YAUtils showNotification:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] type:YANotificationTypeError];
            return;
        }
        
        if(executionTime < 0.5){
            return;
        }
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:outputFileURL.path error:nil];
        
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        
        DLog(@"file size: %lld", fileSize);
        
        [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:outputFileURL addToGroup:[YAUser currentUser].currentGroup];
        
    } else {
        [YAUtils showNotification:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] type:YANotificationTypeError];
    }
    
}


@end
