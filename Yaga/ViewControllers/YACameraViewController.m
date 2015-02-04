//
//  YACameraViewController.m
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YACameraViewController.h"

#import "YAUser.h"
#import "YAUtils.h"
#import "YAAssetsCreator.h"

#import <ClusterPrePermissions/ClusterPrePermissions.h>

@interface YACameraViewController ()
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
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

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizerCamera;

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
        
        self.cameraAccessories = [@[] mutableCopy];
        
        self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self.white setBackgroundColor:[UIColor whiteColor]];
        [self.white setAlpha:0.95];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFlashMode:)];
        tapGestureRecognizer.delegate = self;
        [self.white addGestureRecognizer:tapGestureRecognizer];
        
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
        self.recordButton.transform = CGAffineTransformMakeScale(0, 0);
        
        UILongPressGestureRecognizer *longPressGestureRecognizerButton = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        [longPressGestureRecognizerButton setMinimumPressDuration:0.2f];
        [self.recordButton addGestureRecognizer:longPressGestureRecognizerButton];
        [self.cameraAccessories addObject:self.recordButton];
        [self.view addSubview:self.recordButton];
        
        //switch groups button
        
        self.switchGroupsButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2+30, self.cameraView.frame.size.height - 40, VIEW_WIDTH - VIEW_WIDTH/2-30, 40)];
        //        self.switchGroupsButton.backgroundColor= [UIColor yellowColor];
        [self.switchGroupsButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [self.switchGroupsButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:16]];
        [self.switchGroupsButton addTarget:self action:@selector(toggleGroups:) forControlEvents:UIControlEventTouchUpInside];
        [self.switchGroupsButton setTitle:[NSString stringWithFormat:@"    %@", NSLocalizedString(@"Switch groups", @"")] forState:UIControlStateNormal];
        
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
        
        [self enableRecording:YES];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateCurrentGroupName];
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

- (void)enableRecording:(BOOL)enable {
    if(enable) {
        self.longPressGestureRecognizerCamera = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        [self.longPressGestureRecognizerCamera setMinimumPressDuration:0.2f];
        [self.cameraView addGestureRecognizer:self.longPressGestureRecognizerCamera];
    }
    else {
        [self.cameraView removeGestureRecognizer:self.longPressGestureRecognizerCamera];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.recordButton.transform = enable ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0, 0);
    }];
}

- (void)initCamera {
    // only init camera if not simulator
    
    if(TARGET_IPHONE_SIMULATOR){
        NSLog(@"no camera, simulator");
    } else {
        
        NSLog(@"init camera");
        
        //set still image output
        
        ClusterPrePermissions *permisions = [ClusterPrePermissions sharedPermissions];
        [permisions showAVPermissionsWithType:ClusterAVAuthorizationTypeCamera
                                        title:NSLocalizedString(@"Access camera", nil)
                                      message:NSLocalizedString(@"Give Yaga access to camera", nil)
                              denyButtonTitle:NSLocalizedString(@"Deny", nil)
                             grantButtonTitle:NSLocalizedString(@"Granted", nil)
                            completionHandler:^(BOOL hasPermission, ClusterDialogResult userDialogResult, ClusterDialogResult systemDialogResult) {
                                if (hasPermission) {
                                    
                                    self.session = [[AVCaptureSession alloc] init];
                                    self.session.sessionPreset = AVCaptureSessionPreset640x480;
                                    
                                    [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
                                    [(AVCaptureVideoPreviewLayer *)(self.cameraView.layer) setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                                    
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
                                        NSLog(@"add video input error: %@", error);
                                    }
                                    
                                    if ([self.session canAddInput:self.videoInput])
                                    {
                                        [self.session addInput:self.videoInput];
                                    }
                                    [permisions showAVPermissionsWithType:ClusterAVAuthorizationTypeMicrophone
                                                                    title:NSLocalizedString(@"Access mic", nil)
                                                                  message:NSLocalizedString(@"Give Yaga access to your mic", nil)
                                                          denyButtonTitle:NSLocalizedString(@"Deny", nil)
                                                         grantButtonTitle:NSLocalizedString(@"Granted", nil)
                                                        completionHandler:^(BOOL hasPermission, ClusterDialogResult userDialogResult, ClusterDialogResult systemDialogResult) {
                                                            if (hasPermission) {
                                                                NSError *error = nil;
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
                                                            }else if(!hasPermission
                                                                     && userDialogResult == ClusterDialogResultNoActionTaken
                                                                     && systemDialogResult == ClusterDialogResultNoActionTaken) {
                                                                [self presentAlertForClusterAVType:ClusterAVAuthorizationTypeMicrophone];
                                                            }
                                                            
                                                            
                                                            [self.session startRunning];
                                                            
                                                        }];
                                } else if(!hasPermission
                                          && userDialogResult == ClusterDialogResultNoActionTaken
                                          && systemDialogResult == ClusterDialogResultNoActionTaken) {
                                    [self presentAlertForClusterAVType:ClusterAVAuthorizationTypeCamera];
                                }
                                
                            }];   
    }
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
    if([self.session.outputs containsObject:self.movieFileOutput]) {
        return;
    }
    
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
            [YAUtils showNotification:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] type:AZNotificationTypeError];
            return;
        }
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:outputFileURL.path error:nil];
        
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        
        NSLog(@"file size: %lld", fileSize);
        
        [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:outputFileURL addToGroup:[YAUser currentUser].currentGroup];
        
    } else {
        [YAUtils showNotification:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] type:AZNotificationTypeError];
    }
    
}

- (void)switchCamera:(id)sender { //switch cameras front and rear cameras
    //    int *x = NULL; *x = 42;
    
    
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
        
        [[YAUser currentUser].currentGroup rename:newname];
        
        [self.groupButton setTitle:newname forState:UIControlStateNormal];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateCurrentGroupName {
    [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
}

- (void)presentAlertForClusterAVType:(ClusterAVAuthorizationType)type {
    NSString *title;
    NSString *message;
    NSString *buttonTitle = NSLocalizedString(@"OK", nil);
    if (type == ClusterAVAuthorizationTypeMicrophone) {
        title = NSLocalizedString(@"Audio permissions not granted", nil);
        message = NSLocalizedString(@"To be able to record audio, allow this in app settings", nil);
        
    } else if (type == ClusterAVAuthorizationTypeCamera) {
        title = NSLocalizedString(@"Video permissions not granted", nil);
        message = NSLocalizedString(@"To be able to shoot video, allow this in app settings", nil);
    }
    
    if ([UIAlertController class]) {
        
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:buttonTitle
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
    }
    else
    {
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:title
                                   message:message
                                  delegate:nil
                         cancelButtonTitle:buttonTitle
                         otherButtonTitles:nil];
        [alertView show];
    }
}
@end
