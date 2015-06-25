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

@implementation YACameraView
@end

@interface YACameraManager ()

@property (weak, nonatomic) YACameraView *currentCameraView;
@property (strong, nonatomic) NSURL *currentlyRecordingUrl;
@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;
@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;

@property (nonatomic, strong) dispatch_semaphore_t recordingSemaphore;
@property (nonatomic) BOOL isInitialized;

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
        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;

        self.isInitialized = NO;
    }
    return self;
}

- (void)initCamera {
    if (self.isInitialized) {
        return;
    }
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
        
    }
}

- (void)setCameraView:(YACameraView *)cameraView {
    [cameraView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [cameraView setContentMode:UIViewContentModeScaleAspectFill];
    
    if (![cameraView isEqual:self.currentCameraView] && cameraView) {
        [self.videoCamera removeTarget:self.currentCameraView];
        [self.videoCamera addTarget:cameraView];
    }
    self.currentCameraView = cameraView;
}

- (void)closeCamera {
    self.isInitialized = NO;
    [self.videoCamera stopCameraCapture];
}

- (void)startRecording {
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
    });
    
    
    //    [self performSelector:@selector(gpuSwitchCamera) withObject:self afterDelay:3.0];
    
    
    NSLog(@"start recording video?!?!?!");
}

- (void)stopRecordingWithCompletion:(YARecordingCompletionBlock)completion {
    NSLog(@"Finish recording?");
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        NSLog(@"Finish recording 2?");
        NSLog(@"recording path: %@ ?", self.currentlyRecordingUrl.path);
        
        [self.videoCamera removeTarget:self.movieWriter];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.videoCamera startCameraCapture];
        });
        completion(self.currentlyRecordingUrl);
    }];

}

- (void)switchCamera {
    [self.videoCamera rotateCamera];
}

- (void)forceFrontFacingCamera {
    AVCaptureDevicePosition position = [self.videoCamera cameraPosition];
    if (position == AVCaptureDevicePositionBack) {
        [self.videoCamera rotateCamera];
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

@end
