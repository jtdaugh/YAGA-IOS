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

@interface YACameraViewController ()
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (strong, nonatomic) FBShimmeringView *instructions;
@property (strong, nonatomic) UIView *indicator;
@property (strong, nonatomic) UILabel *indicatorText;
@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSNumber *recording;
@property (strong, nonatomic) NSNumber *FrontCamera;

@property (strong, nonatomic) NSNumber *previousBrightness;

@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;

@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) NSMutableArray *cameraAccessories;
@property (strong, nonatomic) UIButton *switchCameraButton;
@property (strong, nonatomic) UIButton *switchGroupsButton;
@property (strong, nonatomic) UIButton *groupButton;

@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *recordButton;

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
        self.cameraView.autoresizingMask = UIViewAutoresizingNone;
        
//        self.tapToFocusRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(configureFocusPoint:)];
//        [self.cameraView addGestureRecognizer:self.tapToFocusRecognizer];
        
        UILongPressGestureRecognizer *longPressGestureRecognizerCamera = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        [longPressGestureRecognizerCamera setMinimumPressDuration:0.2f];
        [self.cameraView addGestureRecognizer:longPressGestureRecognizerCamera];
        
        self.cameraAccessories = [@[] mutableCopy];
        
        self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self.white setBackgroundColor:[UIColor whiteColor]];
        [self.white setAlpha:0.95];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFlashMode:)];
        tapGestureRecognizer.delegate = self;
        [self.white addGestureRecognizer:tapGestureRecognizer];
    
//        CGFloat gutter = 40, height = 24;
//        self.instructions = [[FBShimmeringView alloc] initWithFrame:CGRectMake(gutter, 8, self.cameraView.frame.size.width - gutter*2, height)];
//        [self.instructions setUserInteractionEnabled:NO];
        //    [self.instructions setAlpha:0.6];
        
//        UILabel *instructionText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.instructions.frame.size.width, self.instructions.frame.size.height)];
//        [instructionText setText:NSLocalizedString(@"RECORD_TIP", @"")];
//        [instructionText setFont:[UIFont fontWithName:BIG_FONT size:18]];
//        [instructionText setTextAlignment:NSTextAlignmentCenter];
//        [instructionText setTextColor:[UIColor whiteColor]];
//        
//        instructionText.layer.shadowColor = [[UIColor blackColor] CGColor];
//        instructionText.layer.shadowRadius = 1.0f;
//        instructionText.layer.shadowOpacity = 1.0;
//        instructionText.layer.shadowOffset = CGSizeZero;
//        self.instructions.backgroundColor = [UIColor yellowColor];
//        self.indicatorText = instructionText;
//        //    [instructionText setBackgroundColor:PRIMARY_COLOR];
//        
//        //    [self.instructions setContentView:instructionText];
//        self.instructions.shimmering = NO;
//        
//        [self.cameraView addSubview:self.instructions];
//        [self.cameraAccessories addObject:self.instructions];

        CGFloat size = 44;
        self.switchCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width-size- 10, 10, size, size)];
        //    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.switchCameraButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
        [self.switchCameraButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
        [self.switchCameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
        [self.cameraAccessories addObject:self.switchCameraButton];
        [self.cameraView addSubview:self.switchCameraButton];
        
        UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, size, size)];
        //    flashButton.translatesAutoresizingMaskIntoConstraints = NO;
        [flashButton addTarget:self action:@selector(switchFlashMode:) forControlEvents:UIControlEventTouchUpInside];
        [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
        [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.flashButton = flashButton;
        [self.cameraAccessories addObject:self.flashButton];
        [self.cameraView addSubview:self.flashButton];
        
        //current group
        CGFloat groupButtonXOrigin = flashButton.frame.origin.x + flashButton.frame.size.width + 5;
        self.groupButton = [[UIButton alloc] initWithFrame:CGRectMake(groupButtonXOrigin, 10, self.switchCameraButton.frame.origin.x - groupButtonXOrigin - 10 , size)];
        [self.groupButton addTarget:self action:@selector(nameGroup:) forControlEvents:UIControlEventTouchUpInside];
        [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
        [self.groupButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:16]];
        self.groupButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.groupButton.layer.shadowRadius = 1.0f;
        self.groupButton.layer.shadowOpacity = 1.0;
        self.groupButton.layer.shadowOffset = CGSizeZero;
        [self.cameraAccessories addObject:self.groupButton];
        [self.cameraView addSubview:self.groupButton];

        //record button
        self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width/2.0 - recordButtonWidth/2.0, self.cameraView.frame.size.height - recordButtonWidth/2.0, recordButtonWidth, recordButtonWidth)];
        [self.recordButton setBackgroundColor:[UIColor redColor]];
        [self.recordButton.layer setCornerRadius:recordButtonWidth/2.0];
        [self.recordButton.layer setBorderColor:[UIColor whiteColor].CGColor];
        [self.recordButton.layer setBorderWidth:4.0f];
        
        UILongPressGestureRecognizer *longPressGestureRecognizerButton = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        [longPressGestureRecognizerButton setMinimumPressDuration:0.2f];
        [self.recordButton addGestureRecognizer:longPressGestureRecognizerButton];
        [self.cameraAccessories addObject:self.recordButton];
        [self.view addSubview:self.recordButton];
        
        //switch groups button
        self.switchGroupsButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH-120, self.cameraView.frame.size.height - 30 - 4, 110, 30)];
        [self.switchGroupsButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [self.switchGroupsButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:16]];
        [self.switchGroupsButton addTarget:self action:@selector(toggleGroups:) forControlEvents:UIControlEventTouchUpInside];
        [self.switchGroupsButton setTitle:@"Switch groups" forState:UIControlStateNormal];
        
        self.switchGroupsButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.switchGroupsButton.layer.shadowRadius = 1.0f;
        self.switchGroupsButton.layer.shadowOpacity = 1.0;
        self.switchGroupsButton.layer.shadowOffset = CGSizeZero;
        
        [self.cameraAccessories addObject:self.switchGroupsButton];
        [self.cameraView addSubview:self.switchGroupsButton];
        
        [self initCamera];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"applicationWillResignActive" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"applicationWillEnterForeground" object:nil];
}

- (void)applicationWillResignActive {
    [self closeCamera];
}

- (void)applicationWillEnterForeground {
    [self initCamera];
}

- (void)initCamera {
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
        }
    });
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
    
    [UIView animateWithDuration:0.2 animations:^{
        [self showCameraAccessories:0];
        [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    }];
    
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
        
        [UIView animateWithDuration:0.2 animations:^{
            [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2)];
            [self showCameraAccessories:YES];
        }];
        
        [self.indicatorText setText:NSLocalizedString(@"RECORD_TIP", @"")];
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
        
        if(error) {
            [AZNotification showNotificationWithTitle:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] controller:self
                                     notificationType:AZNotificationTypeError
                                         startedBlock:nil];
            return;
        }
        
        [YAVideo crateVideoAndAddToCurrentGroupFromRecording:outputFileURL completionHandler:^(NSError *error, YAVideo *video) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(error) {
                    [AZNotification showNotificationWithTitle:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] controller:self
                                             notificationType:AZNotificationTypeError
                                                 startedBlock:nil];
                    return;
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_VIDEO_NOTIFICATION object:video];
                }
            });
            
        } jpgCreatedHandler:^(NSError *error, YAVideo *video) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NEW_VIDEO_TAKEN_NOTIFICATION object:nil];
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
        
        //[self addAudioInput];
        
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
            [self showCameraAccessories:YES];
            [self configureFlashButton:YES];
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
    [self.delegate toggleGroups];
}

- (void)didEnterBackground {
    if(self.flash && [[self.videoInput device] position] == AVCaptureDevicePositionFront){
        [self switchFlashMode:nil];
    }
    [self closeCamera];
}

- (void)willEnterForeground {
    [self initCamera];
}

- (void)showCameraAccessories:(BOOL)show {
    for(UIView *v in self.cameraAccessories){
        [v setAlpha:show ? 1 : 0];
        if(show)
            [self.view bringSubviewToFront:v];
    }
    
}

- (void)nameGroup:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CHANGE_GROUP_TITLE", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"CHANGE_GROUP_PLACEHOLDER", @"");
        textField.text = [YAUser currentUser].currentGroup.name;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *newname = [alert.textFields[0] text];
        if(!newname.length)
            return;
        
        [[RLMRealm defaultRealm] beginWriteTransaction];
        [YAUser currentUser].currentGroup.name = newname;
        [[RLMRealm defaultRealm] commitWriteTransaction];
        
        [self.groupButton setTitle:newname forState:UIControlStateNormal];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateCurrentGroup {
    [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
}

#pragma mark - Manual focus
- (void) configureFocusPoint:(UITapGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:[recognizer view]];
    
    NSLog(@"point x: %f, y: %f", point.x, point.y);
    
    CGFloat size = 48;
    
    UIView *square = [[UIView alloc] initWithFrame:CGRectMake(point.x - size/2, point.y - size/2, size, size)];
    square.layer.borderWidth = 1.5f;
    square.layer.borderColor = PRIMARY_COLOR.CGColor;
    
    //    [square.layer setCornerRadius:size/2];
    
    [self.cameraView addSubview:square];
    [square setTransform:CGAffineTransformMakeScale(1.5, 1.5)];
    [square setAlpha:0.0];
    
    [UIView animateKeyframesWithDuration:0.75 delay:0.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
        //
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^{
            //
            [square setTransform:CGAffineTransformIdentity];
            [square setAlpha:1.0];
        }];
        
        [UIView addKeyframeWithRelativeStartTime:0.9 relativeDuration:0.1 animations:^{
            //
            //            [square setTransform:CGAffineTransformMakeScale(0.9, 0.9)];
            [square setAlpha:0.0];
        }];
        
    } completion:^(BOOL finished) {
        //
        [square removeFromSuperview];
    }];
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        //
        [square setTransform:CGAffineTransformIdentity];
    } completion:^(BOOL finished) {
        //
    }];
    
    
    CGPoint focusPoint = [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) captureDevicePointOfInterestForPoint:point];
    
    //    CGPoint focusPoint = [[(AVCaptureVideoPreviewLayer *) self.cameraView.layer] captureDevicePointOfInterestForPoint:point];
    
    //    CGPoint focusPoint = CGPointMake(point.x / self.cameraView.frame.size.width, point.y / self.cameraView.frame.size.height);
    
    
    //    CGPoint focusPoint = CGPointMake(focus_x, focus_y);
    
    NSLog(@"focus point x: %f, y: %f", focusPoint.x, focusPoint.y);
    
    AVCaptureDevice *device =  [[self videoInput] device];
    
    //    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //    AVCaptureDevice *captureDevice = [devices firstObject];
    //
    //    for (AVCaptureDevice *device in devices) {
    if([device lockForConfiguration:nil]){
        if([device isFocusPointOfInterestSupported]){
            NSLog(@"test");
            //            [device setFocusMode:AVCaptureFocusModeLocked];
            [device setFocusMode:AVCaptureFocusModeLocked];
            [device setFocusPointOfInterest:focusPoint];
            [device setFocusMode:AVCaptureFocusModeLocked];
            //            [device setExposurePointOfInterest:focusPoint];
            //        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        [device unlockForConfiguration];
    }
    //    }
    
    
    
    //    [[[self videoInput] device] setFocusMode:AVCaptureFocusModeLocked];
    
    //    [[[self videoInput] device] setFocusMode:AVCaptureFocusModeAutoFocus];
    //    [device setFocusPointOfInterest:focusPoint];
    //    [device setFocusMode:AVCaptureFocusModeAutoFocus];
    
    
    //    [[[self videoInput] device] setExposureMode:AVCaptureExposureModeAutoExpose];
    //    [[[self videoInput] device] setExposurePointOfInterest:focusPoint];
    
    
}

@end
