//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MainViewController.h"
#import "UIImage+Resize.h"

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
    [self initGrid];
    [self initFirebase];
    [self initCameraFrame];
    self.FrontCamera = 1;
    [self initCamera];
}

- (void)viewDidAppear:(BOOL)animated {
}

- (void)initSwitchButton {
    UIButton *switchButton = [[UIButton alloc] initWithFrame:CGRectMake(640/4 - 60, 1168/8 - 60, 50, 50)];
    [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.view addSubview:switchButton];
}

- (void)initGrid {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    [layout setSectionInset:UIEdgeInsetsZero];
    [layout setMinimumInteritemSpacing:0.0];
    [layout setMinimumLineSpacing:0.0];
    self.grid = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 1136/8, 640/2, 1136/8 * 3) collectionViewLayout:layout];
//    self.grid = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 1136/8, 640/2, 1136/8 * 3)];
    self.grid.delegate = self;
    self.grid.dataSource = self;
    
    [self.grid registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.view addSubview:self.grid];
    
    self.gridData = [NSMutableArray array];
    
//    for(int i = 0; i<6; i++){
//        MPMoviePlayerController * __strong
//        MPMoviePlayerController *moviePlayer;
//        [self.moviePlayers addObject:moviePlayer];
//    }
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.gridData count];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(640/4, 1136/8);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [[UICollectionViewCell alloc] init];
//    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    FDataSnapshot *cellData = self.gridData[indexPath.row];
    if([cellData.value[@"type"] isEqualToString:@"image"]){
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView setClipsToBounds:YES];
        
        [cell addSubview:imageView];
        NSData *data = [[NSData alloc]initWithBase64EncodedString:cellData.value[@"data"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        [imageView setImage:[UIImage imageWithData:data]];
        
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
        
        playerLayer.frame = cell.frame;
        [cell.layer addSublayer: playerLayer];
        
//        // Create an AVURLAsset with an NSURL containing the path to the video
//        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
//        
//        // Create an AVPlayerItem using the asset
//        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
//        
//        // Create the AVPlayer using the playeritem
//        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
//        
//        // Create an AVPlayerLayer using the player
//        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//        
//        // Add it to your view's sublayers
//        [cell.layer addSublayer:playerLayer];
        
        // You can play/pause using the AVPlayer object
        [player play];
//        [player pause];
        
//        NSInteger i = indexPath.row;
//        
//        MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
////        self.moviePlayers[i] = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
//        
//        UIView *movieContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
//        
//        [moviePlayer.view setFrame:movieContainer.frame];
////        [self.moviePlayer prepareToPlay];
//        [moviePlayer setMovieSourceType: MPMovieSourceTypeFile];
//        [moviePlayer setRepeatMode:MPMovieRepeatModeOne];
//        [moviePlayer setControlStyle:MPMovieControlStyleNone];
//        [moviePlayer play];
//        [movieContainer addSubview:moviePlayer.view];
//        
//        switch(i){
//            case 0: self.moviePlayer1 = moviePlayer; break;
//            case 1: self.moviePlayer2 = moviePlayer; break;
//            case 2: self.moviePlayer3 = moviePlayer; break;
//            case 3: self.moviePlayer4 = moviePlayer; break;
//            case 4: self.moviePlayer5 = moviePlayer; break;
//            case 5: self.moviePlayer6 = moviePlayer; break;
//        }
//        
//        [cell addSubview:movieContainer];
    }

    return cell;
}

- (void)initFirebase {
    self.firebase = [[Firebase alloc] initWithUrl:@"https://pic6.firebaseIO.com"];
    
    [[[self.firebase childByAppendingPath:@"global"] queryLimitedToNumberOfChildren:6] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
//        NSLog(@"%@", snapshot.value);
        [self.gridData insertObject:snapshot atIndex:0];
        while([self.gridData count] > 6){
            [self.gridData removeLastObject];
        }
        
        [self.grid reloadData];
    }];
}

- (void) initStream {
}

- (void)initCameraFrame {
    [self.cameraView removeFromSuperview];
    self.cameraView = [[UIImageView alloc] initWithFrame:CGRectMake(640/4, 0, 640/4, 1136/8)];
    [self.view addSubview:self.cameraView];
    
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
        NSLog(@"Ended!!!");
        [self stopRecordingVideo];
        //Do Whatever You want on End of Gesture
    } else if (recognizer.state == UIGestureRecognizerStateBegan){
        NSLog(@"begann!!!");
        [self startRecordingVideo];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    NSLog(@"tapped!!!");
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

- (void) CameraSetOutputProperties
{
//	//SET THE CONNECTION PROPERTIES (output properties)
//	AVCaptureConnection *CaptureConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//	
//	//Set landscape (if required)
//	if ([CaptureConnection isVideoOrientationSupported])
//	{
//		AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;		//<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
//		[CaptureConnection setVideoOrientation:orientation];
//	}
//	
//	//Set frame rate (if requried)
//	CMTimeShow(CaptureConnection.videoMinFrameDuration);
//	CMTimeShow(CaptureConnection.videoMaxFrameDuration);
//	
//	if (CaptureConnection.supportsVideoMinFrameDuration)
//		CaptureConnection.videoMinFrameDuration = CMTimeMake(1, 10);
//	if (CaptureConnection.supportsVideoMaxFrameDuration)
//		CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, 10);
//	
//	CMTimeShow(CaptureConnection.videoMinFrameDuration);
//	CMTimeShow(CaptureConnection.videoMaxFrameDuration);
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
    Firebase *newVideo = [[self.firebase childByAppendingPath:@"global"] childByAutoId];
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
    Firebase *newImage = [[self.firebase childByAppendingPath:@"global"] childByAutoId];
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
