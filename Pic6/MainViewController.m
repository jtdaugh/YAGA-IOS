//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MainViewController.h"
#import "UIImage+Resize.h"
#import "NSString+File.h"
#import "TileCell.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "OverlayViewController.h"

@interface MainViewController ()
@property bool FrontCamera;
@property bool liked;
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
    
    [self initOverlay];
    [self initGridView];
    [self initPlaque];
    [self initFirebase];
    self.FrontCamera = 1;
    [self initCameraView];
    [self initCamera];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {

}

- (void)initPlaque {
    self.plaque = [[UIView alloc] init];
    [self.plaque setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    [self.plaque setBackgroundColor:PRIMARY_COLOR];
    
    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, TILE_WIDTH-16, 30)];
    [logo setText:APP_NAME]; // 🔥
    [logo setTextColor:[UIColor whiteColor]];
    [logo setFont:[UIFont boldSystemFontOfSize:30]];
    [self.plaque addSubview:logo];
    
    UILabel *instructions = [[UILabel alloc] initWithFrame:CGRectMake(10, 30+8+4, TILE_WIDTH-16, 60)];
    [instructions setText:@"📹 Hold to record 👉"];
    [instructions setNumberOfLines:0];
    [instructions sizeToFit];
    [instructions setTextColor:[UIColor whiteColor]];
    [instructions setFont:[UIFont systemFontOfSize:14]];
    [self.plaque addSubview:instructions];

    self.switchButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH - 60, TILE_HEIGHT - 60, 50, 50)];
    [self.switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.switchButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [self.plaque addSubview:self.switchButton];

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
        NSLog(@"%lu", snapshot.childrenCount);
        NSString *lastUid;
        for (FDataSnapshot* child in snapshot.children) {
            [self.gridData insertObject:child atIndex:0];
            lastUid = child.name;
        }
        [self.gridTiles reloadData];
        [self listenForChanges];
    }];
}

- (void)listenForChanges; {
    
    //new child added
    [[[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", DATA]] queryLimitedToNumberOfChildren:1] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [self newTile:snapshot];
    }];

    //child deleted
    [[[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", DATA]] queryLimitedToNumberOfChildren:1] observeEventType:FEventTypeChildMoved withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"child moved");
    }];

    [[[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", DATA]] queryLimitedToNumberOfChildren:1] observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"child deleted");
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
            
            NSData *videoData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value options:NSDataBase64DecodingIgnoreUnknownCharacters];
            
            if(videoData != nil){
                NSURL *movieURL = [uid movieUrl];
                [videoData writeToURL:movieURL options:NSDataWritingAtomic error:&error];
            }
            
            [self finishedLoading:uid];
            
        }
        
    }];
}

- (void) finishedLoading:(NSString *)uid {
    for(TileCell *tile in [self.gridTiles visibleCells]){
        if([tile.uid isEqualToString:uid]){
            [tile play];
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
    
    if(![cell.uid isEqualToString:snapshot.name]){

        [cell setUid:snapshot.name];
        [cell setUsername:snapshot.value[@"user"]];

        if(cell.isLoaded && !self.scrolling){
            [cell play];
        } else {
            [cell showLoader];
            if(!cell.isLoaded){
                [self triggerRemoteLoad:cell.uid];
            }
        }

    }
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.scrolling = YES;
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
    self.scrolling = NO;
    NSArray *visibleCells = [self.gridTiles visibleCells];
    for(TileCell *cell in visibleCells){
        if(cell.state == LOADING){
            if(cell.isLoaded && !self.scrolling){
                [cell play];
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected");
    
    TileCell *selected = (TileCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    selected.frame = CGRectMake(selected.frame.origin.x, selected.frame.origin.y - collectionView.contentOffset.y + TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT);
    [self.overlay addSubview:selected];

    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        //
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
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        [self.overlay setAlpha:0.0];
        NSIndexPath *ip = [self.gridTiles indexPathForCell:tile];
        [tile setVideoFrame:[self.gridTiles layoutAttributesForItemAtIndexPath:ip].frame];
        //
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (IBAction)switchCamera:(id)sender { //switch cameras front and rear cameras
    if (self.FrontCamera == 1) {
        self.FrontCamera = 0;
    } else {
        self.FrontCamera = 1;
    }
    
    [self reloadCamera];
}

- (void)reloadCamera {
    [self.session beginConfiguration];
    // find video object and remove it
    [self.session removeInput:[self.session.inputs lastObject]];
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
    [self.gridView addSubview:self.cameraView];
    
    [self.cameraView setUserInteractionEnabled:YES];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
    [longPressGestureRecognizer setMinimumPressDuration:0.2f];
    longPressGestureRecognizer.delegate = self;
    [self.cameraView addGestureRecognizer:longPressGestureRecognizer];
    
}

- (void)initCamera {
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    //display camera preview frame
    self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //display camera preview frame
    self.captureVideoPreviewLayer.frame = self.cameraView.bounds;
    [self.cameraView.layer addSublayer:self.captureVideoPreviewLayer];
    
    //display camera preview frame
    UIView *view = [self cameraView];
    CALayer *viewLayer = [view layer];
//    [viewLayer setMasksToBounds:YES];
    
    //set camera preview frame
    CGRect bounds = [view bounds];
//    [self.captureVideoPreviewLayer setFrame:bounds];
    
    NSError *error = nil;
    
    [self addAudioInput];
    
    //set still image output
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    //still setting still image output
    [self.session addOutput:self.stillImageOutput];
    
    
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
    
    //SET THE CONNECTION PROPERTIES (output properties)
    //[self CameraSetOutputProperties];
    
    [self addCameraInput];
    
    [self.session startRunning];
    
}

- (void)closeCamera {
    [self.session stopRunning];
}

- (void)addAudioInput {
    //ADD AUDIO INPUT
    NSError *error = nil;
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput) {
        [self.session addInput:audioInput];
    }
}

- (void)addCameraInput {
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
    
    if ([captureDevice lockForConfiguration:NULL] == YES ) {
        captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30);
        captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 30);
        
        if([captureDevice isTorchModeSupported:AVCaptureTorchModeAuto]){
            [captureDevice setTorchMode:AVCaptureTorchModeAuto];
        }
        
        [captureDevice unlockForConfiguration];
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    
    [self.session addInput:input];

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
    NSString *stringData = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    Firebase *dataObject = [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", MEDIA]] childByAutoId];
    NSString *dataPath = dataObject.name;
    [dataObject setValue:stringData withCompletionBlock:^(NSError *error, Firebase *ref) {
    }];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", DATA, dataPath];
    [[self.firebase childByAppendingPath:path] setValue:@{@"type": type, @"user":[self humanName]}];
    
    NSFileManager * fm = [[NSFileManager alloc] init];
    NSError *err = nil;
    [fm moveItemAtURL:outputURL toURL:[dataPath movieUrl] error:&err];
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
    NSLog(@"goodbye?");
//    [self.view setAlpha:0.0];
    [self closeCamera];
}

- (void)willEnterForeground {
    NSLog(@"awake 2!");
    [self initCamera];

    for(TileCell *tile in [self.gridTiles visibleCells]){
        if(tile.state == PLAYING){
            [tile.player play];
        }
    }
}

- (void)didReceiveMemoryWarning {
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
