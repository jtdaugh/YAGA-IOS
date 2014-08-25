//
//  CameraViewController.m
//  Pic6
//
//  Created by Raj Vir on 8/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CameraViewController.h"
#import "GroupViewController.h"
#import "CreateGroupViewController.h"
#import <Parse/Parse.h>


@interface CameraViewController ()

@end

@implementation CameraViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
    [self setupGroups];
    
    [self.view setBackgroundColor:SECONDARY_COLOR];
    
}

- (void)setup {
    // Do any additional setup after loading the view.
    self.cameraAccessories = [[NSMutableArray alloc] init];
    NSError *error = nil;
    if(error){
        NSLog(@"error: %@", error);
    }
    
    [self initPlaque];
    [self initCameraView];
    [self initCamera:YES];
    
    NSLog(@"watup");
    
    UIButton *createGroup = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    [createGroup addTarget:self action:@selector(createGroup) forControlEvents:UIControlEventTouchUpInside];
    [createGroup.titleLabel setFont:[UIFont systemFontOfSize:30]];
    [createGroup setTitle:@"+" forState:UIControlStateNormal];
    [createGroup setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:createGroup];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

}

- (void)setupGroups {
    CNetworking *currentUser = [CNetworking currentUser];
    PFUser *pfUser = [PFUser currentUser];
    
    NSString *path = [NSString stringWithFormat:@"users/%@/groups", pfUser[@"phoneHash"]];
    
    NSLog(@"path: %@", path);
    
    // fetching all of a users groups
    [[currentUser.firebase childByAppendingPath:path] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        currentUser.groupInfo = [[NSMutableArray alloc] init];
        
        // iterate through returned groups
        for(FDataSnapshot *child in snapshot.children){
            
            NSLog(@"group id: %@", child.name);
            
            // fetch group meta data
            NSString *dataPath = [NSString stringWithFormat:@"groups/%@/data", child.name];
            [[currentUser.firebase childByAppendingPath:dataPath] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
                
                // saving group data
                GroupInfo *info = [[GroupInfo alloc] init];
                info.name = dataSnapshot.value[@"name"];
                info.groupId = child.name;
                
                [currentUser.groupInfo insertObject:info atIndex:0];
                
                if([currentUser.groupInfo count] == snapshot.childrenCount){
                    NSLog(@"about to setup pages");
                    [self setupPages];
                }
            }];
        }
    }];
}

- (void)setupPages {

    CNetworking *currentUser = [CNetworking currentUser];
    
    NSDictionary* options = @{ UIPageViewControllerOptionInterPageSpacingKey : [NSNumber numberWithFloat:16.0f] };
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:options];
    
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    self.pageViewController.view.frame = [self frameForContentController];
    
    GroupViewController *groupViewController = [[GroupViewController alloc] init];
    groupViewController.cameraViewController = self;
    //GroupInfo *info = (GroupInfo *)[[CNetworking currentUser] groupInfo][0];
    groupViewController.groupInfo = (GroupInfo *) [currentUser.groupInfo objectAtIndex:0];
    self.vcIndex = 0;
    NSArray *viewControllers = [NSArray arrayWithObject:groupViewController];
    
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
}

#pragma mark -
#pragma mark - UIPageViewControllerDelegate Method

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    CNetworking *currentUser = [CNetworking currentUser];
    
    if (self.vcIndex == 0)
    {
        return nil;
    }
    
    GroupViewController *groupViewController = [[GroupViewController alloc] init];
    groupViewController.cameraViewController = self;
    
    GroupInfo *groupInfo = [[currentUser groupInfo] objectAtIndex:self.vcIndex - 1];
    groupViewController.groupInfo = groupInfo;
    return groupViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    CNetworking *currentUser = [CNetworking currentUser];
    
    if (self.vcIndex == ([currentUser.groupInfo count] - 1))
    {
        return nil;
    }
    
    GroupViewController *groupViewController = [[GroupViewController alloc] init];
    groupViewController.cameraViewController = self;
    
    GroupInfo *groupInfo = [[currentUser groupInfo] objectAtIndex:self.vcIndex + 1];
    groupViewController.groupInfo = groupInfo;
    return groupViewController;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    for(GroupViewController *groupViewController in pendingViewControllers){
        groupViewController.scrolling = [NSNumber numberWithBool:YES];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    GroupViewController *groupViewController = [pageViewController.viewControllers objectAtIndex:0];

    groupViewController.scrolling = [NSNumber numberWithBool:NO];
    [groupViewController scrollingEnded];

    if(completed){
        CNetworking *currentUser = [CNetworking currentUser];
        self.vcIndex = [currentUser.groupInfo indexOfObject:groupViewController.groupInfo];
    }
    
    NSLog(@"previous view controllers count: %lu", [previousViewControllers count]);
    NSLog(@"view controllers count: %lu", [pageViewController.viewControllers count]);
}


#pragma mark -
#pragma mark - Camera Shit

- (void)afterCameraInit {
    //    if(![[CNetworking currentUser] firebase]){
    //    [self initFirebase];
    //    }
}

- (void)initPlaque {
    self.plaque = [[UIView alloc] init];
    [self.plaque setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    [self.plaque setBackgroundColor:SECONDARY_COLOR];
    
    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, TILE_WIDTH-16, 36)];
    [logo setText:APP_NAME]; // 🔥
    [logo setTextColor:[UIColor whiteColor]];
    [logo setFont:[UIFont fontWithName:BIG_FONT size:30]];
    //    [self.plaque addSubview:logo];
    
    UILabel *instructions = [[UILabel alloc] initWithFrame:CGRectMake(10, 30+8+4, TILE_WIDTH-16, 60)];
    [instructions setText:@"📹 Hold to record 👉"];
    [instructions setNumberOfLines:0];
    [instructions sizeToFit];
    [instructions setTextColor:[UIColor whiteColor]];
    [instructions setFont:[UIFont fontWithName:BIG_FONT size:13]];
    //    [self.cameraAccessories addObject:instructions];
    //    [self.plaque addSubview:instructions];
    
    self.switchButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH/2, TILE_HEIGHT/2, TILE_WIDTH/2, TILE_HEIGHT/2)];
    [self.switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    //    [self.switchButton setTitle:@"🔃" forState:UIControlStateNormal];
    //    [self.switchButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
    [self.switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.switchButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.cameraAccessories addObject:self.switchButton];
    [self.plaque addSubview:self.switchButton];
    
    UIButton *cliqueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT/2, TILE_WIDTH/2, TILE_HEIGHT/2)];
    [cliqueButton addTarget:self action:@selector(manageClique) forControlEvents:UIControlEventTouchUpInside];
    //    [cliqueButton setTitle:@"👥" forState:UIControlStateNormal]; //🔃
    //    [cliqueButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
    [cliqueButton setImage:[UIImage imageNamed:@"Clique"] forState:UIControlStateNormal];
    [cliqueButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.plaque addSubview:cliqueButton];
    
    self.flashButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH/2, 0, TILE_WIDTH/2, TILE_HEIGHT/2)];
    [self.flashButton addTarget:self action:@selector(switchFlashMode:) forControlEvents:UIControlEventTouchUpInside];
    [self.flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    [self.flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.cameraAccessories addObject:self.flashButton];
    [self.plaque addSubview:self.flashButton];
    
    [self.view addSubview:self.plaque];
}

- (void)hideContentController:(UIViewController *)content
{
    [content willMoveToParentViewController:nil];  // 1
    [content.view removeFromSuperview];            // 2
    [content removeFromParentViewController];      // 3
}

- (void)createGroup {
    NSLog(@"create group pressed");
    CreateGroupViewController *vc = [[CreateGroupViewController alloc] init];
    
//    [self customPresentViewController:vc];
//    [self displayContentController:vc];
    [self presentViewController:vc animated:YES completion:^{
        //
    }];
}

- (void)manageClique {
    NSLog(@"yoo");
}

- (CGRect) newViewStartFrame {
    return [self frameForContentController];
}

- (CGRect) oldViewEndFrame {
    return [self frameForContentController];
}

- (CGRect) frameForContentController {
    return CGRectMake(0, TILE_HEIGHT, TILE_WIDTH*2, VIEW_HEIGHT - TILE_HEIGHT);
}

- (void) switchCamera:(id)sender { //switch cameras front and rear cameras
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
            [self configureFlashButton:[NSNumber numberWithBool:NO]];
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

- (void) switchFlashMode:(id)sender {
    
    NSLog(@"switching flash mode");
    AVCaptureDevice *currentVideoDevice = [[self videoInput] device];
    
    if([currentVideoDevice position] == AVCaptureDevicePositionBack){
        // back camera
        [currentVideoDevice lockForConfiguration:nil];
        if([self.flash boolValue]){
            //turn flash off
            if([currentVideoDevice isTorchModeSupported:AVCaptureTorchModeOff]){
                [currentVideoDevice setTorchMode:AVCaptureTorchModeOff];
            }
            [self configureFlashButton:[NSNumber numberWithBool:NO]];
        } else {
            //turn flash on
            NSError *error = nil;
            if([currentVideoDevice isTorchModeSupported:AVCaptureTorchModeOn]){
                [currentVideoDevice setTorchModeOnWithLevel:0.8 error:&error];
            }
            if(error){
                NSLog(@"error: %@", error);
            }
            
            [self configureFlashButton:[NSNumber numberWithBool:YES]];
        }
        [currentVideoDevice unlockForConfiguration];
        
    } else if([currentVideoDevice position] == AVCaptureDevicePositionFront) {
        //front camera
        if([self.flash boolValue]){
            // turn flash off
            if(self.previousBrightness){
                [[UIScreen mainScreen] setBrightness:[self.previousBrightness floatValue]];
            }
            [self.white removeFromSuperview];
            [self configureFlashButton:[NSNumber numberWithBool:NO]];
        } else {
            // turn flash on
            self.previousBrightness = [NSNumber numberWithFloat: [[UIScreen mainScreen] brightness]];
            [[UIScreen mainScreen] setBrightness:1.0];
            [self.view addSubview:self.white];
            [self.view bringSubviewToFront:self.cameraView];
            [self configureFlashButton:[NSNumber numberWithBool:YES]];
        }
        
    }
}

- (void)configureFlashButton:(NSNumber *)flash {
    self.flash = flash;
    if([flash boolValue]){
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOn"] forState:UIControlStateNormal];
    } else {
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    }
}

- (void)initCameraView {
    self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(TILE_WIDTH, 0, TILE_WIDTH, TILE_HEIGHT)];
    //    self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.cameraView setBackgroundColor:PRIMARY_COLOR];
    [self.view addSubview:self.cameraView];
    
    [self.cameraView setUserInteractionEnabled:YES];
    
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
    
    self.instructions = [[UIView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT * 3 / 8, TILE_WIDTH, TILE_HEIGHT/4)];
    [self.instructions setAlpha:0.6];
    
    UILabel *instructionText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.instructions.frame.size.width, self.instructions.frame.size.height)];
    [instructionText setText:@"Hold to Record!"];
    [instructionText setFont:[UIFont fontWithName:BIG_FONT size:14]];
    [instructionText setTextAlignment:NSTextAlignmentCenter];
    [instructionText setTextColor:[UIColor whiteColor]];
    [instructionText setBackgroundColor:PRIMARY_COLOR];
    [instructionText sizeToFit];
    CGFloat newHeight = instructionText.frame.size.height * 1.2;
    CGFloat newWidth = instructionText.frame.size.width * 1.2;
    [instructionText setFrame:CGRectMake(.5 * (self.instructions.frame.size.width - newWidth), .5 * (self.instructions.frame.size.height - newHeight), newWidth, newHeight)];
    
    [self.instructions addSubview:instructionText];
    //    [self.instructions setAlpha:0.0];
    
    //    [self.cameraView addSubview:self.instructions];
    //    [self.cameraAccessories addObject:self.instructions];
    
    
}

- (void)initCameraButton {
    self.cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    [self.cameraButton setBackgroundColor:SECONDARY_COLOR];
    [self.cameraButton setImage:[UIImage imageNamed:@"Camera"] forState:UIControlStateNormal];
    [self.cameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.cameraButton addTarget:self action:@selector(cameraButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.cameraButton setTitle:@"Enable Camera" forState:UIControlStateNormal];
    
    [self.cameraButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:13]];
    
    // the space between the image and text
    CGFloat spacing = 6.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = self.cameraButton.imageView.frame.size;
    self.cameraButton.titleEdgeInsets = UIEdgeInsetsMake(
                                                         0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = self.cameraButton.titleLabel.frame.size;
    self.cameraButton.imageEdgeInsets = UIEdgeInsetsMake(
                                                         - (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
    
    [self.cameraView addSubview:self.cameraButton];
    
}

- (void)cameraButtonTapped {
    //    for(TileCell *cell in [self.gridTiles visibleCells]){
    //        if([cell.state isEqualToNumber:[NSNumber numberWithInt:PLAYING]]){
    //            [cell showLoader];
    //        }
    //    }
    
    [self.cameraButton removeFromSuperview];
    
    for(UIView *v in self.cameraAccessories){
        [v setAlpha:1.0];
    }
    
    //    [self setOnboarding:[NSNumber numberWithBool:NO]];
    //    NSLog(@"tapped");
}
- (void)checkDeviceAuthorizationStatus
{    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        if (granted)
        {
            //Granted access to mediaType
        }
        else
        {
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"AVCam!"
                                            message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    }];
}

- (void)initCamera:(BOOL)initial {
    
    NSLog(@"init camera");
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
    [(AVCaptureVideoPreviewLayer *)(self.cameraView.layer) setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //set still image output
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    //    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        
        NSError *error = nil;
        
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
        if(initial){
            [self afterCameraInit];
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
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self endHold];
    } else if (recognizer.state == UIGestureRecognizerStateBegan){
        [self startHold];
    }
}

- (void)startHold {
    
    NSLog(@"starting hold");
    
    self.recording = [NSNumber numberWithBool:YES];
    self.indicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, TILE_HEIGHT/4)];
    [self.indicator setBackgroundColor:[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.75]];
    [self.indicator setUserInteractionEnabled:NO];
    [self.cameraView addSubview:self.indicator];
    
    [UIView animateWithDuration:6.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.indicator setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT/4)];
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

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully)
    {
        //----- RECORDED SUCESSFULLY -----
        
        NSData *videoData = [NSData dataWithContentsOfURL:outputFileURL];
        
        GroupViewController *groupViewController = (GroupViewController *)[self.pageViewController.viewControllers objectAtIndex:0];
        
        [groupViewController uploadData:videoData withType:@"video" withOutputURL:outputFileURL];
    } else {
        NSLog(@"wtf is going on");
    }
    
}

- (void)didEnterBackground {
    if([self.flash boolValue] && [[self.videoInput device] position] == AVCaptureDevicePositionFront){
        [self switchFlashMode:nil];
    }
    [self closeCamera];

}

- (void)willResignActive {
    
}

- (void)willEnterForeground {
    [self initCamera:0];
}

- (void)didBecomeActive {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

@end
