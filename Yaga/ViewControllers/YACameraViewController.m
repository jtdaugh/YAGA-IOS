//
//  YACameraViewController.m
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YACameraViewController.h"
#import "FBShimmeringView.h"

#import "YAUser.h"
#import "YAUtils.h"
#import "AZNotification.h"
#import "YAGifGenerator.h"

@interface YACameraViewController ()
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (strong, nonatomic) FBShimmeringView *instructions;
@property (strong, nonatomic) UIView *indicator;
@property (strong, nonatomic) UILabel *indicatorText;
@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSNumber *recording;
@property (strong, nonatomic) NSNumber *FrontCamera;

@property (strong, nonatomic) NSNumber *previousBrightness;
@property (strong, nonatomic) NSMutableArray *cameraAccessories;

@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;

@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (nonatomic, strong) UIButton *switchGroupsButton;
@end

@implementation YACameraViewController

- (id)init {
    self = [super init];
    if(self) {
        self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0, -0, VIEW_WIDTH, VIEW_HEIGHT / 2)];
        self.view.frame = CGRectMake(0, -0, VIEW_WIDTH, VIEW_HEIGHT / 2);
        [self.cameraView setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:self.cameraView];
        
        [self.cameraView setUserInteractionEnabled:YES];
        
        self.cameraAccessories = [@[] mutableCopy];
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        [longPressGestureRecognizer setMinimumPressDuration:0.2f];
        longPressGestureRecognizer.delegate = self;
        [self.cameraView addGestureRecognizer:longPressGestureRecognizer];
        
        self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self.white setBackgroundColor:[UIColor whiteColor]];
        [self.white setAlpha:0.95];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFlashMode:)];
        tapGestureRecognizer.delegate = self;
        [self.white addGestureRecognizer:tapGestureRecognizer];
        
        CGFloat gutter = 40, height = 24;
        self.instructions = [[FBShimmeringView alloc] initWithFrame:CGRectMake(gutter, 8, self.cameraView.frame.size.width - gutter*2, height)];
        [self.instructions setUserInteractionEnabled:NO];
        //    [self.instructions setAlpha:0.6];
        
        UILabel *instructionText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.instructions.frame.size.width, self.instructions.frame.size.height)];
        [instructionText setText:RECORD_INSTRUCTION];
        [instructionText setFont:[UIFont fontWithName:BIG_FONT size:18]];
        [instructionText setTextAlignment:NSTextAlignmentCenter];
        [instructionText setTextColor:[UIColor whiteColor]];
        
        instructionText.layer.shadowColor = [[UIColor blackColor] CGColor];
        instructionText.layer.shadowRadius = 1.0f;
        instructionText.layer.shadowOpacity = 1.0;
        instructionText.layer.shadowOffset = CGSizeZero;
        
        self.indicatorText = instructionText;
        //    [instructionText setBackgroundColor:PRIMARY_COLOR];
        
        //    [self.instructions setContentView:instructionText];
        self.instructions.shimmering = NO;
        
        [self.cameraView addSubview:self.instructions];
        [self.cameraAccessories addObject:self.instructions];
        
        CGFloat size = 44;
        UIButton *switchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width-size- 10, 10, size, size)];
        //    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
        [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
        [switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
        [switchButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.switchButton = switchButton;
        [self.cameraAccessories addObject:self.switchButton];
        [self.cameraView addSubview:self.switchButton];
        
        UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, size, size)];
        //    flashButton.translatesAutoresizingMaskIntoConstraints = NO;
        [flashButton addTarget:self action:@selector(switchFlashMode:) forControlEvents:UIControlEventTouchUpInside];
        [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
        [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.flashButton = flashButton;
        [self.cameraAccessories addObject:self.flashButton];
        [self.cameraView addSubview:self.flashButton];
        
        
        //switch groups button
        gutter = 96, height = 42;
        self.switchGroupsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.cameraView.frame.size.height - height, self.cameraView.frame.size.width , height)];
        //    [self.groupButton setTitle:@"LindenFest 2014" forState:UIControlStateNormal];
        [self.switchGroupsButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:16]];
        [self.switchGroupsButton addTarget:self action:@selector(toggleGroups:) forControlEvents:UIControlEventTouchUpInside];
        [self.switchGroupsButton setTitle:[NSString stringWithFormat:@"%@ · %@", [YAUser currentUser].currentGroup.name, @"Switch"] forState:UIControlStateNormal];
        
        self.switchGroupsButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.switchGroupsButton.layer.shadowRadius = 1.0f;
        self.switchGroupsButton.layer.shadowOpacity = 1.0;
        self.switchGroupsButton.layer.shadowOffset = CGSizeZero;
        
        [self.cameraAccessories addObject:self.switchGroupsButton];
        [self.cameraView addSubview:self.switchGroupsButton];
        
        [self initCamera:^{
        }];
    }
    return self;
}

- (void)initCamera:(void (^)())block {
    
    NSLog(@"init camera");
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
    [(AVCaptureVideoPreviewLayer *)(self.cameraView.layer) setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    //set still image output
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        
        NSError *error = nil;
        
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if(status != AVAuthorizationStatusAuthorized){ // not determined
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(granted){ // Access has been granted ..do something
                    NSLog(@"Granted");
                } else { // Access denied ..do something
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *alertMessage = NSLocalizedString(@"NO CAMERA ALERT MESSAGE", nil);
                        UIAlertController *alertController = [UIAlertController
                                                              alertControllerWithTitle:NSLocalizedString(@"Warning", nil)
                                                              message:alertMessage
                                                              preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *okAction = [UIAlertAction
                                                   actionWithTitle:NSLocalizedString(@"OK", nil)
                                                   style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action)
                                                   {
                                                   }];
                        [alertController addAction:okAction];
                        [self presentViewController:alertController animated:YES completion:nil];
                    });
                }
            }];
        } else {
            
            NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
            AVCaptureDevice *captureDevice = [devices firstObject];
            
            for (AVCaptureDevice *device in devices)
            {
                if ([device position] == AVCaptureDevicePositionFront)
                {
                    captureDevice = device;
                    break;
                }
            }
            
            //        [captureDevice lockForConfiguration:nil];
            //        [captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 1)];
            //        [captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 1)];
            //        [captureDevice unlockForConfiguration];
            
            self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
            
            if (error)
            {
                NSLog(@"add video input error: %@", error);
            }
            
            if ([self.session canAddInput:self.videoInput])
            {
                [self.session addInput:self.videoInput];
            }
            
            AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
            self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
            
            if (error)
            {
                NSLog(@"add audio input error: %@", error);
            }
            
            if ([self.session canAddInput:self.audioInput])
            {
                [self.session addInput:self.audioInput];
            }
            
            self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            
            if ([self.session canAddOutput:self.movieFileOutput])
            {
                [self.session addOutput:self.movieFileOutput];
            }
            
            [self.session startRunning];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                block();
            }];
        }
    });
}

- (void)addAudioInput {
    
    NSError *error = nil;
    
    if(error){
        NSLog(@"set play and record error: %@", error);
    }
    
    NSLog(@"audio input added!");
}

- (void)closeCamera {
    [self.session beginConfiguration];
    for(AVCaptureDeviceInput *input in self.session.inputs){
        [self.session removeInput:input];
    }
    [self.session commitConfiguration];
    [self.session stopRunning];
}

- (void)handleHold:(UITapGestureRecognizer *)recognizer {
    NSLog(@"%ld", (unsigned long)recognizer.state);
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self endHold];
    } else if (recognizer.state == UIGestureRecognizerStateBegan){
        [self startHold];
    }
}

- (void)startHold {
    
    NSLog(@"starting hold");
    
    self.recording = [NSNumber numberWithBool:YES];
    self.indicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView.frame.size.width, self.cameraView.frame.size.height/8)];
    [self.indicator setBackgroundColor:PRIMARY_COLOR];
    [self.indicator setUserInteractionEnabled:NO];
    [self.indicatorText setText:@"Recording..."];
    [self.cameraView addSubview:self.indicator];
    [self.cameraView bringSubviewToFront:self.instructions];
    
    [UIView animateWithDuration:10.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.indicator setFrame:CGRectMake(self.cameraView.frame.size.width, 0, 0, self.indicator.frame.size.height)];
    } completion:^(BOOL finished) {
        if(finished){
            [self endHold];
        }
        //
    }];
    
    [self startRecordingVideo];
    
}

- (void) endHold {
    if([self.recording boolValue]){
        [self.indicatorText setText:RECORD_INSTRUCTION];
        [self.indicator removeFromSuperview];
        [self stopRecordingVideo];
        // Do Whatever You want on End of Gesture
        self.recording = [NSNumber numberWithBool:NO];
    }
}

- (void) startRecordingVideo {
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
    [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    
}

- (void) stopRecordingVideo {
    [self.movieFileOutput stopRecording];
    NSLog(@"stop recording video");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully) {
        NSString *filename = [[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:@"mov"];
        NSURL *videoPathURL = [[YAUtils cachesDirectory] URLByAppendingPathComponent:filename];
        
        NSError *error;
        [[NSFileManager defaultManager] moveItemAtURL:outputFileURL toURL:videoPathURL error:&error];
        
        if(error) {
            [AZNotification showNotificationWithTitle:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] controller:self
                                     notificationType:AZNotificationTypeError
                                         startedBlock:nil];
            return;
        }
        
        YAGifGenerator *gen = [YAGifGenerator new];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoPathURL options:nil];
        NSURL *gifURL = [[videoPathURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"gif"];
        
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        [gen crateGifAtUrl:gifURL fromAsset:asset completionHandler:^(NSError *error, NSURL *gifUrl) {
            if(error) {
                [AZNotification showNotificationWithTitle:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] controller:self
                                         notificationType:AZNotificationTypeError
                                             startedBlock:nil];
                return;
            }
            
            //save
            dispatch_async(dispatch_get_main_queue(), ^{
                [[RLMRealm defaultRealm] beginWriteTransaction];
                
                YAVideo *video = [YAVideo new];
                video.movPath = videoPathURL.absoluteString;
                video.gifPath = gifUrl.absoluteString;
                [[YAUser currentUser].currentGroup.videos addObject:video];
                [[RLMRealm defaultRealm] commitWriteTransaction];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"new_video_taken" object:nil];
                
                //upload
                [YAUtils uploadVideoRecoringFromUrl:outputFileURL completion:^(NSError *error) {
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    if(error) {
                        [AZNotification showNotificationWithTitle:[NSString stringWithFormat:@"Unable to upload recording, %@", error.localizedDescription] controller:self
                                                 notificationType:AZNotificationTypeError
                                                     startedBlock:nil];
                    }
                    
                }];
                
            });
        }];
        
        
    } else {
        [AZNotification showNotificationWithTitle:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] controller:self
                                 notificationType:AZNotificationTypeError
                                     startedBlock:nil];
    }
    
}

- (void)switchCamera:(id)sender { //switch cameras front and rear cameras
    //    int *x = NULL; *x = 42;
    
    dispatch_async([self sessionQueue], ^{
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
        
        [self addAudioInput];
        
        AVCaptureDevice *videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureFlashButton:NO];
        });
        
        [[self session] beginConfiguration];
        
        [[self session] removeInput:[self videoInput]];
        if ([[self session] canAddInput:videoDeviceInput])
        {
            [[self session] addInput:videoDeviceInput];
            [self setVideoInput:videoDeviceInput];
        }
        else
        {
            [[self session] addInput:[self videoInput]];
        }
        
        [[self session] commitConfiguration];
        
    });
    
    //    [self.session beginConfiguration];
    //    [self.session commitConfiguration];
    
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

- (void)switchFlashMode:(id)sender {
    
    NSLog(@"switching flash mode");
    AVCaptureDevice *currentVideoDevice = [[self videoInput] device];
    
    if([currentVideoDevice position] == AVCaptureDevicePositionBack){
        // back camera
        [currentVideoDevice lockForConfiguration:nil];
        if(self.flash){
            //turn flash off
            if([currentVideoDevice isTorchModeSupported:AVCaptureTorchModeOff]){
                [currentVideoDevice setTorchMode:AVCaptureTorchModeOff];
            }
            [self configureFlashButton:NO];
        } else {
            //turn flash on
            NSError *error = nil;
            if([currentVideoDevice isTorchModeSupported:AVCaptureTorchModeOn]){
                [currentVideoDevice setTorchModeOnWithLevel:0.8 error:&error];
            }
            if(error){
                NSLog(@"error: %@", error);
            }
            
            [self configureFlashButton:YES];
        }
        [currentVideoDevice unlockForConfiguration];
        
    } else if([currentVideoDevice position] == AVCaptureDevicePositionFront) {
        //front camera
        if(self.flash){
            // turn flash off
            if(self.previousBrightness){
                [[UIScreen mainScreen] setBrightness:[self.previousBrightness floatValue]];
            }
            [self.white removeFromSuperview];
            [self configureFlashButton:NO];
        } else {
            // turn flash on
            self.previousBrightness = [NSNumber numberWithFloat: [[UIScreen mainScreen] brightness]];
            [[UIScreen mainScreen] setBrightness:1.0];
            [self.view addSubview:self.white];
            [self.view bringSubviewToFront:self.cameraView];
            [self.view bringSubviewToFront:self.switchGroupsButton];
            [self configureFlashButton:NO];
        }
        
    }
}

- (void)configureFlashButton:(BOOL)flash {
    self.flash = flash;
    if(flash){
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOn"] forState:UIControlStateNormal];
    } else {
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    }
}

- (void)toggleGroups:(id)sender {
    [self.toggleGroupDelegate performSelector:self.toggleGroupSeletor withObject:sender afterDelay:0];
}

@end
