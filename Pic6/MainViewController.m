//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MainViewController.h"
#import "UIImage+Resize.h"

#define NODE_NAME @"global"

@interface MainViewController ()
@property bool FrontCamera;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"yooo");
    
    UIView *plaque = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
    [logo setImage:[UIImage imageNamed:@"Logo"]];
    [plaque addSubview:logo];
    [self.view addSubview:plaque];
    
    [self initSwitchButton];
    [self initGridView];
    [self initFirebase];
    [self initCameraFrame];
    self.FrontCamera = 1;
    [self initCamera];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"test!");
}

- (void)initSwitchButton {
    UIButton *switchButton = [[UIButton alloc] initWithFrame:CGRectMake(640/4 - 60, 1168/8 - 60, 50, 50)];
    [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.view addSubview:switchButton];
}

- (void)initGridView {
    self.gridView = [[UIView alloc] initWithFrame:CGRectMake(0, 1136/8, 640/2, 1136/8 * 3)];

    self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, -1136/8, 640/2, 1136/2)];
    [self.overlay setBackgroundColor:[UIColor blackColor]];
    [self.overlay setAlpha:0.0];
    
//    UITapGestureRecognizer *tappedTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedTile:)];
//    [self.overlay addGestureRecognizer:tappedTile];

    
    [self.gridView addSubview:self.overlay];
    [self.view addSubview:self.gridView];
    self.gridData = [NSMutableArray array];
    self.gridTiles = [NSMutableArray array];
    self.players = [NSMutableDictionary dictionary];
    
}

- (void)insertGridTile:(FDataSnapshot *)snapshot {
//    [[self.gridTiles lastObject] removeFromSuperview];
    UIView *newGridTile = [[UIView alloc] initWithFrame:CGRectMake(640/4, -1136/8, 640/4, 1136/8)];
    FDataSnapshot *cellData = snapshot;
    
    NSMutableDictionary *tileData = [NSMutableDictionary dictionary];
    if([cellData.value[@"type"] isEqualToString:@"image"]){
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView setClipsToBounds:YES];
        
        [newGridTile addSubview:imageView];
        NSData *data = [[NSData alloc]initWithBase64EncodedString:cellData.value[@"data"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        [imageView setImage:[UIImage imageWithData:data]];
        
        [tileData setObject:imageView forKey:@"imageView"];
        
    } else if([cellData.value[@"type"] isEqualToString:@"video"]){
        NSLog(@"%@", cellData.name);
        
        NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), cellData.name];
        NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:moviePath])
        {
            NSError *error = nil;
            NSData *videoData = [[NSData alloc] initWithBase64EncodedString:cellData.value[@"data"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
            
            //            videoData writeToURL:movieURL atomically:<#(BOOL)#>
            //            [videoData writeToFile:moviePath atomically:YES];
            [videoData writeToURL:movieURL options:NSDataWritingAtomic error:&error];
            //            NSError *error;
            //            if ([fileManager removeItemAtPath:moviePath error:&error] == NO)
            //            {
            //                //Error - handle if requried
            //            }
        }
        
        AVPlayer *player = [AVPlayer playerWithURL:movieURL];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        UIView *playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
        
        playerLayer.frame = playerContainer.frame;
        [playerContainer.layer addSublayer: playerLayer];
        [newGridTile addSubview:playerContainer];
        
        [player play];
        
        [tileData setObject:player forKey:@"player"];
        [tileData setObject:playerLayer forKey:@"playerLayer"];
        [tileData setObject:playerContainer forKey:@"playerContainer"];
        
        [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[player currentItem]];
        
    }

    UITapGestureRecognizer *tappedTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedTile:)];
    [newGridTile addGestureRecognizer:tappedTile];
    
    [self.gridView addSubview:newGridTile];
    [tileData setObject:newGridTile forKey:@"view"];
    [tileData setObject:snapshot forKey:@"data"];
    [tileData setValue:[NSNumber numberWithBool:0] forKey:@"enlarged"];
    
    [self.gridData insertObject:tileData atIndex:0];
//    [self.gridTiles insertObject:newGridTile atIndex:0];
//    [self.gridData addObject:cellData];
    
    [self layoutGrid:0];
    
}

- (void) layoutGrid:(BOOL)tapped {
    
    CGFloat duration;
    if(tapped){
        duration = 0.5;
    } else {
        duration = 0.0;
    }
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        int i = 0;
        bool was_enlarged = 0;
        for(NSDictionary *tileData in self.gridData){
            int width, height;
            if([[tileData valueForKey:@"enlarged"] isEqualToValue:[NSNumber numberWithBool:1]]){
                width = 640/2;
                height = 1136/4;
                [[tileData objectForKey:@"view"] setFrame:CGRectMake(0, 0, 640/2, 1136/4)];
                was_enlarged = 1;
                [self.overlay setAlpha:1.0];
                [self.overlay setTag:i];
                [self.gridView bringSubviewToFront:self.overlay];
                [self.gridView bringSubviewToFront:[tileData objectForKey:@"view"]];
            } else {
                width = 640/4;
                height = 1136/8;
                [[tileData objectForKey:@"view"] setFrame:CGRectMake((i%2) * 640/4, (i/2) * 1136/8, width, height)];
            }
            
            FDataSnapshot *snapshot = [tileData objectForKey:@"data"];

            if([snapshot.value[@"type"] isEqualToString:@"image"]){
                [[tileData objectForKey:@"imageView"] setFrame:CGRectMake(0, 0, width, height)];
            } else if([snapshot.value[@"type"] isEqualToString:@"video"]){
                [[tileData objectForKey:@"playerLayer"] setFrame:CGRectMake(0, 0, width, height)];
                [[tileData objectForKey:@"playerContainer"] setFrame:CGRectMake(0, 0, width, height)];
            }
            
            [[tileData objectForKey:@"view"] setTag:i];
            i++;
        }
        
        if(!was_enlarged){
            [self.overlay setAlpha:0.0];
        }
    } completion:^(BOOL finished) {
        for(int i = 6; i < [self.gridData count]; i++){
            if([[self.gridData[i] objectForKey:@"enlarged"] isEqualToNumber:[NSNumber numberWithBool:0]]){
                [[self.gridData[i] objectForKey:@"view"] removeFromSuperview];
                [self.gridData removeObjectAtIndex:i];
                i--;
            }
        }
        
        //
    }];

}

- (void)tappedTile:(UITapGestureRecognizer *)gestureRecognizer {
    [self.gridView bringSubviewToFront:[gestureRecognizer view]];
    NSInteger tag = [[gestureRecognizer view] tag];
    NSMutableDictionary *tileData = self.gridData[tag];
    float alpha;
    if([[tileData valueForKey:@"enlarged"] isEqualToValue:[NSNumber numberWithBool:1]]){
        [tileData setValue:[NSNumber numberWithBool:0] forKey:@"enlarged"];
        alpha = 0.0;
    } else {
        [tileData setValue:[NSNumber numberWithBool:1] forKey:@"enlarged"];
        alpha = 1.0;
    }
    [self layoutGrid:1];
    
}

//loop video when ends
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (void)initFirebase {
    self.firebase = [[Firebase alloc] initWithUrl:@"https://pic6.firebaseIO.com"];
    
    [[[self.firebase childByAppendingPath:NODE_NAME] queryLimitedToNumberOfChildren:6] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
//        NSLog(@"%@", snapshot.value);
//        [self.gridData insertObject:snapshot atIndex:0];
//        while([self.gridData count] > 6){
//            [self.gridData removeLastObject];
//        }
//        
//        [self.grid reloadData];
        [self insertGridTile:snapshot];
    }];
}

- (void) initStream {
}

- (void)initCameraFrame {
    [self.cameraView removeFromSuperview];
    self.cameraView = [[UIImageView alloc] initWithFrame:CGRectMake(640/4, 0, 640/4, 1136/8)];
    [self.view addSubview:self.cameraView];
    [self.view bringSubviewToFront:self.gridView];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
    [longPressGestureRecognizer setMinimumPressDuration:0.4f];
    longPressGestureRecognizer.delegate = self;
    [self.cameraView addGestureRecognizer:longPressGestureRecognizer];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.cameraView setUserInteractionEnabled:YES];
    tapGestureRecognizer.delegate = self;
    [tapGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
    [self.cameraView addGestureRecognizer:tapGestureRecognizer];

}

- (void)handleHold:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self endHold];
    } else if (recognizer.state == UIGestureRecognizerStateBegan){
        [self startHold];
    }
}

- (void)startHold {
    NSLog(@"begann!!!");
    self.recording = 1;
    self.indicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 8)];
    [self.indicator setBackgroundColor:[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.75]];
    [self.cameraView addSubview:self.indicator];
    
    [UIView animateWithDuration:6.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.indicator setFrame:CGRectMake(0, 0, 640/4, 8)];
    } completion:^(BOOL finished) {
        if(finished){
            [self endHold];
        }
        //
    }];
    [self startRecordingVideo];
    
}

- (void) endHold {
    if(self.recording){
        NSLog(@"Ended!!!");
        [self.indicator removeFromSuperview];
        [self stopRecordingVideo];
        // Do Whatever You want on End of Gesture
        self.recording = 0;
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    [self capImage];
}

- (void)initCamera {
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
	session.sessionPreset = AVCaptureSessionPresetMedium;
    
    //display camera preview frame
	AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //display camera preview frame
	captureVideoPreviewLayer.frame = self.cameraView.bounds;
	[self.cameraView.layer addSublayer:captureVideoPreviewLayer];
    
    //display camera preview frame
    UIView *view = [self cameraView];
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    //set camera preview frame
    CGRect bounds = [view bounds];
    [captureVideoPreviewLayer setFrame:bounds];
    
    //get front and back camera objects
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *captureDevice;
    
    //get front and back camera objects
    for (AVCaptureDevice *device in devices) {
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack && !self.FrontCamera) {
                captureDevice = device;
            }
            if ([device position] == AVCaptureDevicePositionFront && self.FrontCamera) {
                captureDevice = device;
            }
        }
    }
    
    if ( [captureDevice lockForConfiguration:NULL] == YES ) {
        captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30);
        captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 30);
        [captureDevice unlockForConfiguration];
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    [session addInput:input];
    
    //set still image output
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    //still setting still image output
    [session addOutput:self.stillImageOutput];
    

	//ADD MOVIE FILE OUTPUT
	NSLog(@"Adding movie file output");
	self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
	
	Float64 TotalSeconds = 6;			//Total seconds
	int32_t preferredTimeScale = 10;	//Frames per second
	CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
	self.movieFileOutput.maxRecordedDuration = maxDuration;
	
	self.movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024; //SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
	
	if ([session canAddOutput:self.movieFileOutput]) {
		[session addOutput:self.movieFileOutput];
    }
    
	//SET THE CONNECTION PROPERTIES (output properties)
	//[self CameraSetOutputProperties];
    
    
    
    [session startRunning];
}

- (void) startRecordingVideo {
//    AVCaptureMovieFileOutput *aMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];

    
    NSLog(@"START RECORDING");
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
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
	NSLog(@"didFinishRecordingToOutputFileAtURL - enter");
	
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
        NSLog(@"didFinishRecordingToOutputFileAtURL - success");

        NSData *videoData = [NSData dataWithContentsOfURL:outputFileURL];
        NSLog(@"%lu", (unsigned long)[videoData length]);
        [self uploadVideo:videoData];
        
//		ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//		if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
//		{
//			[library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
//										completionBlock:^(NSURL *assetURL, NSError *error)
//             {
//                 if (error)
//                 {
//                     
//                 }
//             }];
//		}
	}
    
}

- (void) uploadVideo:(NSData *) videoData {
    NSString *stringData = [videoData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    Firebase *newVideo = [[self.firebase childByAppendingPath:NODE_NAME] childByAutoId];
    [newVideo setValue:@{@"type": @"video", @"data":stringData}];
    NSLog(@"video!!!");
}

- (void) capImage { //method to capture image from AVCaptureSession video feed
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    NSLog(@"about to request a capture from: %@", self.stillImageOutput);
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (imageSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            [self processImage:[UIImage imageWithData:imageData]];
        }
    }];
}

- (void)processImage:(UIImage *) image {
    //resizes image
    UIImage *newImage = [image imageScaledToFitSize:CGSizeMake(640/4, 1136/8)];
    NSData *imageData = UIImageJPEGRepresentation(newImage, 1);
    NSLog(@"%lu", (unsigned long)[imageData length]);
    [self uploadImage:imageData];
}

- (void)uploadImage:(NSData *) imageData {
    //NSString *stringData = [[NSString alloc] initWithData:imageData encoding:NSUTF8StringEncoding];
    //NSString *stringData = [NSString stringWithUTF8String:[imageData bytes]];
    NSString *stringData = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    Firebase *newImage = [[self.firebase childByAppendingPath:NODE_NAME] childByAutoId];
    [newImage setValue:@{@"type": @"image", @"data":stringData}];
    //    NSLog(@"%@", stringData);
}

- (IBAction)switchCamera:(id)sender { //switch cameras front and rear cameras
    if (self.FrontCamera == 1) {
        self.FrontCamera = 0;
    } else {
        self.FrontCamera = 1;
    }
    [self initCameraFrame];
    [self initCamera];
}

- (void)willEnterForeground {
    for(NSDictionary *gridData in self.gridData){
        FDataSnapshot *snapshot = [gridData objectForKey:@"data"];
        if([snapshot.value[@"type"] isEqualToString:@"video"]){
            AVPlayer *player = [gridData objectForKey:@"player"];
            [player play];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
