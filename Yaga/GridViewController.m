//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GridViewController.h"
#import "UIImage+Resize.h"
#import "UIImage+Colors.h"
#import "NSString+File.h"
#import "TileCell.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "OverlayViewController.h"
#import "YagaNavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import "CreateViewController.h"
#import "SplashViewController.h"
#import "AddMembersViewController.h"
#import "ElevatorView.h"
#import "GroupListCell.h"

//Swift headers
#import "Yaga-Swift.h"

@interface GridViewController ()
@end

@implementation GridViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //    [[CNetworking currentUser] logout];
    //if([[CNetworking currentUser] loggedIn]){
    if ([[NetworkManager sharedManager] userIsLoggedIn]) {
        [self setupView];
    }
}

- (void)logout {
    [[CNetworking currentUser] logout];
    
    YagaNavigationController *vc = [[YagaNavigationController alloc] init];
    [vc setViewControllers:@[[[SplashViewController alloc] init]]];
    
    [self closeElevator];
    
    [self presentViewController:vc animated:NO completion:^{
        //
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if([[CNetworking currentUser] loggedIn]){
        if(![self.appeared boolValue]){
            self.appeared = [NSNumber numberWithBool:YES];
            if(![self.setup boolValue]){
                [self setupView];
            } else {
                [self.gridTiles reloadData];
            }
        }
    } else {
        NSLog(@"poop. not logged in.");
//        YagaNavigationController *vc = [[YagaNavigationController alloc] init];
//        [vc setViewControllers:@[[[SplashViewController alloc] init]]];
//        
//        [self presentViewController:vc animated:NO completion:^{
//            //
//        }];
        [self performSegueWithIdentifier:@"SplashScreen" sender:self];
    }
}

- (void)printMessage:(NSString *)message {
    NSLog(@"%@ -- %lu", message, [[[CNetworking currentUser] groupInfo] indexOfObject:self.groupInfo]);
}

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    NSLog(@"view did load? %lu", [[[CNetworking currentUser] groupInfo] indexOfObject:self.groupInfo]);
//
//    if([PFUser currentUser]){
//    }
//}

- (void)setupView {
    
    self.setup = [NSNumber numberWithBool:YES];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [Crashlytics setUserIdentifier:(NSString *) [[CNetworking currentUser] userDataForKey:nUsername]];
    
    [self initOverlay];
    [self initElevator];
    [self initLoader];
    [self initGridView];
    [self initCameraView];
    [self initCamera:^{
        [self setupGroups];
    }];
    
    [self initBall];
    
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
    
    
    //    [self initFirebase];
    // look at afterCameraInit to see what happens after the camera gets initialized. eg initFirebase.
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)initCameraView {
    self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT / 2)];
    //    self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.cameraView setBackgroundColor:PRIMARY_COLOR];
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
    
    //    self.cameraView.layer.shadowColor = [[UIColor redColor] CGColor];
    //    self.cameraView.layer.shadowRadius = 10.0f;
    //    self.cameraView.layer.shadowOpacity = 1;
    //    self.cameraView.layer.shadowOffset = CGSizeZero;
    
    
}

- (void)initCamera:(void (^)())block {
    
    NSLog(@"init camera");
    
    self.session = [[AVCaptureSession alloc] init];
    //    self.session.sessionPreset = AVCaptureSessionPreset
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
    });
}

- (void)afterCameraInit {
    [self setupGroups];
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
    NSLog(@"%ld", recognizer.state);
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

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    NSLog(@"anyone here?");
    
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
        
        [self uploadData:videoData withType:@"video" withOutputURL:outputFileURL];
    } else {
        NSLog(@"wtf is going on");
    }
    
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
            [self.view bringSubviewToFront:self.switchGroups];
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

- (void)initGridView {
    self.gridView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    //    [self.gridView setBackgroundColor:[UIColor yellowColor]];
    //    [self.gridView setBackgroundColor:[UIColor whiteColor]];
    
    [self initGridTiles];
    //    [self initBall];
    
    [self.view addSubview:self.gridView];
}

- (void) initBall {
    
    CGFloat gutter = 96, height = 42;
    CGFloat bottom = 28;
    self.switchGroups = [[UIButton alloc] initWithFrame:CGRectMake(gutter, self.cameraView.frame.size.height - height, self.cameraView.frame.size.width - gutter*2, height)];
    //    [self.groupButton setTitle:@"LindenFest 2014" forState:UIControlStateNormal];
    [self.switchGroups.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:16]];
    [self.switchGroups addTarget:self action:@selector(tappedBall) forControlEvents:UIControlEventTouchUpInside];
    [self.switchGroups setTitle:@"Switch Groups" forState:UIControlStateNormal];
    self.switchGroups.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.switchGroups.layer.shadowRadius = 1.0f;
    self.switchGroups.layer.shadowOpacity = 1.0;
    self.switchGroups.layer.shadowOffset = CGSizeZero;
    
    [self.cameraAccessories addObject:self.switchGroups];
    
    //    [self.switchGroups setBackgroundColor:PRIMARY_COLOR];
    //    self.switchGroups.layer.cornerRadius = height/2;
    //    self.switchGroups.clipsToBounds = YES;
    //    self.switchGroups.layer.borderWidth = 1.0f;
    //    self.switchGroups.layer.borderColor = [[UIColor blackColor] CGColor];
    [self.cameraView addSubview:self.switchGroups];
}

- (void) initElevator {
    
    self.elevator = [[ElevatorView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    
    //    [self.elevator setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:0.8]];
    
    self.elevator.groupsList = [[GroupListTableView alloc] initWithFrame:CGRectMake(0, ELEVATOR_MARGIN + 2, VIEW_WIDTH, VIEW_HEIGHT - ELEVATOR_MARGIN*2 - 84)];
    
    [self.elevator.groupsList setScrollEnabled:YES];
    [self.elevator.groupsList setRowHeight:96];
    //    [self.elevator.groupsList setSeparatorColor:PRIMARY_COLOR];
    [self.elevator.groupsList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.elevator.groupsList setBackgroundColor:[UIColor clearColor]];
    [self.elevator.groupsList setUserInteractionEnabled:YES];
    [self.elevator.groupsList setContentInset:UIEdgeInsetsMake(44, 0, 0, 0)];
    [self.elevator.groupsList registerClass:[GroupListCell class] forCellReuseIdentifier:@"ElevatorCell"];
    
    self.elevator.groupsList.delegate = self;
    self.elevator.groupsList.dataSource = self;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeElevator)];
    tap.delegate = self;
    [self.elevator.tapOut addGestureRecognizer:tap];
    
    [self.elevator addSubview:self.elevator.groupsList];
    
    self.elevator.border = [[UIView alloc] initWithFrame:CGRectMake(0, self.elevator.groupsList.frame.size.height + self.elevator.groupsList.frame.origin.y, self.elevator.frame.size.width, 0.5)];
    [self.elevator.border setBackgroundColor:[UIColor colorWithWhite:0.80 alpha:1.0]];
    [self.elevator addSubview:self.elevator.border];
    
    
    UIButton *logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 600, 200, 40)];
    [logoutButton setBackgroundColor:[UIColor greenColor]];
    [logoutButton setTitle:@"Reload Groups" forState:UIControlStateNormal];
    [logoutButton.titleLabel setTextColor:[UIColor redColor]];
    [logoutButton addTarget:self action:@selector(reloadGroups) forControlEvents:UIControlEventTouchUpInside];
    
    self.elevator.createGroup = [[UIButton alloc] initWithFrame:
                                 CGRectMake(44,
                                            self.elevator.groupsList.frame.size.height + self.elevator.groupsList.frame.origin.y,
                                            VIEW_WIDTH - 44,
                                            VIEW_HEIGHT - self.elevator.groupsList.frame.size.height - ELEVATOR_MARGIN*2 - 2 - self.elevator.border.frame.size.height)
                                 ];
    [self.elevator addSubview:self.elevator.createGroup];
    [self.elevator.createGroup setTitle:@"Create Group  〉" forState:UIControlStateNormal];
    [self.elevator.createGroup.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
    [self.elevator.createGroup setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self.elevator.createGroup setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
    [self.elevator.createGroup addTarget:self action:@selector(createGroup) forControlEvents:UIControlEventTouchUpInside];
    //    [self.elevator addSubview:logoutButton];
    
    
    
    [self.view addSubview:self.elevator];
    //    [self.view sendSubviewToBack:self.elevatorMenu];
    
    [self.elevator.groupsList reloadData];
    
    [self.elevator setAlpha:0.0];
}

- (void)reloadGroups {
    [[CNetworking currentUser] myCrewsWithCompletion:^{
        NSLog(@"completed?!");
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configureGroupInfo: [[[CNetworking currentUser] groupInfo] objectAtIndex:indexPath.row]];
    [[CNetworking currentUser] saveUserData:[NSNumber numberWithInteger:indexPath.row] forKey:nCurrentGroup];
    [self closeElevator];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSMutableArray *groupInfo = [[CNetworking currentUser] groupInfo];
    
    NSLog(@"number of rows: %lu", [groupInfo count]);
    return [groupInfo count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ElevatorCell";
    GroupListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    GroupInfo *groupInfo = [[[CNetworking currentUser] groupInfo] objectAtIndex:indexPath.row];
    [cell.title setText:groupInfo.name];
    [cell.subtitle setText:@"rjvir, kyle, and b9speed"];
    
    [cell.icon setTag:indexPath.row];
    [cell.icon addTarget:self action:@selector(groupSettings:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (void)groupSettings:(UIButton *)sender {
    NSInteger index = sender.tag;
    
    GroupInfo *groupInfo = [[[CNetworking currentUser] groupInfo] objectAtIndex:index];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:groupInfo.name delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Edit Title", @"Edit Members", @"Mute Group", @"Leave Group", nil];
    
    [actionSheet showInView:self.view];
}

- (void)createGroup {
    YagaNavigationController *vc = [[YagaNavigationController alloc] init];
    [vc setViewControllers:@[[[AddMembersViewController alloc] init]]];
    
    [self presentViewController:vc animated:NO completion:^{
        //
    }];
}

- (void) tappedBall {
    NSLog(@"tappedBall");
    
    if(![self.scrolling boolValue]){
        if(self.gridTiles.contentOffset.y > 0){
            NSLog(@"wat");
            //            [self.gridTiles setContentOffset:CGPointZero animated:YES];
        } else {
            [self toggleElevator];
        }
    } else {
        NSLog(@"wat 2");
    }
}

- (void)toggleElevator {
    NSLog(@"toggle elevator");
    if([self.elevatorOpen boolValue]){
        [self closeElevator];
    } else {
        [self openElevator];
    }
}

- (void) openElevator {
    
    //    [self.elevatorMenu reloadData];
    [self.elevator setAlpha:0.0];
    [self.elevator setTransform:CGAffineTransformMakeScale(0.75, 0.75)];
    [self.view bringSubviewToFront:self.elevator];
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        //
        [self.cameraView setFrame:CGRectMake(0, -(VIEW_HEIGHT/2)+ELEVATOR_MARGIN, self.cameraView.frame.size.width, self.cameraView.frame.size.height)];
        CGRect ballFrame = self.switchGroups.frame;
        ballFrame.origin.y = self.cameraView.frame.origin.y + self.cameraView.frame.size.height - ballFrame.size.height;
        [self.switchGroups setFrame:ballFrame];
        
        CGRect frame = self.gridTiles.frame;
        frame.origin.y += VIEW_HEIGHT/2 - ELEVATOR_MARGIN;
        [self.gridTiles setFrame:frame];
        
        for(UIView *view in self.cameraAccessories){
            [view setAlpha:0.0];
        }
        
        [self.elevator setTransform:CGAffineTransformIdentity];
        [self.elevator setAlpha:1.0];
        
    } completion:^(BOOL finished) {
        self.elevatorOpen = [NSNumber numberWithBool:YES];
    }];
    
}

- (void) closeElevator {
    
    NSLog(@"test");
    
    [self.elevator setTransform:CGAffineTransformIdentity];
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        //
        [self.cameraView setFrame:CGRectMake(0, 0, self.cameraView.frame.size.width, self.cameraView.frame.size.height)];
        CGRect ballFrame = self.switchGroups.frame;
        ballFrame.origin.y = self.cameraView.frame.origin.y + self.cameraView.frame.size.height - ballFrame.size.height;
        [self.switchGroups setFrame:ballFrame];
        
        CGRect frame = self.gridTiles.frame;
        frame.origin.y = 0;
        [self.gridTiles setFrame:frame];
        [self.elevator setAlpha:0.0];
        
        for(UIView *view in self.cameraAccessories){
            [view setAlpha:1.0];
        }
        
        [self.elevator setTransform:CGAffineTransformMakeScale(0.75, 0.75)];
        
    } completion:^(BOOL finished) {
        self.elevatorOpen = [NSNumber numberWithBool:NO];
        [self.view sendSubviewToBack:self.elevator];
    }];
}

- (void) initGridTiles {
    int tile_buffer = 0;
    
    CGFloat spacing = 1.0f;
    self.gridLayout= [[UICollectionViewFlowLayout alloc] init];
    [self.gridLayout setSectionInset:UIEdgeInsetsMake(VIEW_HEIGHT/2 + spacing, 0, 0, 0)];
    [self.gridLayout setMinimumInteritemSpacing:spacing];
    [self.gridLayout setMinimumLineSpacing:spacing];
    [self.gridLayout setItemSize:CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT)];
    
    self.swipeLayout= [[UICollectionViewFlowLayout alloc] init];
    CGFloat swipeSpacing = 0.0f;
    [self.swipeLayout setSectionInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    [self.swipeLayout setMinimumInteritemSpacing:swipeSpacing];
    [self.swipeLayout setMinimumLineSpacing:swipeSpacing];
    [self.swipeLayout setItemSize:CGSizeMake(VIEW_WIDTH, VIEW_HEIGHT)];
    [self.swipeLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    self.gridTiles = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT) collectionViewLayout:self.gridLayout];
    self.gridTiles.delegate = self;
    self.gridTiles.dataSource = self;
    [self.gridTiles registerClass:[TileCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.gridTiles setBackgroundColor:[UIColor whiteColor]];
    [self.gridTiles setAllowsMultipleSelection:NO];
    //    [self.gridTiles setBounces:NO];
    [self.gridView addSubview:self.gridTiles];
    
    self.pull = [[UIRefreshControl alloc] init];
    [self.pull setTintColor:[UIColor whiteColor]];
    [self.pull addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    [self.gridTiles addSubview:self.pull];
    
    CGFloat size = 48;
    self.loader = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.gridTiles.frame.size.width - size)/2, (self.gridTiles.frame.size.height - size)/2, size, size)];
    [self.loader setTintColor:[UIColor whiteColor]];
    [self.loader setHidesWhenStopped:YES];
    [self.loader setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.gridTiles addSubview:self.loader];
    [self.loader startAnimating];
    
}

- (void) initLoader {
    UIView *loader = [[UIView alloc] initWithFrame:self.gridTiles.frame];
    [self.gridView insertSubview:loader belowSubview:self.gridTiles];
}

- (void) initOverlay {
    self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.overlay setBackgroundColor:[UIColor blackColor]];
    [self.overlay setAlpha:0.0];
    
    [self.view addSubview:self.overlay];
}

- (void)configureGroupInfo:(GroupInfo *)groupInfo {
    NSLog(@"configure group info 2");
    
    self.groupInfo = groupInfo;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        
        //Your code goes in here
        //        NSLog(@"Main Thread Code");
        [self.switchGroups setTitle:[NSString stringWithFormat:@"%@ · %@", self.groupInfo.name, @"Switch"] forState:UIControlStateNormal];
        // set title here
        
    }];
}

- (void) deleteUid:(NSString *)uid {
//val TODO:
    
//    CNetworking *currentUser = [CNetworking currentUser];
//    [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"groups/%@/%@/%@", self.groupInfo.groupId, STREAM, uid]] removeValueWithCompletionBlock:^(NSError *error, Firebase *ref) {
//        
//        int index = 0;
//        int toDelete = -1;
//        for(FDataSnapshot *snapshot in [[CNetworking currentUser] gridDataForGroupId:self.groupInfo.groupId]){
//            if([snapshot.name isEqualToString:uid]){
//                toDelete = index;
//            }
//            index++;
//        };
//        if(toDelete > -1){
//            [[[CNetworking currentUser] gridDataForGroupId:self.groupInfo.groupId] removeObjectAtIndex:toDelete];
//        }
//        [self.gridTiles reloadData];
//    }];
}


- (void) triggerRemoteLoad:(NSString *)uid {
    
    //val TODO
//    [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
//        if(dataSnapshot.value != [NSNull null]){
//            NSError *error = nil;
//            
//            NSData *videoData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value[@"video"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
//            
//            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value[@"thumb"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
//            
//            if(videoData != nil && imageData != nil){
//                NSURL *movieURL = [uid movieUrl];
//                [videoData writeToURL:movieURL options:NSDataWritingAtomic error:&error];
//                
//                NSURL *imageURL = [uid imageUrl];
//                [imageData writeToURL:imageURL options:NSDataWritingAtomic error:&error];
//            }
//            
//            [self finishedLoading:uid];
//            
//        }
//    }];
}

- (void) finishedLoading:(NSString *)uid {
    for(TileCell *tile in [self.gridTiles visibleCells]){
        if([tile.uid isEqualToString:uid]){
            NSLog(@"finished loading?");
            [self.gridTiles reloadItemsAtIndexPaths:@[[self.gridTiles indexPathForCell:tile]]];
        }
    }
}

- (void) refreshTable {
    [self.pull endRefreshing];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[[CNetworking currentUser] gridDataForGroupId:self.groupInfo.groupId] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    //val TODO
    return cell;
//    id snapshot = [[[CNetworking currentUser] gridDataForGroupId:self.groupInfo.groupId] objectAtIndex:indexPath.row];
//    
////    if(self.selectedIndex){
////        [cell setVideoFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, VIEW_WIDTH, VIEW_HEIGHT/2)];
////    }
//
//    // if cell uid is not correct
//    if(![cell.uid isEqualToString:snapshot.name]){
//        
//        [cell setUid:snapshot.name];
//        [cell setUsername:snapshot.value[@"user"]];
//        [cell setSnapshot: snapshot];
//        
//        // set colors for loader tiles
//        //        NSArray *colors = (NSArray *) snapshot.value[@"colors"];
//        //
//        //        [cell setColors:colors];
//        
//        if([cell isLoaded]){
//            if([self.scrolling boolValue]){
//                //                [cell play];
//                [cell showImage];
//            } else {
//                [cell play:nil];
//                
//            }
//        } else {
//            [cell showLoader];
//            NSLog(@"whaaaat %lu, %@", indexPath.row, cell.uid);
//            [self triggerRemoteLoad:cell.uid];
//        }
//    }
//    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if([scrollView isEqual:self.gridTiles]){
        self.scrolling = [NSNumber numberWithBool:YES];
        CGFloat offset = 0;
        
        CGFloat gutter = 44;
        
        if(scrollView.contentOffset.y > VIEW_HEIGHT/2 - gutter){
            offset = VIEW_HEIGHT/2 - gutter;
        } else if(scrollView.contentOffset.y < 0){
            offset = 0;
        } else {
            offset = scrollView.contentOffset.y;
        }
        
        CGRect frame = self.cameraView.frame;
        frame.origin.y = 0 - offset;
        self.cameraView.frame = frame;
        
        frame = self.switchGroups.frame;
        frame.origin.y = self.cameraView.frame.size.height - self.switchGroups.frame.size.height - offset;
        self.switchGroups.frame = frame;
        
        if(self.selectedIndex){
            
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.scrolling = [NSNumber numberWithBool:NO];
    [self scrollingEnded];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(!decelerate){
        self.scrolling = [NSNumber numberWithBool:NO];
        [self performSelector:@selector(scrollingEnded) withObject:self afterDelay:0.1];
    }
}



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TileCell *selected = (TileCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if([selected.state isEqualToNumber:[NSNumber numberWithInt:PLAYING]]) {
        if(selected.player.rate == 1.0){
            
            if(!self.selectedIndex){
                self.selectedIndex = indexPath;
                
                [collectionView setCollectionViewLayout:self.swipeLayout animated:YES completion:^(BOOL finished) {
                }];
                for(TileCell *cell in self.gridTiles.visibleCells){
                    [cell setVideoFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, self.swipeLayout.itemSize.width, self.swipeLayout.itemSize.height)];
                }
                
                [collectionView setPagingEnabled:YES];
                [self.cameraView removeFromSuperview];
            } else {
                self.selectedIndex = nil;
                [collectionView setCollectionViewLayout:self.gridLayout animated:YES completion:^(BOOL finished) {
                    //
                }];
                for(TileCell *cell in self.gridTiles.visibleCells){
                    [cell setVideoFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, self.gridLayout.itemSize.width, self.gridLayout.itemSize.height)];
                    if([cell.state isEqualToNumber:[NSNumber numberWithInt:LOADED]]){
                        [cell play:^{
                            
                        }];
                    }
                }
                
                [collectionView setPagingEnabled:NO];
                [self.view addSubview:self.cameraView];

            }
//            [self presentOverlay:selected];
        } else {
            [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
    } else {
        NSLog(@"state: %@", selected.state);
        //        [collectionView reloadItemsAtIndexPaths:@[[collectionView indexPathForCell:selected]]];
    }
    
//    NSLog(@"subviews: %lu", [[self.gridView subviews] count]);
    
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)presentOverlay:(TileCell *)tile {
    tile.frame = CGRectMake(tile.frame.origin.x, tile.frame.origin.y - self.gridTiles.contentOffset.y + TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT);
    [self.view bringSubviewToFront:self.overlay];
    [self.overlay addSubview:tile];
    
    [tile.loader setAlpha:0.0];
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        [self.overlay setAlpha:1.0];
        [tile.player setVolume:1.0];
        //        [tile setVideoFrame:CGRectMake(0, VIEW_HEIGHT/4, VIEW_WIDTH, VIEW_HEIGHT/2)];
        [tile setVideoFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    } completion:^(BOOL finished) {
        //
        OverlayViewController *overlay = [[OverlayViewController alloc] init];
        [overlay setTile:tile];
        [overlay setPreviousViewController:self];
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:overlay animated:NO completion:^{
            
        }];
    }];
}

- (void) collapse:(TileCell *)tile speed:(CGFloat)speed {
    
    tile.frame = CGRectMake(0, self.gridTiles.contentOffset.y, VIEW_WIDTH, VIEW_HEIGHT/2);
    [self.gridTiles addSubview:tile];
    [self.overlay setAlpha:0.0];
    
    [tile.loader setAlpha:1.0];
    
    //    [self.gridTiles addSubview:self.overlay];
    [UIView animateWithDuration:speed delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:0.7 options:0 animations:^{
        NSIndexPath *ip = [self.gridTiles indexPathForCell:tile];
        [tile setVideoFrame:[self.gridTiles layoutAttributesForItemAtIndexPath:ip].frame];
        //
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL {
    //val TODO:
    
//    // measure size of data
//    NSLog(@"%@ size: %lu", type, (unsigned long)[data length]);
//    
//    // set up data object
//    NSString *videoData = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
////    Firebase *dataObject = [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@", MEDIA]] childByAutoId];
////    NSString *dataPath = dataObject.name;
//    
//    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:outputURL options:nil];
//    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
//    [imageGenerator setAppliesPreferredTrackTransform:YES];
//    //    UIImage* image = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
//    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMake(0,1) actualTime:nil error:nil];
//    
//    UIImage *image = [[UIImage imageWithCGImage:imageRef] imageScaledToFitSize:CGSizeMake(VIEW_WIDTH, VIEW_HEIGHT/2)];
//    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
//    //NSString *imageString = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
//    
//    NSArray *colors = [image getColors];
//    
//    //    for(NSString *color in colors){
//    //        NSLog(@"color: %@", color);
//    //    }
//    
////    [dataObject setValue:@{@"video":videoData, @"thumb":imageString} withCompletionBlock:^(NSError *error, Firebase *ref) {
////    }];
//    
//    //    NSMutableDictionary *clique = (NSMutableDictionary *)[PFUser currentUser][@"clique"];
//    //    [clique setObject:@1 forKeyedSubscript:[PFUser currentUser][@"phoneHash"]];
//    
//    //    for(NSString *hash in clique){
//    //        NSLog(@"hash: %@", hash);
//    //        NSString *escapedHash = [hash stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
//    //        NSString *path = [NSString stringWithFormat:@"%@/%@/%@", STREAM, escapedHash, dataPath];
//    //        [[[[CNetworking currentUser] firebase] childByAppendingPath:path] setValue:@{@"type": type, @"user":(NSString *)[[CNetworking currentUser] userDataForKey:@"username"], @"colors":colors}];
//    //    }
//    
//    NSLog(@"group id: %@", self.groupInfo.groupId);
//    
//    NSFileManager * fm = [[NSFileManager alloc] init];
//    NSError *err = nil;
//    [fm moveItemAtURL:outputURL toURL:[[self tempFilename] movieUrl] error:&err];
//    [imageData writeToURL:[[self tempFilename] imageUrl] options:NSDataWritingAtomic error:&err];
//    
//    if(err){
//        NSLog(@"error: %@", err);
//    }
//    
}

- (NSString*)tempFilename {
    return [NSString stringWithFormat:@"file %f", [[NSDate date] timeIntervalSince1970]];
}

- (void)scrollingEnded {
    if(![self.scrolling boolValue]){
        //        NSLog(@"visible cells count: %lu", [[self.gridTiles visibleCells] count]);
        
        NSLog(@"scrolling ended count: %lu", [[self.gridTiles visibleCells] count]);
        
        for(TileCell *cell in [self.gridTiles visibleCells]){
            
            if([cell.state isEqualToNumber:[NSNumber numberWithInt: LOADED]]){
                [cell play:^{
                    if(self.selectedIndex){
                        [cell setSelected:YES];
//                        [cell.player setVolume:0.0];
//                        [((TileCell *)[self.gridTiles cellForItemAtIndexPath:self.selectedIndex]).player setVolume:0.0];
//                        self.selectedIndex = [self.gridTiles indexPathForCell:cell];
//                        [self.gridTiles selectItemAtIndexPath:[self.gridTiles indexPathForCell:cell] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    }
                }];
            }
        }
    }
}

- (void)conserveTiles {
    
    for(TileCell *tile in [self.gridTiles visibleCells]){
        if([tile.state isEqualToNumber:[NSNumber numberWithInt: PLAYING]]){
            //            [tile showImage];
            tile.player = nil;
            [tile.player removeObservers];
        }
    }
}

- (void)setupGroups {
    
    NSLog(@"setup groups");
    
    CNetworking *currentUser = [CNetworking currentUser];
    
    //    [currentUser myCrewsWithCompletion:^{
    //        //
    NSLog(@"groupinfo count? %lu", [[currentUser groupInfo] count]);
    
    
    int cur = 0;
    if([currentUser userDataForKey:nCurrentGroup]){
        NSNumber *currentIndex = (NSNumber *)[currentUser userDataForKey:nCurrentGroup];
        cur = [currentIndex intValue];
    }
    [self configureGroupInfo:[currentUser.groupInfo objectAtIndex:cur]];
    [self.gridTiles reloadData];
    //    }];
    
    //    NSString *userid = (NSString *)[currentUser userDataForKey:nUserId];
    //
    //    NSString *path = [NSString stringWithFormat:@"users/%@/groups", userid];
    //
    //    NSLog(@"path: %@", path);
    //
    //    // fetching all of a users groups
    //    [[currentUser.firebase childByAppendingPath:path] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    //
    //        currentUser.groupInfo = [[NSMutableArray alloc] init];
    //
    //        // iterate through returned groups
    //        for(FDataSnapshot *child in snapshot.children){
    //
    //            // fetch group meta data
    //            NSString *dataPath = [NSString stringWithFormat:@"groups/%@/data", child.name];
    ////            NSLog(@"datapath: %@", dataPath);
    //
    //            [[currentUser.firebase childByAppendingPath:dataPath] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
    //
    //                // saving group data
    //                GroupInfo *info = [[GroupInfo alloc] init];
    //                info.name = dataSnapshot.value[@"name"];
    //                info.groupId = child.name;
    //                info.members = [[NSMutableArray alloc] init];
    //
    //                for(NSString *member in dataSnapshot.value[@"members"]){
    //                    [info.members addObject:member];
    //                }
    //
    //                [currentUser.groupInfo insertObject:info atIndex:0];
    //
    //                if([currentUser.groupInfo count] == snapshot.childrenCount){
    //                    NSLog(@"about to setup pages");
    //                    [self.gridTiles reloadData];
    //                    [self configureGroupInfo:[currentUser.groupInfo objectAtIndex:0]];
    ////                    [self initGridTiles];
    //
    ////                    [self setGroupInfo:[currentUser.groupInfo objectAtIndex:0]];
    //
    //
    //                }
    //            }];
    //        }
    //    }];
    
}


- (void)willResignActive {
    //    [self removeAudioInput];
    // remove microphone
    
}

- (void)didBecomeActive {
    //    [self addAudioInput];
    // add microphone
}

- (void)didEnterBackground {
    //    NSLog(@"did enter background");
    //    [self.view setAlpha:0.0];
    
    if([self.flash boolValue] && [[self.videoInput device] position] == AVCaptureDevicePositionFront){
        [self switchFlashMode:nil];
    }
    [self closeCamera];
    
    [self conserveTiles];
}

- (void)willEnterForeground {
    //    NSLog(@"will enter foreground");
    //    [self.view setAlpha:1.0];
    [self initCamera:^{
        [self.gridTiles reloadData];
    }];
    
    //    for(TileCell *tile in [self.gridTiles visibleCells]){
    //        if([tile.state isEqualToNumber:[NSNumber numberWithInt: PLAYING]] || [tile.state  isEqualToNumber:[NSNumber numberWithInt:  LOADED]]){
    //            [tile play];
    //        }
    //    }
}

- (void)removeFromSuperview {
    //    [super removeFromSuperview];
    for(TileCell *tile in [self.gridTiles visibleCells]){
        tile.player = nil;
        [tile.player removeObservers];
    }
}

- (void)dismiss {
    //    [self dismissViewControllerAnimated:YES completion:^{
    //        //
    //    }];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"memory warning in group controller? %lu", [[[CNetworking currentUser] groupInfo] indexOfObject:self.groupInfo]);
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
