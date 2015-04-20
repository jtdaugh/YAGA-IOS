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

#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>

@interface YACameraViewController ()
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (strong, nonatomic) UIView *indicator;
@property (strong, nonatomic) UILabel *indicatorText;
@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSNumber *recording;
@property (strong, nonatomic) NSDate *recordingTime;
@property (strong, nonatomic) NSNumber *FrontCamera;

@property (strong, nonatomic) NSNumber *previousBrightness;

@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;

@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) NSMutableArray *cameraAccessories;
@property (strong, nonatomic) UIButton *switchCameraButton;
@property (strong, nonatomic) UIButton *switchGroupsButton;
@property (strong, nonatomic) UIImageView *unviewedVideosBadge;
@property (strong, nonatomic) UIButton *groupButton;

@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *recordButton;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizerCamera;
@property (strong, nonatomic) UITapGestureRecognizer *switchCameraGestureRecognizerCamera;
@property (nonatomic) BOOL audioInputAdded;

@property (nonatomic, strong) UILabel *recordTooltipLabel;

@property (nonatomic, strong) UIButton *openSettingsButton;

@property (nonatomic, strong) dispatch_semaphore_t recordingSemaphore;

@property (nonatomic, strong) CTCallCenter *callCenter;

@property (nonatomic, strong) NSMutableArray *currentRecordingURLs;

@property (strong, nonatomic) UIView *loader;
@property (strong, nonatomic) NSTimer *loaderTimer;
@property (strong, nonatomic) NSMutableArray *loaderTiles;

@property (strong, nonatomic) UIView *recordingIndicator;


@end

@implementation YACameraViewController

- (id)init {
    self = [super init];
    if(self) {
        [YAUtils instance].cameraNeedsRefresh = YES; // So we set up the vid session initially.
        
        self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0, -0, VIEW_WIDTH, VIEW_HEIGHT / 2)];
        self.view.frame = CGRectMake(0, -0, VIEW_WIDTH, VIEW_HEIGHT / 2);
        [self.cameraView setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:self.cameraView];
        [self.cameraView setUserInteractionEnabled:YES];
        self.cameraView.autoresizingMask = UIViewAutoresizingNone;
        
        self.cameraAccessories = [@[] mutableCopy];
        
        self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self.white setBackgroundColor:[UIColor whiteColor]];
        [self.white setAlpha:0.8];
        
        [self.white setUserInteractionEnabled:YES];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFlashMode:)];
        tapGestureRecognizer.delegate = self;
        [self.white addGestureRecognizer:tapGestureRecognizer];
        
        CGFloat size = 60;
        self.switchCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width-size- 10, 10, size, size)];
        //    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.switchCameraButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
        [self.switchCameraButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
        [self.switchCameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        
        [self.cameraAccessories addObject:self.switchCameraButton];
        [self.cameraView addSubview:self.switchCameraButton];
        
        UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, size - 10, size - 10)];
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
        [self.groupButton addTarget:self action:@selector(openGroupOptions:) forControlEvents:UIControlEventTouchUpInside];
        [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
        [self.groupButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
        self.groupButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.groupButton.layer.shadowRadius = 1.0f;
        self.groupButton.layer.shadowOpacity = 1.0;
        self.groupButton.layer.shadowOffset = CGSizeZero;
        [self.cameraAccessories addObject:self.groupButton];
        [self.cameraView addSubview:self.groupButton];
        
        //record button
        self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width/2.0 - recordButtonWidth/2.0, self.cameraView.frame.size.height - 1.0*recordButtonWidth/2.0, recordButtonWidth, recordButtonWidth)];
        [self.recordButton setBackgroundColor:[UIColor redColor]];
        [self.recordButton.layer setCornerRadius:recordButtonWidth/2.0];
        [self.recordButton.layer setBorderColor:[UIColor whiteColor].CGColor];
        [self.recordButton.layer setBorderWidth:4.0f];
        
        [self.recordButton addTarget:self action:@selector(startHold) forControlEvents:UIControlEventTouchDown];
        [self.recordButton addTarget:self action:@selector(endHold) forControlEvents:UIControlEventTouchUpInside];
        [self.recordButton addTarget:self action:@selector(endHold) forControlEvents:UIControlEventTouchUpOutside];
        
//        UILongPressGestureRecognizer *longPressGestureRecognizerButton = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
//        [longPressGestureRecognizerButton setMinimumPressDuration:0.2f];
//        [self.recordButton addGestureRecognizer:longPressGestureRecognizerButton];

        [self.cameraAccessories addObject:self.recordButton];
        [self.view addSubview:self.recordButton];
        
        //switch groups button
        
        self.switchGroupsButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2+30, self.cameraView.frame.size.height - 40, VIEW_WIDTH - VIEW_WIDTH/2-30-10, 40)];
        //        self.switchGroupsButton.backgroundColor= [UIColor yellowColor];
        [self.switchGroupsButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [self.switchGroupsButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
        [self.switchGroupsButton addTarget:self action:@selector(toggleGroups:) forControlEvents:UIControlEventTouchUpInside];
        [self.switchGroupsButton setTitle:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Groups", @"")] forState:UIControlStateNormal];
        
        CGFloat requiredWidth = [self.switchGroupsButton.titleLabel.attributedText size].width;
        CGRect tempFrame = self.switchGroupsButton.frame;
        tempFrame.origin.x = VIEW_WIDTH - 10 - requiredWidth;
        tempFrame.size.width = requiredWidth;
        [self.switchGroupsButton setFrame:tempFrame];
        
        self.switchGroupsButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.switchGroupsButton.layer.shadowRadius = 1.0f;
        self.switchGroupsButton.layer.shadowOpacity = 1.0;
        self.switchGroupsButton.layer.shadowOffset = CGSizeZero;
        
        [self.cameraAccessories addObject:self.switchGroupsButton];
        [self.cameraView addSubview:self.switchGroupsButton];
        
        //unviewed badge
        const CGFloat badgeWidth = 10;
        CGFloat badgeMargin = 8;
        self.unviewedVideosBadge = [[UIImageView alloc] initWithFrame:CGRectMake(self.switchGroupsButton.frame.origin.x - badgeWidth - badgeMargin, self.switchGroupsButton.frame.origin.y + badgeWidth + 5, badgeWidth, badgeWidth)];
        self.unviewedVideosBadge.image = [YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:0.5]];
        self.unviewedVideosBadge.clipsToBounds = YES;
        self.unviewedVideosBadge.layer.cornerRadius = badgeWidth/2;
        [self.cameraAccessories addObject:self.unviewedVideosBadge];
        [self.cameraView addSubview:self.unviewedVideosBadge];
        
        // initializing the loader
        self.loader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        
        int rows = 32, cols = 16;
        
        CGFloat lwidth = VIEW_WIDTH/((float)cols);
        CGFloat lheight = VIEW_HEIGHT/((float)rows);
        
        self.loaderTiles = [[NSMutableArray alloc] init];
        for(int i = 0; i< (rows * 2 * cols); i++){
            int xPos = i%cols;
            int yPos = i/rows;
            
            UIView *loaderTile = [[UIView alloc] initWithFrame:CGRectMake(xPos * lwidth, yPos*lheight, lwidth, lheight)];
            [self.loader addSubview:loaderTile];
            [self.loaderTiles addObject:loaderTile];
        }
        
        CGFloat width = 48;
        self.recordingIndicator = [[UIView alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width/2 - width/2, 20, width, width)];
        UIImageView *monkeyIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
        [monkeyIndicator setImage:[UIImage imageNamed:@"Monkey_Pink"]];
        [self.recordingIndicator addSubview:monkeyIndicator];
        self.recordingIndicator.alpha = 0.0;
        [self.cameraView addSubview:self.recordingIndicator];
        
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.duration = 0.25;
        scaleAnimation.repeatCount = HUGE_VAL;
        scaleAnimation.autoreverses = YES;
        scaleAnimation.fromValue = [NSNumber numberWithFloat:1.618];
        scaleAnimation.toValue = [NSNumber numberWithFloat:1.0];
        
        [self.recordingIndicator.layer addAnimation:scaleAnimation forKey:@"scale"];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(groupDidRefresh:)
                                                     name:GROUP_DID_REFRESH_NOTIFICATION
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(groupDidChange:)
                                                     name:GROUP_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        
        [self updateUviewedViedeosBadge];
        
        if(![[NSUserDefaults standardUserDefaults] boolForKey:kFirstVideoRecorded]) {
            //first start tooltips
            
            CGFloat tooltipPadding = recordButtonWidth / 2 * 3 / 2;
            
            self.recordTooltipLabel = [[UILabel alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - 108, 0, 120, VIEW_HEIGHT/2 - tooltipPadding)];
            NSString *fontName = @"AvenirNext-HeavyItalic";
            CGFloat fontSize = 26;

            self.recordTooltipLabel.font = [UIFont fontWithName:fontName size:fontSize];
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Tap and hold to record\n \u2B07\U0000FE0E"
                                                                         attributes:@{
                                                                                      NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                      NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]
                                                                                      }];
            
            self.recordTooltipLabel.textAlignment = NSTextAlignmentRight;
            self.recordTooltipLabel.attributedText = string;
            self.recordTooltipLabel.numberOfLines = 4;
            self.recordTooltipLabel.textColor = PRIMARY_COLOR;
            [self.view addSubview:self.recordTooltipLabel];
            
            
            NSStringDrawingOptions option = NSStringDrawingUsesLineFragmentOrigin;
            
            NSString *text = self.recordTooltipLabel.text;
            NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:fontName size:fontSize]};
            
            CGRect rect = [text boundingRectWithSize:CGSizeMake(self.recordTooltipLabel.frame.size.width, CGFLOAT_MAX)
                                             options:option
                                          attributes:attributes
                                             context:nil];

            CGRect frame = self.recordTooltipLabel.frame;
            frame.origin.y = VIEW_HEIGHT/2 - rect.size.height - tooltipPadding;
            frame.size.height = rect.size.height;
            self.recordTooltipLabel.frame = frame;
            //warning create varible for all screen sizes
//            CGPoint center = self.view.center;
//            center.x -= 47.f;
//            center.y += 65.f;
//            self.recordTooltipLabel.center = center;
        }

    }
    
    //stop recording on incoming call
    void (^block)(CTCall*) = ^(CTCall* call) {
        DLog(@"Phone call received, state:%@. Stopping recording..", call.callState);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endHold];
        });
    };
    self.callCenter = [[CTCallCenter alloc] init];
    self.callCenter.callEventHandler = block;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([YAUtils instance].cameraNeedsRefresh) {
        [self initCamera];
        [YAUtils instance].cameraNeedsRefresh = NO;
    }
    
    [self enableRecording:YES];

    [self updateCurrentGroupName];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)enableRecording:(BOOL)enable {
    if(enable) {
        self.longPressGestureRecognizerCamera = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        [self.longPressGestureRecognizerCamera setMinimumPressDuration:0.2f];
        [self.cameraView addGestureRecognizer:self.longPressGestureRecognizerCamera];

        self.switchCameraGestureRecognizerCamera = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchCamera:)];
        [self.cameraView addGestureRecognizer:self.switchCameraGestureRecognizerCamera];
    }
    else {
        [self.cameraView removeGestureRecognizer:self.longPressGestureRecognizerCamera];
    }
//    [UIView animateWithDuration:0.2 animations:^{
//        self.recordButton.transforgm = enable ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0, 0);
//    }];
}

- (void)initCamera {
    // only init camera if not simulator
    
    if(TARGET_IPHONE_SIMULATOR){
        DLog(@"no camera, simulator");
    } else {
        
        DLog(@"init camera");
        
        //set still image output
        
        AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (videoStatus == AVAuthorizationStatusAuthorized) {
            
            self.session = [[AVCaptureSession alloc] init];
           
            [self.session beginConfiguration];
            
            self.session.sessionPreset = AVCaptureSessionPreset640x480;
            
            [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
            [(AVCaptureVideoPreviewLayer *)(self.cameraView.layer) setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self setupVideoInput];
            });
            
            [self.session commitConfiguration];
            
            [self removeOpenSettingsButton];
            
        } else {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                     completionHandler:^(BOOL granted) {
                                         self.session = [[AVCaptureSession alloc] init];
                                         [self.session beginConfiguration];
                                         self.session.sessionPreset = AVCaptureSessionPreset640x480;
                                         
                                         [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
                                         [(AVCaptureVideoPreviewLayer *)(self.cameraView.layer) setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                                         if (granted) {
                                             [self setupVideoInput];
                                         } else {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self addOpenSettingsButton];
                                             });
                                             
                                         }
                                         [self.session commitConfiguration];
                                     }];
        }
    }
}

- (void)setupVideoInput {
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
    
    if ([self.session canAddInput:self.videoInput])
    {
        [self.session addInput:self.videoInput];
    }
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if ([self.session canAddOutput:self.movieFileOutput])
    {
        [self.session addOutput:self.movieFileOutput];
    }
    
    AVAuthorizationStatus audioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioStatus == AVAuthorizationStatusAuthorized) {
        [self setupAudioInput];
        [self.session startRunning];
    } else {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
                                     if (granted) {
                                         [self setupAudioInput];
                                         [self.session startRunning];
                                     }
                                 }];
    }
    
}

- (void)setupAudioInput {
    NSError *error = nil;
    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if (error)
    {
        DLog(@"add audio input error: %@", error);
    }
    //Don't add just now to allow bg audio to play
    self.audioInputAdded = NO;
    if ([self.session canAddInput:self.audioInput])
    {
        [self.session addInput:self.audioInput];
    }
    
}

- (void)closeCamera {
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    // Don't try to configure anything if no permissions are granted. This would be rare anyway.
    if (videoStatus == AVAuthorizationStatusAuthorized) {
        if (self.session) {
            [self.session beginConfiguration];
            for(AVCaptureDeviceInput *input in self.session.inputs){
                [self.session removeInput:input];
            }
            [self.session commitConfiguration];
            
            if ([self.session isRunning])
                [self.session stopRunning];
        }
        self.session = nil;
    }
}

- (void)handleHold:(UITapGestureRecognizer *)recognizer {
    DLog(@"%ld", (unsigned long)recognizer.state);
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self endHold];
    } else if (recognizer.state == UIGestureRecognizerStateBegan){
        [self startHold];
    }
}

- (void)startHold {
    DLog(@"starting hold");
    
    self.recordingTime = [NSDate date];
//    //We're starting to shoot so add audio
//    if (!self.audioInputAdded) {
//        [self.session beginConfiguration];
//        [self.session addInput:self.audioInput];
//        self.audioInputAdded = YES;
//        [self.session commitConfiguration];
//    }
    self.currentRecordingURLs = [NSMutableArray new];
    self.recording = [NSNumber numberWithBool:YES];
    self.recordingIndicator.alpha = 1.0;
//    self.indicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView.frame.size.width, self.cameraView.frame.size.height/8)];
//    [self.indicator setBackgroundColor:PRIMARY_COLOR];
//    [self.indicator setUserInteractionEnabled:NO];
//    [self.indicatorText setText:@"Recording..."];
//    [self.view addSubview:self.indicator];
    
    [self.view bringSubviewToFront:self.white];
    [self.view bringSubviewToFront:self.indicator];

    if(self.recordTooltipLabel) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFirstVideoRecorded];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.recordTooltipLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.recordTooltipLabel removeFromSuperview];
            self.recordTooltipLabel = nil;
        }];
        
        [AnalyticsKit logEvent:@"First video post"];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [self showCameraAccessories:0];
        [self.view setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    } completion:^(BOOL finished) {
        
    }];
    
//    [UIView animateWithDuration:MAX_VIDEO_DURATION delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
//        //
//        [self.indicator setFrame:CGRectMake(self.cameraView.frame.size.width, 0, 0, self.indicator.frame.size.height)];
//    } completion:^(BOOL finished) {
//        //
//        if(finished){
//            [self endHold];
//        }
//    }];

    [self performSelector:@selector(endHold) withObject:self afterDelay:MAX_VIDEO_DURATION];
//    [UIView animateWithDuration:MAX_VIDEO_DURATION delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
////        [self.indicator setFrame:CGRectMake(self.cameraView.frame.size.width, 0, 0, self.indicator.frame.size.height)];
//    } completion:^(BOOL finished) {
//        if(finished){
//            [self endHold];
//        }
//        //
//    }];

    [self startRecordingVideo];
    
}

- (void)endHold {
    if([self.recording boolValue]){
        self.recordingIndicator.alpha = 0.0;
        
        [self.view bringSubviewToFront:self.cameraView];
//        [self.view bringSubviewToFront:self.recordButton];
        
        [UIView animateWithDuration:0.2 animations:^{
            [self.view setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2 + recordButtonWidth/2)];
            [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2)];
            [self showCameraAccessories:YES];
        }];
        
        [self.indicatorText setText:NSLocalizedString(@"RECORD_TIP", @"")];
        [self.indicator removeFromSuperview];
        // Do Whatever You want on End of Gesture
        self.recording = [NSNumber numberWithBool:NO];
        
        if(self.flash){
            [self switchFlashMode:nil];
        }

        [self stopRecordingVideo];
    }
}

- (void) startRecordingVideo {
    if(!self.session.outputs.count)
        return;
    
    //    AVCaptureMovieFileOutput *aMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    //Create temporary URL to record to
    NSString *randomString = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), randomString];
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
        
        [self.currentRecordingURLs addObject:outputFileURL];
        
        if (![self.recording boolValue]) {
            if ([self.currentRecordingURLs count] > 1) {
                [[YAAssetsCreator sharedCreator] createVideoFromSequenceOfURLs:self.currentRecordingURLs addToGroup:[YAUser currentUser].currentGroup];
            } else {
                [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:outputFileURL addToGroup:[YAUser currentUser].currentGroup];
            }
        }
    } else {
        [YAUtils showNotification:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] type:YANotificationTypeError];
    }
    
}

- (void)switchCamera:(id)sender { //switch cameras front and rear camerashiiegor@gmail.com
    if(self.openSettingsButton)
        return;
    
    [self.cameraView addSubview:self.loader];
    
    self.loaderTimer = [NSTimer scheduledTimerWithTimeInterval: 0.025
                                                        target: self
                                                      selector:@selector(loaderTick:)
                                                      userInfo: nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.loaderTimer forMode:NSRunLoopCommonModes];
    [self loaderTick:nil];

    if([self.recording boolValue]){
        [self stopRecordingVideo];
    }
    
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
    if ([[self session] canAddInput:videoDeviceInput]) {
        [[self session] addInput:videoDeviceInput];
        [self setVideoInput:videoDeviceInput];
    }
    else
    {
        [[self session] addInput:[self videoInput]];
    }
    
    [[self session] commitConfiguration];
    
//    [UIView transitionWithView:self.cameraView
//                      duration:0.5
//                       options:UIViewAnimationOptionTransitionFlipFromRight|UIViewAnimationOptionCurveEaseInOut
//                    animations:^{
//                    }
//                    completion:^(BOOL finished) {
//                        if (finished) {
//                            //DO Stuff
//                        }
//                    }];
    
    if([self.recording boolValue]){
        [self performSelector:@selector(stopLoader) withObject:self afterDelay:.25];
        [self performSelector:@selector(startRecordingVideo) withObject:self afterDelay:.25];
    }
    
    //    [self.session beginConfiguration];
    //    [self.session commitConfiguration];
    
}

- (void)loaderTick:(NSTimer *)timer {
    dispatch_async(dispatch_get_main_queue(), ^{
        //Your main thread code goes in here
        for(UIView *v in self.loaderTiles){
            UIColor *p = PRIMARY_COLOR;
            p = [p colorWithAlphaComponent:(arc4random() % 128 / 256.0)];
            //            CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
            //            CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
            //            CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
            //            UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
            //
            [v setBackgroundColor:p];
        }
        
    });
    //    NSLog(@"loader tick!");
}

- (void)stopLoader {
    [self.loader removeFromSuperview];
    [self.loaderTimer invalidate];
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
    
    DLog(@"switching flash mode");
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
                DLog(@"error: %@", error);
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
    if(self.flash){
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

- (void)openGroupOptions:(id)sender {
    [self.delegate openGroupOptions];
}

#pragma mark -

- (void)updateCurrentGroupName {
    [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
}

- (void)updateUviewedViedeosBadge {
    self.unviewedVideosBadge.hidden = ![[YAUser currentUser] hasUnviewedVideosInGroups];
}

#pragma mark Group Notifications
- (void)groupDidRefresh:(NSNotification*)notification {
    [self updateUviewedViedeosBadge];
}

- (void)groupDidChange:(NSNotification*)notification {
    [self updateCurrentGroupName];
}

#pragma mark Settings
- (void)addOpenSettingsButton {
    if(!self.openSettingsButton) {
        CGRect r = self.cameraView.bounds;
        r.size.height /= 2;
        r.size.width *= .6;
        r.origin.x = (self.view.frame.size.width - r.size.width)/2;
//        r.origin.y = 0;
        
        self.openSettingsButton = [[UIButton alloc] initWithFrame:r];
        [self.openSettingsButton setTitle:NSLocalizedString(@"Enable Camera", @"") forState:UIControlStateNormal];
        [self.openSettingsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.openSettingsButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:24];
        [self.openSettingsButton addTarget:self action:@selector(openSettings:) forControlEvents:UIControlEventTouchUpInside];
        [self.openSettingsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self.openSettingsButton.titleLabel setNumberOfLines:0];
        self.openSettingsButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.cameraView addSubview:self.openSettingsButton];
    }
}

- (void)removeOpenSettingsButton {
    if(self.openSettingsButton) {
        [self.openSettingsButton removeFromSuperview];
        self.openSettingsButton = nil;
    }
}

- (void)openSettings:(id)sender {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:url];
}

@end
