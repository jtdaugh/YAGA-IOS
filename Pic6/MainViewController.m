//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MainViewController.h"
#import "UIImage+Resize.h"
#import "UIView+Grid.h"
#import "TileCell.h"
#import "AVPlayer+AVPlayer_Async.h"

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
    [self initLoader];
    [self initPlaque];
    [self initFirebase];
    [self initCameraFrame];
    self.FrontCamera = 0;
    [self initCamera];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {

}

- (void)initPlaque {
    self.plaque = [[UIView alloc] init];
    [self.plaque setGridPosition:0];
    [self.plaque setBackgroundColor:PRIMARY_COLOR];
    
    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, TILE_WIDTH-16, 30)];
    [logo setText:APP_NAME]; // 🔥
    [logo setTextColor:[UIColor whiteColor]];
    [logo setFont:[UIFont boldSystemFontOfSize:30]];
    [self.plaque addSubview:logo];
    
    UILabel *instructions = [[UILabel alloc] initWithFrame:CGRectMake(10, 30+8+4, TILE_WIDTH-16, 60)];
    [instructions setText:@"Tap to snap, \nhold to record"];
    [instructions setNumberOfLines:0];
    [instructions sizeToFit];
    [instructions setTextColor:[UIColor whiteColor]];
    [instructions setFont:[UIFont systemFontOfSize:14]];
    [self.plaque addSubview:instructions];
//    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
//    [logo setImage:[UIImage imageNamed:@"Logo"]];
//    [self.plaque addSubview:logo];

    self.switchButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH - 60, TILE_HEIGHT - 60, 50, 50)];
    [self.switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.switchButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [self.plaque addSubview:self.switchButton];

    [self.gridView addSubview:self.plaque];
}

- (void)initLoader {
    self.loader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH*2, TILE_HEIGHT*4)];
    [self.loader setBackgroundColor:PRIMARY_COLOR];
    self.loaderTiles = [NSMutableArray array];
    for(int i = 2; i < 2 + NUM_TILES; i++){
        UIView *tile = [[UIView alloc] init];
        [tile setGridPosition:i];
        [self.loaderTiles addObject:tile];
        [self.loader addSubview:tile];
    }
    
//    [self.gridView addSubview:self.loader];
    
    self.loaderTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                     target:self
                                   selector:@selector(loaderTick:)
                                   userInfo:nil
                                    repeats:YES];
    self.loading = 1;
}

- (void)loaderTick:(NSTimer *) timer {
    for(int i = 0; i < NUM_TILES; i++){
        [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)([UIColor colorWithRed:((float)arc4random() / ARC4RANDOM_MAX) green:((float)arc4random() / ARC4RANDOM_MAX) blue:((float)arc4random() / ARC4RANDOM_MAX) alpha:0.5])];
    }
}

- (void) doneLoading {
    if(self.loading){
        self.loading = 0;
        [self.loader removeFromSuperview];
    }
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
    self.tiles = [NSMutableArray array];
    self.gridData = [NSMutableArray array];
}

- (void) initOverlay {
    self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT*4)];
    [self.overlay setBackgroundColor:[UIColor greenColor]];
    [self.overlay setAlpha:0.0];
    
//    UITapGestureRecognizer *collapseTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collapseTile)];
//    [self.overlay addGestureRecognizer:collapseTile];

//    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH-48-8, TILE_HEIGHT*3+16, 48, 48)];
//    [self.likeButton setTitle:@"😃" forState:UIControlStateNormal];
//    [self.likeButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
//    [self.likeButton setAlpha:0.5];
//    [self.likeButton addTarget:self action:@selector(likePressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.overlay addSubview:self.likeButton];
    
//    self.likeCount = [[UILabel alloc] initWithFrame:CGRectMake(VIEW_WIDTH-48-8-72-8, TILE_HEIGHT*3+16, 72, 48)];
//    [self.likeCount setTextAlignment:NSTextAlignmentRight];
//    [self.likeCount setTextColor:[UIColor whiteColor]];
//    [self.likeCount setFont:[UIFont systemFontOfSize:36]];
//    [self.overlay addSubview:self.likeCount];
    
//    self.displayName = [[UILabel alloc] initWithFrame:CGRectMake(8, TILE_HEIGHT*3 + 16, TILE_WIDTH, 48)];
//    [self.displayName setTextAlignment:NSTextAlignmentLeft];
//    [self.displayName setTextColor:[UIColor whiteColor]];
//    [self.displayName setFont:[UIFont systemFontOfSize:36]];
//    [self.overlay addSubview:self.displayName];
    [self.gridTiles addSubview:self.overlay];
}

- (NSURL *) movieUrlForSnapshotName:(NSString *)name {
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), name];
    NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
    return movieURL;
}

- (void) triggerRemoteLoad:(NSString *)uid {
    
    [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
        if(dataSnapshot.value != [NSNull null]){
            NSError *error = nil;
            
            NSData *videoData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value options:NSDataBase64DecodingIgnoreUnknownCharacters];
            
            if(videoData != nil){
                NSURL *movieURL = [self movieUrlForSnapshotName:uid];
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

- (void) newTile:(FDataSnapshot *)snapshot {
    [self.gridData insertObject:snapshot atIndex:0];
    [self.gridTiles insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
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
    
    [cell setUid:snapshot.name];
    
    if(cell.isLoaded && !self.scrolling){
        [cell play];
    } else {
        [cell showLoader];
        if(!cell.isLoaded){
            NSLog(@"triggering remote load of %@", cell.uid);
            [self triggerRemoteLoad:cell.uid];
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
    NSLog(@"scrolling ended");
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

- (void)selectedTile:(UITapGestureRecognizer *)gesture {
    TileCell *selected = (TileCell *)[gesture view];
    [selected removeFromSuperview];
    [self.overlay addSubview:selected];
    
    NSLog(@"yooo");
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        [self.view bringSubviewToFront:self.overlay];
        [self.overlay setAlpha:1.0];
        [selected setVideoFrame:CGRectMake(0, TILE_HEIGHT, 2*TILE_WIDTH, 2*TILE_HEIGHT)];
        //
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected");
//    TileCell *selected = (TileCell *)[collectionView cellForItemAtIndexPath:indexPath];
// //    [selected setSelected:YES];
//    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
//        [self.overlay setAlpha:1.0];
//        [collectionView bringSubviewToFront:self.overlay];
//        [collectionView bringSubviewToFront:selected];
//        [selected setSelected:YES];
//        [selected setVideoFrame:CGRectMake(0, TILE_HEIGHT, 2*TILE_WIDTH, 2*TILE_HEIGHT)];
//        
//        UITapGestureRecognizer *tappedTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deselectTile:)];
//        [selected addGestureRecognizer:tappedTile];
//    } completion:^(BOOL finished) {
//        //
//    }];
}

- (void)deselectTile:(UITapGestureRecognizer *)gesture {
    
//    TileCell *selected = (TileCell *)[gesture view];
//    NSIndexPath *indexPath = [self.gridTiles indexPathForCell:selected];
//    UICollectionViewLayoutAttributes *attributes = [self.gridTiles layoutAttributesForItemAtIndexPath:indexPath];
//    for (UIGestureRecognizer *recognizer in selected.gestureRecognizers) {
//        [selected removeGestureRecognizer:recognizer];
//    }
//
//    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
//        //
//        [selected setVideoFrame:attributes.frame];
//    } completion:^(BOOL finished) {
//        //
//    }];
//    NSLog(@"%li", indexPath.row);
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"deselected");
}


- (void)enlargeTile:(UITapGestureRecognizer *)gestureRecognizer {
    if(self.enlargedTile == nil){
        
        int tileIndex = 0;
        
        //get tapped tile
        for(Tile *tile in self.tiles){
            if(tile.view == [gestureRecognizer view]){
                break;
            }
            tileIndex++;
        }
        
        self.enlargedTile = self.tiles[tileIndex];
        
        //remove gesture recognizers
        for (UIGestureRecognizer *recognizer in self.enlargedTile.view.gestureRecognizers) {
            [self.enlargedTile.view removeGestureRecognizer:recognizer];
        }
        
        //resize tile
        [self.view bringSubviewToFront:self.overlay];
        [self.enlargedTile.view removeFromSuperview];
        [self.overlay addSubview:self.enlargedTile.view];
        [self.displayName setText:self.enlargedTile.data.value[@"user"]];
        
        [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/likes", DATA, self.enlargedTile.data.name]] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            [self renderLikes:snapshot];
        }];

        [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/likes/%@", DATA, self.enlargedTile.data.name, [self humanName]]] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            [self renderLikeButton:snapshot];
        }];
        
        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
            [self.overlay setAlpha:1.0];
            [self.likeButton setAlpha:0.5];
            [self.enlargedTile setVideoFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH*2, TILE_HEIGHT*2)];

            [self.enlargedTile.player setVolume:1.0];
        } completion:^(BOOL finished) {
            // add tap gesture recognizer for collapsing tile
        }];
    }
}

- (void) likePressed {
    if(self.liked){
        [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/likes/%@", DATA, self.enlargedTile.data.name, [self humanName]]] setValue:[NSNull null]];
    } else {
        [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/likes/%@", DATA, self.enlargedTile.data.name, [self humanName]]] setValue:@"1"];
    }
}

- (void)renderLikes:(FDataSnapshot *)snapshot {
    NSLog(@"%lu", (unsigned long)snapshot.childrenCount);
//    [self.likeCount setText:[NSString stringWithFormat:@"%lu", snapshot.childrenCount]];
}

- (void)renderLikeButton:(FDataSnapshot *)snapshot {
    if(snapshot.value != [NSNull null]){
        self.liked = 1;
    } else {
        self.liked = 0;
    }
    
    NSLog(@"%lu", (unsigned long)snapshot.childrenCount);
    
    [UIView animateKeyframesWithDuration:0.5 delay:0.0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
            [self.likeButton setTransform:self.liked?CGAffineTransformMakeScale(1.4, 1.4):CGAffineTransformMakeScale(0.7, 0.7)];
            [self.likeButton setAlpha:self.liked?1.0:0.5];
        }];
        [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
            [self.likeButton setTransform:CGAffineTransformIdentity];
        }];
    } completion:^(BOOL finished) {
        
    }];

}

- (void)closeButtonTapped {
    [self collapseTile];
}

- (void)overlayTapped {
    NSLog(@"overlay tapped");
    [self collapseTile];
}

- (void)collapseTile {
    int tileIndex = 0;
    
    //get tapped tile
    for(Tile *tile in self.tiles){
        if(tile == self.enlargedTile){
            break;
        }
        tileIndex++;
    }
    
    [self.view bringSubviewToFront:self.gridView];
    [self.enlargedTile.view removeFromSuperview];
    [self.gridView addSubview:self.enlargedTile.view];
    [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/likes", DATA, self.enlargedTile.data.name]] removeAllObservers];
    [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@/likes/%@", DATA, self.enlargedTile.data.name, [self humanName]]] removeAllObservers];

    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        //
        [self.overlay setAlpha:0.0];
        [self.enlargedTile.view setGridPosition:2+tileIndex];
        [self.enlargedTile.playerLayer setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
        [self.enlargedTile.playerContainer setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
        [self.enlargedTile.player setVolume:0.0];
    } completion:^(BOOL finished) {
        // set tap gesture recognizer
        UITapGestureRecognizer *tappedTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enlargeTile:)];
        [self.enlargedTile.view addGestureRecognizer:tappedTile];
        self.enlargedTile = nil;
//        [self layoutGrid];
    }];
}

//loop video when ends
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (void)initFirebase {
    self.firebase = [[[Firebase alloc] initWithUrl:@"https://pic6.firebaseIO.com"] childByAppendingPath:NODE_NAME];;
    
    [[[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", DATA]] queryLimitedToNumberOfChildren:NUM_TILES] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        [self newTile:snapshot];
    }];
}

- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL {
    // measure size of data
    NSLog(@"%@ size: %lu", type, (unsigned long)[data length]);

    // set up data object
    NSString *stringData = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    Firebase *dataObject = [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", MEDIA]] childByAutoId];
    [dataObject setValue:stringData];
    NSString *dataPath = dataObject.name;
    
    [dataObject setValue:stringData];// withCompletionBlock:^(NSError *error, Firebase *ref) {
    NSFileManager * fm = [[NSFileManager alloc] init];
    NSError *err = nil;
    [fm moveItemAtURL:outputURL toURL:[self movieUrlForSnapshotName:dataPath] error:&err];
    if(err){
        NSLog(@"error: %@", err);
    }
    
    //upload to reactions if enlarged tile, otherwise upload to main stream
    NSString *path;
    if(self.enlargedTile){
        path = [NSString stringWithFormat:@"%@/%@/%@", REACTIONS, self.enlargedTile.data.name, dataPath];
    } else {
        path = [NSString stringWithFormat:@"%@/%@", DATA, dataPath];
    }
    
    [[self.firebase childByAppendingPath:path] setValue:@{@"type": type, @"user":[self humanName]}];
}

- (IBAction)switchCamera:(id)sender { //switch cameras front and rear cameras
    if (self.FrontCamera == 1) {
        self.FrontCamera = 0;
    } else {
        self.FrontCamera = 1;
    }
    [self initCamera];
}

- (void)initCameraFrame {
    UIView *superView = [self.cameraView superview];
    [self.cameraView removeFromSuperview];
    self.cameraView = [[UIImageView alloc] initWithFrame:CGRectMake(TILE_WIDTH, 0, TILE_WIDTH, TILE_HEIGHT)];
    if(superView){
        [superView addSubview:self.cameraView];
    } else {
        [self.gridView addSubview:self.cameraView];
    }
    [self.gridView bringSubviewToFront:self.cameraView];
    
    [self.cameraView setUserInteractionEnabled:YES];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
    [longPressGestureRecognizer setMinimumPressDuration:0.2f];
    longPressGestureRecognizer.delegate = self;
    [self.cameraView addGestureRecognizer:longPressGestureRecognizer];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.delegate = self;
    [tapGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
//    [self.cameraView addGestureRecognizer:tapGestureRecognizer];

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
    [session addInput:input];
    
    //ADD AUDIO INPUT
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

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    [self capImage];
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
//            self uploadData:<#(NSData *)#> withType:<#(NSString *)#> withOutputURL:<#(NSURL *)#>
//            [self processImage:[UIImage imageWithData:imageData]];
        }
    }];
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

- (void)willEnterForeground {
    for(TileCell *tile in [self.gridTiles visibleCells]){
        if(tile.state == PLAYING){
            [tile play];
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
