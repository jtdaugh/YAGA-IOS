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
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    [logo setImage:[UIImage imageNamed:@"Logo"]];
    [self.plaque addSubview:logo];

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
    
    [self.gridView addSubview:self.loader];
    
    self.loaderTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                     target:self
                                   selector:@selector(loaderTick:)
                                   userInfo:nil
                                    repeats:YES];
    self.loading = 1;
    self.tickCount = 0;
}

- (void)loaderTick:(NSTimer *) timer {
//    int positions[] = {0,1,4,3,2,1,4,5};
//    int positions[] = {3,5,4,6,7,5,4,2};
    int positions[] = {1,3,2,4,5,3,2,0};
    int count = 8;
    
    for(int i = 0; i < NUM_TILES; i++){
//        float val = ((float)arc4random() / ARC4RANDOM_MAX);
        [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)([UIColor colorWithRed:((float)arc4random() / ARC4RANDOM_MAX) green:((float)arc4random() / ARC4RANDOM_MAX) blue:((float)arc4random() / ARC4RANDOM_MAX) alpha:0.5])];
//        if(i == (int) positions[self.tickCount % count]){// if i == root
//            [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)([UIColor colorWithWhite:1.0 alpha:0.5])];
//        } else if (i == (int) positions[(self.tickCount - 1) % count]){
//            [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)([UIColor colorWithWhite:1.0 alpha:0.25])];
//        } else if (i == (int) positions[(self.tickCount - 2) % count]){
//            [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)([UIColor colorWithWhite:1.0 alpha:0.125])];
//        } else {
//            [self.loaderTiles[i] setBackgroundColor:(__bridge CGColorRef)(PRIMARY_COLOR)];
//        }
    }
    self.tickCount = self.tickCount + 1;
}

- (void) doneLoading {
    [self.loaderTimer invalidate];
    [self.loader removeFromSuperview];
}

- (void)initGridView {
    self.gridView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT * 4)];
    
    self.carousel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT*4)];
    [self.carousel setBackgroundColor:[UIColor clearColor]];
    [self.carousel setAlpha:0.0];
    
    self.carouselText = [[UILabel alloc] initWithFrame:CGRectMake(0, TILE_WIDTH * 3, VIEW_WIDTH, 40)];
    [self.carousel addSubview:self.carouselText];
    [self.carouselText setText:@"Swipe Through Reactions 😮"];
    [self.carouselText setTextColor:[UIColor whiteColor]];
    [self.carouselText setTextAlignment:NSTextAlignmentCenter];
    
    self.scroller = [[UIScrollView alloc] initWithFrame:CGRectMake(CAROUSEL_GUTTER, TILE_HEIGHT + 16, ENLARGED_WIDTH + CAROUSEL_MARGIN, ENLARGED_HEIGHT)];
    [self.scroller setClipsToBounds:NO];
    [self.scroller setContentSize:CGSizeMake((ENLARGED_WIDTH + CAROUSEL_MARGIN), ENLARGED_HEIGHT)];
    [self.scroller setScrollEnabled:YES];
    [self.scroller setPagingEnabled:YES];
    [self.scroller setShowsHorizontalScrollIndicator:NO];
    [self.scroller setShowsVerticalScrollIndicator:NO];
    self.scroller.delegate = self;
    [self.carousel addSubview:self.scroller];
    
    self.blackBG = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT*4)];
    [self.blackBG setBackgroundColor:[UIColor blackColor]];
    [self.blackBG setAlpha:0.0];
    
    self.reactionPlaque = [[UIView alloc] init];
    [self.reactionPlaque setGridPosition:0];
    UIImageView *reactionLogo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    [reactionLogo setImage:[UIImage imageNamed:@"ReactionPlaque"]];
    [self.reactionPlaque addSubview:reactionLogo];
    [self.reactionPlaque setAlpha:0.0];
    
    UITapGestureRecognizer *collapseTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collapseTile)];
    [self.reactionPlaque addGestureRecognizer:collapseTile];
    
    [self.carousel addSubview:self.reactionPlaque];

    self.displayName = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, TILE_WIDTH, 40)];
    [self.displayName setTextAlignment:NSTextAlignmentCenter];
    [self.displayName setTextColor:[UIColor whiteColor]];
    [self.displayName setFont:[UIFont systemFontOfSize:24]];
    
    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, TILE_WIDTH-40, TILE_HEIGHT - 40)];
    [self.closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.carousel addSubview:self.blackBG];
    [self.carousel addSubview:self.closeButton];
    [self.view addSubview:self.carousel];
    [self.view addSubview:self.gridView];
    self.tiles = [NSMutableArray array];
    self.reactions = [NSMutableArray array];
    
}

- (NSURL *) movieUrlForSnapshotName:(NSString *)name {
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), name];
    NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
    return movieURL;
}

- (void)newGridTile:(FDataSnapshot *)snapshot {
    Tile *tile = [[Tile alloc] init];
    tile.data = snapshot;
    tile.view = [[UIView alloc] init];
    [tile.view setGridPosition:0];
//    tile.loader = [[LoaderTileView alloc] initWithFrame:tile.view.frame];
//    [tile.view addSubview:tile.loader];
    [self.gridView addSubview:tile.view];
    [self.tiles insertObject:tile atIndex:0];
    
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), snapshot.name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:moviePath]){
        
        NSLog(@"the file does not exist!");
        
        [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, snapshot.name]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            [self newGridData:snapshot];
        }];
    }
    
    [self layoutGrid];
}

- (void) newGridData:(FDataSnapshot *)snapshot {

    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), snapshot.name];
    NSURL *movieURL = [self movieUrlForSnapshotName:snapshot.name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:moviePath])
    {
        NSError *error = nil;
        if(snapshot.value != [NSNull null]){
            
            NSData *videoData = [[NSData alloc] initWithBase64EncodedString:snapshot.value options:NSDataBase64DecodingIgnoreUnknownCharacters];
            
            if(videoData != nil){
                [videoData writeToURL:movieURL options:NSDataWritingAtomic error:&error];
            }            
        } else {
            
        }
    }

    [self layoutGrid];
}

- (void)newCarouselTile:(FDataSnapshot *)snapshot {
    Tile *tile = [[Tile alloc] init];
    tile.data = snapshot;
    
    tile.view = [[UIView alloc] init];
    
    [self.scroller addSubview:tile.view];
    [self.reactions addObject:tile];
    
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), snapshot.name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:moviePath]){
        
        NSLog(@"the file does not exist: %@", snapshot.value);
        
        [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, snapshot.name]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            [self newCarouselData:snapshot];
        }];
    }
    
    [self layoutCarousel];
}

- (void) newCarouselData:(FDataSnapshot *)snapshot {
    
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), snapshot.name];
    NSURL *movieURL = [self movieUrlForSnapshotName:snapshot.name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:moviePath])
    {
        NSError *error = nil;
        
        NSData *videoData = [[NSData alloc] initWithBase64EncodedString:snapshot.value options:NSDataBase64DecodingIgnoreUnknownCharacters];
        [videoData writeToURL:movieURL options:NSDataWritingAtomic error:&error];
    }
    
    [self layoutCarousel];
}

- (void) layoutCarousel {
    
    int i = 0;
    for(Tile *tile in self.reactions){
        if(!tile.player){
            NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), tile.data.name];
            NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:moviePath]){
                
                // init video player
                AVPlayer *player = [AVPlayer playerWithURL:movieURL];
                AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
                [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                
                // set video sizing
                UIView *playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ENLARGED_WIDTH, ENLARGED_HEIGHT)];
                playerLayer.frame = playerContainer.frame;
                
                // play video in frame
                [playerContainer.layer addSublayer: playerLayer];
                [tile.view addSubview:playerContainer];
                //                [tile.loader removeFromSuperview];
                
                // mute and play
                [player setVolume:0.0];
                [player play];
                
                // set looping
                [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:[player currentItem]];
                
//                // set tap gesture recognizer
//                UITapGestureRecognizer *tappedTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enlargeTile:)];
//                [tile.view addGestureRecognizer:tappedTile];
                
                // set video view pointers for later use (when resizing)
                tile.player = player;
                tile.playerLayer = playerLayer;
                tile.playerContainer = playerContainer;
                
//                [tile setCarouselPosition:5];
            }
        }
        
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            //
            [tile setCarouselPosition:i];
//            [tile setCarouselPosition:self.carouselPosition withIndex:i];
        } completion:^(BOOL finished) {
            //
//            [self.scroller setContentSize:CGSizeMake(ENLARGED_WIDTH*5, ENLARGED_HEIGHT)];
            [self.scroller setContentSize:CGSizeMake((ENLARGED_WIDTH + CAROUSEL_MARGIN)*[self.reactions count], ENLARGED_HEIGHT)];
        }];
        i++;
    }
    
    if([self.reactions count] > 1){
        [UIView animateWithDuration:0.3 animations:^{
            [self.carouselText setAlpha:1.0];
        }];
    }
    
    NSLog(@"%i", i);
    
}

- (void) layoutGrid {
    //iterate through tiles and positions
    // set proper frame
    //
    int i = 0;
    for(Tile *tile in self.tiles){
        if(!tile.player){
            NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), tile.data.name];
            NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:moviePath]){
                
                // init video player
                AVPlayer *player = [AVPlayer playerWithURL:movieURL];
                AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
                [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                
                // set video sizing
                UIView *playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
                playerLayer.frame = playerContainer.frame;
                
                // play video in frame
                [playerContainer.layer addSublayer: playerLayer];
                [tile.view addSubview:playerContainer];
                //                [tile.loader removeFromSuperview];
                
                // mute and play
                [player setVolume:0.0];
                [player play];
                
                // set looping
                [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:[player currentItem]];
                
                // set tap gesture recognizer
                UITapGestureRecognizer *tappedTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enlargeTile:)];
                [tile.view addGestureRecognizer:tappedTile];
                
                // set video view pointers for later use (when resizing)
                tile.player = player;
                tile.playerLayer = playerLayer;
                tile.playerContainer = playerContainer;
            }
        }
        if(!self.enlargedTile){
            [tile.view setGridPosition:i + 2];
        }
        i++;
    }
    
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
        
        [self.reactions insertObject:self.enlargedTile atIndex:0];
        
        [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@", REACTIONS, self.enlargedTile.data.name]] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            [self newCarouselTile:snapshot];
        }];
        
        
        //remove gesture recognizers
        for (UIGestureRecognizer *recognizer in self.enlargedTile.view.gestureRecognizers) {
            [self.enlargedTile.view removeGestureRecognizer:recognizer];
        }
        
        //resize tile
        [self.view bringSubviewToFront:self.carousel];
        [self.enlargedTile.view removeFromSuperview];
        [self.cameraView removeFromSuperview];
        [self.switchButton removeFromSuperview];
        [self.carousel setAlpha:1.0];
        [self.carousel addSubview:self.cameraView];
        [self.carousel bringSubviewToFront:self.reactionPlaque];
        [self.carousel bringSubviewToFront:self.scroller];
        [self.carousel bringSubviewToFront:self.carouselText];
        [self.reactionPlaque addSubview:self.switchButton];
        [self.scroller addSubview:self.enlargedTile.view];
        [self.scroller setContentOffset:CGPointZero animated:NO];
        [self.scroller setContentSize:CGSizeMake((ENLARGED_WIDTH + CAROUSEL_MARGIN)*[self.reactions count], ENLARGED_HEIGHT)];
        self.carouselPosition = 0;

        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
            [self.blackBG setAlpha:1.0];
            [self.reactionPlaque setAlpha:1.0];
            [self.enlargedTile setCarouselPosition:0];

            [self.enlargedTile.player setVolume:1.0];
        } completion:^(BOOL finished) {
            UISwipeGestureRecognizer* swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
            swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
            
            UISwipeGestureRecognizer* swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
            swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
            
//            [self.enlargedTile.view addGestureRecognizer:swipeRightGestureRecognizer];
//            [self.enlargedTile.view addGestureRecognizer:swipeLeftGestureRecognizer];
            //
        }];
        
    }
}

- (void)closeButtonTapped {
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
    [self.cameraView removeFromSuperview];
    [self.switchButton removeFromSuperview];
    [self.gridView addSubview:self.cameraView];
    [self.gridView addSubview:self.enlargedTile.view];
    [self.plaque addSubview:self.switchButton];

    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        //
        [self.blackBG setAlpha:0.0];
        [self.enlargedTile.view setGridPosition:2+tileIndex];
        [self.enlargedTile.playerLayer setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
        [self.enlargedTile.playerContainer setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
        [self.enlargedTile.player setVolume:0.0];
        [self.reactions removeObjectAtIndex:0];
        for(Tile *tile in self.reactions){
            [tile.player setVolume:0.0];
            [tile.view removeFromSuperview];
        }
        [self.reactions removeAllObjects];
        [self.carousel setAlpha:0.0];
        [self.carouselText setAlpha:0.0];
    } completion:^(BOOL finished) {
        // set tap gesture recognizer
        UITapGestureRecognizer *tappedTile = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enlargeTile:)];
        [self.enlargedTile.view addGestureRecognizer:tappedTile];
        self.enlargedTile = nil;
        [self layoutGrid];
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
        
        [self newGridTile:snapshot];
        if(self.loading){
            self.loading = 0;
            [self doneLoading];
        }
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
    [self initCameraFrame];
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
    [self.gridView bringSubviewToFront:self.gridView];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
    [longPressGestureRecognizer setMinimumPressDuration:0.2f];
    longPressGestureRecognizer.delegate = self;
    [self.cameraView addGestureRecognizer:longPressGestureRecognizer];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.cameraView setUserInteractionEnabled:YES];
    tapGestureRecognizer.delegate = self;
    [tapGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
    
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
    for(Tile *tile in self.tiles){
        if(tile.player){
            [tile.player play];
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
