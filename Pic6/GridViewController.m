//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GridViewController.h"
#import "UIImage+Resize.h"
#import "NSString+File.h"
#import "TileCell.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "OverlayViewController.h"
#import "CliqueViewController.h"

@interface GridViewController ()
@end

@implementation GridViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
//    [[UIApplication sharedApplication].delegate.window setRootViewController:self];
//    [self willEnterForeground];
    
    
    if(![self.appeared boolValue]){
        self.appeared = [NSNumber numberWithBool:YES];
    }
    
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    window.rootViewController = self;
    [window makeKeyAndVisible];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.cameraAccessories = [[NSMutableArray alloc] init];

    [self initOverlay];
    [self initGridView];
    [self initPlaque];
    self.FrontCamera = [NSNumber numberWithBool:0];
    if([self.onboarding boolValue] || 1){
        [self initCameraButton];
        for(UIView *v in self.cameraAccessories){
            [v setAlpha:0.0];
        }
    } else {
        [self initCameraView];
        [self initCamera];
    }
    [self initFirebase];
    
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

- (void)initPlaque {
    self.plaque = [[UIView alloc] init];
    [self.plaque setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    [self.plaque setBackgroundColor:PRIMARY_COLOR];
    
    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, TILE_WIDTH-16, 36)];
    [logo setText:APP_NAME]; // 🔥
    [logo setTextColor:[UIColor whiteColor]];
    [logo setFont:[UIFont fontWithName:BIG_FONT size:30]];
    [self.plaque addSubview:logo];
    
    UILabel *instructions = [[UILabel alloc] initWithFrame:CGRectMake(10, 30+8+4, TILE_WIDTH-16, 60)];
    [instructions setText:@"📹 Hold to record 👉"];
    [instructions setNumberOfLines:0];
    [instructions sizeToFit];
    [instructions setTextColor:[UIColor whiteColor]];
    [instructions setFont:[UIFont fontWithName:BIG_FONT size:13]];
    [self.cameraAccessories addObject:instructions];
    [self.plaque addSubview:instructions];

    self.switchButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH - 60, TILE_HEIGHT - 60, 50, 50)];
    [self.switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.switchButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [self.cameraAccessories addObject:self.switchButton];
    [self.plaque addSubview:self.switchButton];

    UIButton *cliqueButton = [[UIButton alloc] initWithFrame:CGRectMake(10, TILE_HEIGHT - 60, 50, 50)];
    [cliqueButton addTarget:self action:@selector(manageClique:) forControlEvents:UIControlEventTouchUpInside];
    [cliqueButton setImage:[UIImage imageNamed:@"Clique"] forState:UIControlStateNormal];
    [cliqueButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [self.plaque addSubview:cliqueButton];
    
    [self.gridView addSubview:self.plaque];
}

- (void)initGridView {
    self.gridView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT * 4)];
    
    int tile_buffer = 0;
    
    UICollectionViewFlowLayout *layout= [[UICollectionViewFlowLayout alloc] init];
    [layout setSectionInset:UIEdgeInsetsMake(0, 0, TILE_HEIGHT*tile_buffer, 0)];
    [layout setMinimumInteritemSpacing:0.0];
    [layout setMinimumLineSpacing:0.0];
    self.gridTiles = [[UICollectionView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH*2, TILE_HEIGHT*3 + tile_buffer*TILE_HEIGHT) collectionViewLayout:layout];
    [self.gridTiles setBackgroundColor:[UIColor blackColor]];
    self.gridTiles.delegate = self;
    self.gridTiles.dataSource = self;
    [self.gridTiles registerClass:[TileCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.gridTiles setBackgroundColor:PRIMARY_COLOR];
//    [self.gridTiles setBounces:NO];
    [self.gridView addSubview:self.gridTiles];
    
    [self.view addSubview:self.gridView];
    self.gridData = [NSMutableArray array];
}

- (void) initOverlay {
    self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT*4)];
    [self.overlay setBackgroundColor:[UIColor blackColor]];
    [self.overlay setAlpha:0.0];

    [self.view addSubview:self.overlay];
}

- (void)initFirebase {
    
    self.firebase = [[[Firebase alloc] initWithUrl:@"https://pic6.firebaseIO.com"] childByAppendingPath:NODE_NAME];;
    
    [[[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", DATA]] queryLimitedToNumberOfChildren:NUM_TILES] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"children count: %lu", snapshot.childrenCount);
        NSString *lastUid;
        for (FDataSnapshot* child in snapshot.children) {
            [self.gridData insertObject:child atIndex:0];
            lastUid = child.name;
        }
        [self.gridTiles reloadData];
        [self listenForChanges];
    }];
}

- (void)listenForChanges {
    
    //new child added
    [[[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", DATA]] queryLimitedToNumberOfChildren:1] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [self newTile:snapshot];
    }];

}

- (void) newTile:(FDataSnapshot *)snapshot {
    if(!([self.gridData count] > 0 && [[(FDataSnapshot *)self.gridData[0] name] isEqualToString:snapshot.name])){
        [self.gridData insertObject:snapshot atIndex:0];
        [self.gridTiles insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    }
}

- (void) triggerRemoteLoad:(NSString *)uid {
    [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
        if(dataSnapshot.value != [NSNull null]){
            NSError *error = nil;
            
            NSData *videoData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value[@"video"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
            
            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value[@"thumb"] options:NSDataBase64DecodingIgnoreUnknownCharacters];

            if(videoData != nil && imageData != nil){
                NSURL *movieURL = [uid movieUrl];
                [videoData writeToURL:movieURL options:NSDataWritingAtomic error:&error];

                NSURL *imageURL = [uid imageUrl];
                [imageData writeToURL:imageURL options:NSDataWritingAtomic error:&error];
            }
            
            [self finishedLoading:uid];
            
        }
    }];
}

- (void) finishedLoading:(NSString *)uid {
    for(TileCell *tile in [self.gridTiles visibleCells]){
        if([tile.uid isEqualToString:uid]){
            [self.gridTiles reloadItemsAtIndexPaths:@[[self.gridTiles indexPathForCell:tile]]];
        }
    }
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.gridData count];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(TILE_WIDTH, TILE_HEIGHT);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    FDataSnapshot *snapshot = [self.gridData objectAtIndex:indexPath.row];
    cell.state = [NSNumber numberWithInt:LIMBO];
    
    if(![cell.uid isEqualToString:snapshot.name]){

        [cell setUid:snapshot.name];
        [cell setUsername:snapshot.value[@"user"]];

        if(cell.isLoaded){
            if([self.scrolling boolValue]){
                [cell showImage];
            } else {
                [cell play];
            }
        } else {
            [cell showLoader];
            [self triggerRemoteLoad:cell.uid];
        }
    }
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.scrolling = [NSNumber numberWithBool:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollingEnded];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(!decelerate){
        [self scrollingEnded];
    }
}

- (void)scrollingEnded {
    self.scrolling = [NSNumber numberWithBool:NO];
    for(TileCell *cell in [self.gridTiles visibleCells]){
        if([cell.state isEqualToNumber:[NSNumber numberWithInt: LOADED]]){
            [cell play];
        } else {

        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected");
    
    TileCell *selected = (TileCell *)[collectionView cellForItemAtIndexPath:indexPath];
        
    selected.frame = CGRectMake(selected.frame.origin.x, selected.frame.origin.y - collectionView.contentOffset.y + TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT);
    [self.overlay addSubview:selected];

    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        [self.view bringSubviewToFront:self.overlay];
        [self.overlay setAlpha:1.0];
        [selected.player setVolume:1.0];
        [selected setVideoFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH*2, TILE_HEIGHT*2)];
    } completion:^(BOOL finished) {
        //
        OverlayViewController *overlay = [[OverlayViewController alloc] init];
        [overlay setTile:selected];
        [overlay setPreviousViewController:self];
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:overlay animated:NO completion:^{
            
        }];
    }];
    
}

- (void) collapse:(TileCell *)tile {
    tile.frame = CGRectMake(0, self.gridTiles.contentOffset.y, TILE_WIDTH*2, TILE_HEIGHT*2);
    [self.gridTiles addSubview:tile];
    [self.overlay setAlpha:0.0];
//    [self.gridTiles addSubview:self.overlay];
    
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        NSIndexPath *ip = [self.gridTiles indexPathForCell:tile];
        [tile setVideoFrame:[self.gridTiles layoutAttributesForItemAtIndexPath:ip].frame];
        //
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)manageClique:(id)sender { //switch cameras front and rear cameras
    CliqueViewController *vc = [[CliqueViewController alloc] init];
    [self presentViewController:vc animated:YES completion:^{
        //
    }];
}

- (IBAction)switchCamera:(id)sender { //switch cameras front and rear cameras
    if ([self.FrontCamera boolValue]) {
        self.FrontCamera = [NSNumber numberWithBool:NO];
    } else {
        self.FrontCamera = [NSNumber numberWithBool:YES];
    }
//    [self.session beginConfiguration];
//    [self.session commitConfiguration];

    [self reloadCamera];
}

- (void)reloadCamera {
    [self.session beginConfiguration];
    // find video object and remove it
    [self.session removeInput:self.videoInput];
    [self addCameraInput];
    [self.session commitConfiguration];
}

- (void)reloadCameraAndAudio {
    [self.session beginConfiguration];
    for(AVCaptureDeviceInput *input in self.session.inputs){
        [self.session removeInput:input];
    }
    [self.session commitConfiguration];

}

- (void)initCameraView {
    self.cameraView = [[UIView alloc] initWithFrame:CGRectMake(TILE_WIDTH, 0, TILE_WIDTH, TILE_HEIGHT)];
    [self.cameraView setBackgroundColor:PRIMARY_COLOR];
    [self.gridView addSubview:self.cameraView];
    
    for(UIView *v in self.cameraAccessories){
        [v setAlpha:1.0];
    }
    
    [self.cameraView setUserInteractionEnabled:YES];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
    [longPressGestureRecognizer setMinimumPressDuration:0.2f];
    longPressGestureRecognizer.delegate = self;
    [self.cameraView addGestureRecognizer:longPressGestureRecognizer];
    
}

- (void)initCameraButton {
    UIButton *cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH, 0, TILE_WIDTH, TILE_HEIGHT)];
    [cameraButton setBackgroundColor:SECONDARY_COLOR];
    [cameraButton setImage:[UIImage imageNamed:@"Camera"] forState:UIControlStateNormal];
    [cameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [cameraButton addTarget:self action:@selector(cameraButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [cameraButton setTitle:@"Enable Camera" forState:UIControlStateNormal];
    
    [cameraButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:13]];
    
    // the space between the image and text
    CGFloat spacing = 6.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = cameraButton.imageView.frame.size;
    cameraButton.titleEdgeInsets = UIEdgeInsetsMake(
                                              0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = cameraButton.titleLabel.frame.size;
    cameraButton.imageEdgeInsets = UIEdgeInsetsMake(
                                              - (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
    
    [self.gridView addSubview:cameraButton];
    
}

- (void)cameraButtonTapped {
    [self initCameraView];
    [self initCamera];
    [self setOnboarding:[NSNumber numberWithBool:NO]];
    NSLog(@"tapped");
    
}
- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeAudio;
    
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

- (void)initCamera {
    
        self.session = [[AVCaptureSession alloc] init];
        self.session.sessionPreset = AVCaptureSessionPresetMedium;
        
        //display camera preview frame
        self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [self.captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        //display camera preview frame
        self.captureVideoPreviewLayer.frame = self.cameraView.bounds;

//        [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
        [[self.cameraView.layer.sublayers firstObject] removeFromSuperlayer];
        [self.cameraView.layer addSublayer:self.captureVideoPreviewLayer];

        //display camera preview frame
        UIView *view = [self cameraView];
        CALayer *viewLayer = [view layer];
        [viewLayer setMasksToBounds:YES];
        
        //set camera preview frame
        CGRect bounds = [view bounds];
        [self.captureVideoPreviewLayer setFrame:bounds];

    
        //set still image output
        [self addCameraInput];
        [self addAudioInput];
    
        //ADD MOVIE FILE OUTPUT
        self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        
        Float64 TotalSeconds = 6;			//Total seconds
        int32_t preferredTimeScale = 10;	//Frames per second
        CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
        self.movieFileOutput.maxRecordedDuration = maxDuration;
        
        self.movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024; //SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
        if ([self.session canAddOutput:self.movieFileOutput]) {
            [self.session addOutput:self.movieFileOutput];
        }
            
        [self.session startRunning];

}

- (void)closeCamera {
    [self.session beginConfiguration];
    for(AVCaptureDeviceInput *input in self.session.inputs){
        [self.session removeInput:input];
    }
    [self.session commitConfiguration];
    [self.session stopRunning];
}

- (void)addAudioInput {
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
        //ADD AUDIO INPUT
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    //    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        
        NSLog(@"adding audio input");
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
        AVCaptureDevice *captureDevice;
        
        for(AVCaptureDevice *device in devices){
            captureDevice = device;
            break;
        }
        
        // AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput * audioInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
        [self.session addInput:audioInput];
    });
}

- (void)removeAudioInput {
    [self.session beginConfiguration];
    [self.session removeInput:self.audioInput];
    [self.session commitConfiguration];
}

- (void)addCameraInput {
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    //    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        
        //get front and back camera objects
        NSArray *devices = [AVCaptureDevice devices];
        AVCaptureDevice *captureDevice;
        
        //get front and back camera objects
        for (AVCaptureDevice *device in devices) {
            
            if ([device hasMediaType:AVMediaTypeVideo]) {
                
                if ([device position] == AVCaptureDevicePositionBack && ![self.FrontCamera boolValue]) {
                    captureDevice = device;
                }
                if ([device position] == AVCaptureDevicePositionFront && [self.FrontCamera boolValue]) {
                    captureDevice = device;
                }
            }
        }
        
        if ([captureDevice lockForConfiguration:NULL] == YES ) {
            captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30);
            captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 30);
            
            if([captureDevice isTorchModeSupported:AVCaptureTorchModeAuto]){
                [captureDevice setTorchMode:AVCaptureTorchModeAuto];
            }
            
            [captureDevice unlockForConfiguration];
        }
        
        NSError *error = nil;
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        if (!self.videoInput) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        
        [self.session addInput:self.videoInput];
    });
}

- (void)handleHold:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self endHold];
    } else if (recognizer.state == UIGestureRecognizerStateBegan){
        [self startHold];
    }
}

- (void)startHold {
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
        [self.indicator removeFromSuperview];
        [self stopRecordingVideo];
        // Do Whatever You want on End of Gesture
        self.recording = 0;
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
        [self uploadData:videoData withType:@"video" withOutputURL:outputFileURL];
    }
    
}

- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL {
    // measure size of data
    NSLog(@"%@ size: %lu", type, (unsigned long)[data length]);
    
    // set up data object
    NSString *videoData = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    Firebase *dataObject = [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", MEDIA]] childByAutoId];
    NSString *dataPath = dataObject.name;
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:outputURL options:nil];
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [imageGenerator setAppliesPreferredTrackTransform:YES];
//    UIImage* image = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMake(0,1) actualTime:nil error:nil];
    
    UIImage *image = [[UIImage imageWithCGImage:imageRef] imageScaledToFitSize:CGSizeMake(TILE_WIDTH*2, TILE_HEIGHT*2)];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
    NSString *imageString = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    [dataObject setValue:@{@"video":videoData, @"thumb":imageString} withCompletionBlock:^(NSError *error, Firebase *ref) {
    }];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", DATA, dataPath];
    [[self.firebase childByAppendingPath:path] setValue:@{@"type": type, @"user":[self humanName]}];
    
    NSFileManager * fm = [[NSFileManager alloc] init];
    NSError *err = nil;
    [fm moveItemAtURL:outputURL toURL:[dataPath movieUrl] error:&err];
    [imageData writeToURL:[dataPath imageUrl] options:NSDataWritingAtomic error:&err];

    
    if(err){
        NSLog(@"error: %@", err);
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
    [self.view setAlpha:0.0];
    [self closeCamera];
    
}

- (void)willEnterForeground {
//    NSLog(@"will enter foreground");
    [self.view setAlpha:1.0];
    [self initCamera];

    for(TileCell *tile in [self.gridTiles visibleCells]){
        if([tile.state isEqualToNumber:[NSNumber numberWithInt: PLAYING]] || [tile.state  isEqualToNumber:[NSNumber numberWithInt:  LOADED]]){
            [tile play];
        }
    }
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"memory warning?");
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
