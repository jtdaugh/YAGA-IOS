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
    
    UIView *plaque = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    [logo setImage:[UIImage imageNamed:@"Logo"]];
    [plaque addSubview:logo];
    [self.view addSubview:plaque];
    
    [self initSwitchButton];
    [self initLoader];
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
    UIButton *switchButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH - 60, TILE_HEIGHT - 60, 50, 50)];
    [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.view addSubview:switchButton];
}

- (void)initLoader {
    self.loader = [[UIView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH*2, TILE_HEIGHT*3)];
    [self.loader setBackgroundColor:PRIMARY_COLOR];
    self.loaderTiles = [NSMutableArray array];
    for(int i = 0; i<6; i++){
        int x, y;
        if(i > 2){
            x = 0;
            y = TILE_HEIGHT * (-i + 5);
        } else if (i <= 2){
            x = TILE_WIDTH;
            y = TILE_HEIGHT * i;
        }
        
        UIView *tile = [[UIView alloc] initWithFrame:CGRectMake(x, y, TILE_WIDTH, TILE_HEIGHT)];
        [self.loaderTiles addObject:tile];
        [self.loader addSubview:tile];
    }
    
    [self.view addSubview:self.loader];
    
    self.loaderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(loaderTick:)
                                   userInfo:nil
                                    repeats:YES];
    self.loading = 1;
    self.tickCount = 0;
}

- (void)loaderTick:(NSTimer *) timer {
//    NSArray *positions = @[@0, @1, @4, @3, @2, @1, @4, @5];
//    NSArray *positions = [[NSArray alloc] initWithObjects:0, 1, 4, 3, 2, 1, 4, 5,nil];
    int positions[8] = {0,1,4,3,2,1,4,5};
    int rootIndex = self.tickCount % 8;
    int trailer1Index = (self.tickCount - 1) % 8;
    int trailer2Index = (self.tickCount - 2) % 8;
    
    int root = 0;
//    int root = (int);
    int trailer1 = (int)positions[(self.tickCount - 1) % 8];
    int trailer2 = (int)positions[(self.tickCount - 2) % 8];
    
    for(int i = 0; i < [self.loaderTiles count]; i++){
        if(i == (int) positions[self.tickCount % 8]){// if i == root
            [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)([UIColor colorWithWhite:1.0 alpha:0.5])];
        } else if (i == (int) positions[(self.tickCount - 1) % 8]){
            [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)([UIColor colorWithWhite:1.0 alpha:0.25])];
        } else if (i == (int) positions[(self.tickCount - 2) % 8]){
            [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)([UIColor colorWithWhite:1.0 alpha:0.125])];
        } else {
            [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)(PRIMARY_COLOR)];
        }
    }
    self.tickCount = self.tickCount + 1;
}

- (void) doneLoading {
    [self.loaderTimer invalidate];
    [self.loader removeFromSuperview];
}

- (void)initGridView {
    self.gridView = [[UIView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH * 2, TILE_HEIGHT * 3)];

    self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, -TILE_HEIGHT, TILE_WIDTH * 2, TILE_HEIGHT*4)];
    [self.overlay setBackgroundColor:[UIColor blackColor]];
    [self.overlay setAlpha:0.0];
    
    self.displayName = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, TILE_WIDTH * 2, 40)];
    [self.displayName setTextAlignment:NSTextAlignmentCenter];
    [self.displayName setTextColor:[UIColor whiteColor]];
    [self.displayName setFont:[UIFont systemFontOfSize:24]];
    
    [self.overlay addSubview:self.displayName];
    [self.gridView addSubview:self.overlay];
    [self.view addSubview:self.gridView];
    self.gridData = [NSMutableArray array];
    self.gridTiles = [NSMutableArray array];
    self.players = [NSMutableDictionary dictionary];
    
}

- (void)insertGridTile:(FDataSnapshot *)snapshot {
    UIView *newGridTile = [[UIView alloc] initWithFrame:CGRectMake(TILE_WIDTH, -TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)];
    FDataSnapshot *cellData = snapshot;
    
    NSMutableDictionary *tileData = [NSMutableDictionary dictionary];
    if([cellData.value[@"type"] isEqualToString:@"image"]){
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
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
        
        UIView *playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
        
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
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:0 animations:^{
        int i = 0;
        bool was_enlarged = 0;
        for(NSDictionary *tileData in self.gridData){
            int width, height, top_offset;
            FDataSnapshot *snapshot = [tileData objectForKey:@"data"];

            if([[tileData valueForKey:@"enlarged"] isEqualToValue:[NSNumber numberWithBool:1]]){
                width = TILE_WIDTH * 2;
                height = TILE_HEIGHT * 2;
                top_offset = -TILE_HEIGHT/2;
                [[tileData objectForKey:@"view"] setFrame:CGRectMake(0, top_offset, TILE_WIDTH * 2, TILE_HEIGHT * 2)];
                was_enlarged = 1;
                [self.overlay setAlpha:1.0];
                [self.overlay setTag:i];
                [self.displayName setText:snapshot.value[@"user"]];
                NSLog(@"%@", snapshot.value[@"user"]);
                [self.gridView bringSubviewToFront:self.overlay];
                [self.view bringSubviewToFront:self.cameraView];
                [self.cameraView setFrame:CGRectMake(TILE_WIDTH, TILE_HEIGHT*3, TILE_WIDTH, TILE_HEIGHT)];
                self.captureVideoPreviewLayer.frame = self.cameraView.bounds;
                [self.gridView bringSubviewToFront:[tileData objectForKey:@"view"]];
            } else {
                width = TILE_WIDTH;
                height = TILE_HEIGHT;
                top_offset = 0;
                [[tileData objectForKey:@"view"] setFrame:CGRectMake((i%2) * TILE_WIDTH, (i/2) * TILE_HEIGHT, width, height)];
            }
            
            if([snapshot.value[@"type"] isEqualToString:@"image"]){
                [[tileData objectForKey:@"imageView"] setFrame:CGRectMake(0, 0, width, height)];
            } else if([snapshot.value[@"type"] isEqualToString:@"video"]){
                if([[tileData valueForKey:@"enlarged"] isEqualToValue:[NSNumber numberWithBool:1]]){
                    [self setAudioLevel:1.0 forPlayer:[tileData objectForKey:@"player"]];
                } else {
                    [self setAudioLevel:0.0 forPlayer:[tileData objectForKey:@"player"]];
                }
                [[tileData objectForKey:@"playerLayer"] setFrame:CGRectMake(0, 0, width, height)];
                [[tileData objectForKey:@"playerContainer"] setFrame:CGRectMake(0, 0, width, height)];
            }
            
            [[tileData objectForKey:@"view"] setTag:i];
            i++;
        }
        
        if(!was_enlarged){
            [self.view bringSubviewToFront:self.cameraView];
            [self.cameraView setFrame:CGRectMake(TILE_WIDTH, 0, TILE_WIDTH, TILE_HEIGHT)];
            self.captureVideoPreviewLayer.frame = self.cameraView.bounds;
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
        [self insertGridTile:snapshot];
        if(self.loading){
            self.loading = 0;
            [self doneLoading];
        }
    }];
}

- (void) initStream {
}

- (void)initCameraFrame {
    [self.cameraView removeFromSuperview];
    self.cameraView = [[UIImageView alloc] initWithFrame:CGRectMake(TILE_WIDTH, 0, TILE_WIDTH, TILE_HEIGHT)];
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
        [self.indicator setFrame:CGRectMake(0, 0, TILE_WIDTH, 8)];
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
	self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [self.captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //display camera preview frame
	self.captureVideoPreviewLayer.frame = self.cameraView.bounds;
	[self.cameraView.layer addSublayer:self.captureVideoPreviewLayer];
    
    //display camera preview frame
    UIView *view = [self cameraView];
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    //set camera preview frame
    CGRect bounds = [view bounds];
    [self.captureVideoPreviewLayer setFrame:bounds];
    
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
    
    //ADD AUDIO INPUT
	NSLog(@"Adding audio input");
	AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
	if (audioInput)
	{
		[session addInput:audioInput];
	}
    
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
    [newVideo setValue:@{@"type": @"video", @"data":stringData, @"user":[self humanName]}];
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
    UIImage *newImage = [image imageScaledToFitSize:CGSizeMake(TILE_WIDTH, TILE_HEIGHT)];
    NSData *imageData = UIImageJPEGRepresentation(newImage, 1);
    NSLog(@"%lu", (unsigned long)[imageData length]);
    [self uploadImage:imageData];
}

- (void)uploadImage:(NSData *) imageData {
    //NSString *stringData = [[NSString alloc] initWithData:imageData encoding:NSUTF8StringEncoding];
    //NSString *stringData = [NSString stringWithUTF8String:[imageData bytes]];
    NSString *stringData = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    Firebase *newImage = [[self.firebase childByAppendingPath:NODE_NAME] childByAutoId];
    [newImage setValue:@{@"type": @"image", @"data":stringData, @"user":[self humanName]}];
    //    NSLog(@"%@", stringData);
}

- (void)setAudioLevel:(CGFloat) level forPlayer:(AVPlayer *)player  {
    AVAsset *asset = [[player currentItem] asset];
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    // Mute all the audio tracks
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =    [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:level atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioZeroMix = [AVMutableAudioMix audioMix];
    [audioZeroMix setInputParameters:allAudioParams];
    
    [[player currentItem] setAudioMix:audioZeroMix];
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

- (NSString *)humanName {
    NSString *deviceName = [[UIDevice currentDevice].name lowercaseString];
    for (NSString *string in @[@"’s iphone", @"’s ipad", @"’s ipod touch", @"’s ipod",
                               @"'s iphone", @"'s ipad", @"'s ipod touch", @"'s ipod",
                               @"s iphone", @"s ipad", @"s ipod touch", @"s ipod", @"iphone"]) {
        NSRange ownershipRange = [deviceName rangeOfString:string];
        
        if (ownershipRange.location != NSNotFound) {
            return [[[deviceName substringToIndex:ownershipRange.location] componentsSeparatedByString:@" "][0]
                    stringByReplacingCharactersInRange:NSMakeRange(0,1)
                    withString:[[deviceName substringToIndex:1] capitalizedString]];
        }
    }
    
    return [UIDevice currentDevice].name;
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
