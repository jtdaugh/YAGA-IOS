//
//  YACameraViewController.m
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAInviteCameraViewController.h"

#import "YAUser.h"
#import "YAUtils.h"
#import "YAAssetsCreator.h"

#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>

@interface YAInviteCameraViewController () <YACameraManagerDelegate>
@property (strong, nonatomic) UIView *indicator;
@property (strong, nonatomic) UILabel *indicatorText;
@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSNumber *recording;
@property (strong, nonatomic) NSNumber *FrontCamera;
@property (assign, nonatomic) BOOL flash;

@property (strong, nonatomic) NSNumber *previousBrightness;

@property (strong, nonatomic) NSMutableArray *cameraAccessories;
@property (strong, nonatomic) UIButton *switchCameraButton;

@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *recordButton;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizerCamera;
@property (nonatomic) BOOL audioInputAdded;

@property (nonatomic, strong) CTCallCenter *callCenter;
@end

@implementation YAInviteCameraViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.cameraView = [[YACameraView alloc] initWithFrame:self.view.bounds];
    [self.cameraView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:self.cameraView];
    [self.cameraView setUserInteractionEnabled:YES];
    self.cameraView.autoresizingMask = UIViewAutoresizingNone;
    
    self.cameraAccessories = [@[] mutableCopy];
    
    self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.white setBackgroundColor:[UIColor whiteColor]];
    [self.white setAlpha:0.8];
    
    [self.white setUserInteractionEnabled:YES];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFlash:)];
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
    [flashButton addTarget:self action:@selector(toggleFlash:) forControlEvents:UIControlEventTouchUpInside];
    [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.flashButton = flashButton;
    [self.cameraAccessories addObject:self.flashButton];
    [self.cameraView addSubview:self.flashButton];
    
    //record button
    self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0 - recordButtonWidth/2.0, self.view.frame.size.height - (recordButtonWidth+10), recordButtonWidth, recordButtonWidth)];
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
    
    [self enableRecording:YES];
    
    //stop recording on incoming call
    void (^block)(CTCall*) = ^(CTCall* call) {
        DLog(@"Phone call received, state:%@. Stopping recording..", call.callState);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endHold];
        });
    };
    self.callCenter = [[CTCallCenter alloc] init];
    self.callCenter.callEventHandler = block;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [YACameraManager sharedManager].delegate = self;
    [[YACameraManager sharedManager] forceFrontFacingCamera];
    [[YACameraManager sharedManager] setCameraView:self.cameraView];
    
    CGFloat size = 44;
    self.view.frame = self.smallCameraFrame;
    self.cameraView.frame = self.view.bounds;

    self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    self.switchCameraButton.frame = CGRectMake(self.cameraView.frame.size.width-size- 10, 10, size, size);
    self.flashButton.frame = CGRectMake(10, 10, size, size);
    self.recordButton.frame = CGRectMake(self.view.frame.size.width/2.0 - recordButtonWidth/2.0, self.view.frame.size.height - (recordButtonWidth+10), recordButtonWidth, recordButtonWidth);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
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
    //    [UIView animateWithDuration:0.2 animations:^{
    //        self.recordButton.transform = enable ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0, 0);
    //    }];
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
    [self.delegate beganHold];
    DLog(@"starting hold");
    
    //    //We're starting to shoot so add audio
    //    if (!self.audioInputAdded) {
    //        [self.session beginConfiguration];
    //        [self.session addInput:self.audioInput];
    //        self.audioInputAdded = YES;
    //        [self.session commitConfiguration];
    //    }
    self.recording = [NSNumber numberWithBool:YES];
    self.indicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT / 32.f)];
    [self.indicator setBackgroundColor:PRIMARY_COLOR];
    [self.indicator setUserInteractionEnabled:NO];
    [self.indicatorText setText:@"Recording..."];
    [self.view addSubview:self.indicator];
    
    [self.view bringSubviewToFront:self.white];
    [self.view bringSubviewToFront:self.indicator];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self showCameraAccessories:0];
        [self.view setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    } completion:^(BOOL finished) {
        
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

- (void)endHold {
    [self.delegate endedHold];
    if([self.recording boolValue]){
        
        [self.view bringSubviewToFront:self.cameraView];
        //        [self.view bringSubviewToFront:self.recordButton];
        
        [UIView animateWithDuration:0.2 animations:^{
            [self.view setFrame:self.smallCameraFrame];
            [self.cameraView setFrame:self.view.bounds];
            [self showCameraAccessories:YES];
        }];
        
        [self.indicatorText setText:NSLocalizedString(@"RECORD_TIP", @"")];
        [self.indicator removeFromSuperview];
        // Do Whatever You want on End of Gesture
        self.recording = [NSNumber numberWithBool:NO];
        
        if(self.flash){
            [self setFlashMode:NO];
        }
        
        [self stopRecordingVideo];
    }
}
- (void) startRecordingVideo {
    [[YACameraManager sharedManager] startRecording];
}

- (void) stopRecordingVideo {
    __weak YAInviteCameraViewController *weakSelf = self;
    [[YACameraManager sharedManager] stopRecordingWithCompletion:^(NSURL *recordedURL) {
        [weakSelf.delegate finishedRecordingVideoToURL:recordedURL];
    }];
}


- (void)switchCamera:(id)sender {
    [self setFlashMode:NO];
    [[YACameraManager sharedManager] switchCamera];
}

- (YACameraView *)currentCameraView {
    return self.cameraView;
}

- (void)setFrontFacingFlash:(BOOL)showFlash {
    if(!showFlash) {
        // turn flash off
        if(self.previousBrightness){
            [[UIScreen mainScreen] setBrightness:[self.previousBrightness floatValue]];
        }
        [self.white removeFromSuperview];
    } else {
        // turn flash on
        self.previousBrightness = [NSNumber numberWithFloat: [[UIScreen mainScreen] brightness]];
        [[UIScreen mainScreen] setBrightness:1.0];
        [self.view addSubview:self.white];
        
        [self.view bringSubviewToFront:self.cameraView];
        [self showCameraAccessories:YES];
    }
}

- (void)toggleFlash:(id)sender {
    [self setFlashMode:!self.flash];
}

- (void)setFlashMode:(BOOL)flashOn {
    self.flash = flashOn;
    DLog(@"switching flash mode");
    [self configureFlashButton:flashOn];
    [[YACameraManager sharedManager] toggleFlash:flashOn];
}

- (void)configureFlashButton:(BOOL)flash {
    if(flash){
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOn"] forState:UIControlStateNormal];
    } else {
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    }
}

- (void)didEnterBackground {
    if(self.flash){
        [self setFlashMode:NO];
    }
}

- (void)showCameraAccessories:(BOOL)show {
    for(UIView *v in self.cameraAccessories){
        [v setAlpha:show ? 1 : 0];
        if(show)
            [self.view bringSubviewToFront:v];
    }
    
}

@end
