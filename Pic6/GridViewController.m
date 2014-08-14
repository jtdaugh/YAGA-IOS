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
#import "OnboardingNavigationController.h"
#import "UIColor+Expanded.h"
#import <Crashlytics/Crashlytics.h>
#import <Parse/Parse.h>

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
    
    if([PFUser currentUser]){
        NSLog(@"current user is set in View Did Appear!");
        if(![self.appeared boolValue]){
            self.appeared = [NSNumber numberWithBool:YES];
            if(![self.setup boolValue]){
                [self setupView];
            }
        }
    } else {
        NSLog(@"poop. not logged in.");
        OnboardingNavigationController *vc = [[OnboardingNavigationController alloc] init];
        [self presentViewController:vc animated:NO completion:^{
            //
        }];
    }

////    [currentUser saveUserData:[NSNumber numberWithBool:NO] forKey:@"onboarded"];
//    CNetworking *currentUser = [CNetworking currentUser];
//
//    if([(NSNumber *)[currentUser userDataForKey:@"onboarded"] boolValue]){
//        if(![self.appeared boolValue]){
//            self.appeared = [NSNumber numberWithBool:YES];
//            if(![self.setup boolValue]){
//                [self setupView];
//            }
//        }
//    } else {
//        OnboardingNavigationController *vc = [[OnboardingNavigationController alloc] init];
//        [self presentViewController:vc animated:NO completion:^{
//            //
//        }];
//    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *redString = [[UIColor redColor] stringValue];
    
    UIColor *redColor = [UIColor colorWithString:redString];
    
    NSLog(@"red: %@", [redColor stringValue]);
    
    if([PFUser currentUser]){
        NSLog(@"current user is set!");
        [self setupView];
    }
//    [currentUser saveUserData:[NSNumber numberWithBool:NO] forKey:@"onboarded"];
//    
//    if([(NSNumber *)[currentUser userDataForKey:@"onboarded"] boolValue]){
//        [currentUser saveUserData:[NSNumber numberWithBool:YES] forKey:@"onboarded"];
//        [self setupView];
//    }
}

- (void)setupView {
    
    NSLog(@"setting up muthafuckas");
    
    self.setup = [NSNumber numberWithBool:YES];
    
    // Do any additional setup after loading the view.
    self.cameraAccessories = [[NSMutableArray alloc] init];
    NSError *error = nil;
    if(error){
        NSLog(@"error: %@", error);
    }
    NSLog(@"heyoo: %@", [self humanName]);
    [Crashlytics setUserIdentifier:[self humanName]];
    
    [self initOverlay];
    [self initGridView];
    [self initPlaque];
    [self initCameraView];
    [self initGridTiles];
    [self initLoader];
    [self initCamera:YES];
    // look at afterCameraInit to see what happens after the camera gets initialized. eg initFirebase.
    
    
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

- (void)afterCameraInit {
//    if(![[CNetworking currentUser] firebase]){
    [self initFirebase];
//    }
}

- (void)initPlaque {
    self.plaque = [[UIView alloc] init];
    [self.plaque setFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    [self.plaque setBackgroundColor:PRIMARY_COLOR];
    
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
    [cliqueButton addTarget:self action:@selector(manageClique:) forControlEvents:UIControlEventTouchUpInside];
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
    
    [self.gridView addSubview:self.plaque];
}

- (void)initGridView {
    self.gridView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT * 4)];
    [self.gridView setBackgroundColor:PRIMARY_COLOR];
    
    [self.view addSubview:self.gridView];
}

- (void) initGridTiles {
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
    
    self.gridData = [NSMutableArray array];
}

- (void) initLoader {
    NSLog(@"initing loader");
    UIView *loader = [[UIView alloc] initWithFrame:self.gridTiles.frame];
    [self.gridView insertSubview:loader belowSubview:self.gridTiles];
}

- (void) initOverlay {
    self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT*4)];
    [self.overlay setBackgroundColor:[UIColor blackColor]];
    [self.overlay setAlpha:0.0];

    [self.view addSubview:self.overlay];
}

- (void)initFirebase {

    NSString *hash = [PFUser currentUser][@"phoneHash"];
    NSString *escapedHash = [hash stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];

    [[[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@/%@", STREAM, escapedHash]] queryLimitedToNumberOfChildren:NUM_TILES] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"children count: %lu", snapshot.childrenCount);
        NSString *lastUid;
        for (FDataSnapshot* child in snapshot.children) {
            [self.gridData insertObject:child atIndex:0];
            lastUid = child.name;
        }
        [self.loader stopAnimating];
        [self.gridTiles reloadData];
        [self listenForChanges];
    }];
}

- (void)listenForChanges {
    
    //new child added
    NSString *hash = [PFUser currentUser][@"phoneHash"];
    NSString *escapedHash = [hash stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    
    [[[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@/%@", STREAM, escapedHash]] queryLimitedToNumberOfChildren:1] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
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
    
    [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
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

- (void) refreshTable {
    [self.pull endRefreshing];
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
//    cell.state = [NSNumber numberWithInt:LIMBO];
    
    if(![cell.uid isEqualToString:snapshot.name]){

        [cell setUid:snapshot.name];
        [cell setUsername:snapshot.value[@"user"]];
        
        NSArray *colors = (NSArray *) snapshot.value[@"colors"];
        
        [cell setColors:colors];
        
        if(cell.isLoaded){
            if([self.scrolling boolValue]){
//                [cell play];
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
    self.scrolling = [NSNumber numberWithBool:NO];
    [self scrollingEnded];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(!decelerate){
        self.scrolling = [NSNumber numberWithBool:NO];
        [self performSelector:@selector(scrollingEnded) withObject:self afterDelay:0.1];
    }
}

- (void)scrollingEnded {
    if(![self.scrolling boolValue]){
        for(TileCell *cell in [self.gridTiles visibleCells]){
            if([cell.state isEqualToNumber:[NSNumber numberWithInt: LOADED]]){
                [cell play];
            } else {
                
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TileCell *selected = (TileCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if([selected.state isEqualToNumber:[NSNumber numberWithInt:PLAYING]]) {
        if(selected.player.rate == 1.0){
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
        } else {
            [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
    } else {
        NSLog(@"state: %@", selected.state);
//        [collectionView reloadItemsAtIndexPaths:@[[collectionView indexPathForCell:selected]]];
    }
    
}

- (void) collapse:(TileCell *)tile speed:(CGFloat)speed {
    tile.frame = CGRectMake(0, self.gridTiles.contentOffset.y, TILE_WIDTH*2, TILE_HEIGHT*2);
    [self.gridTiles addSubview:tile];
    [self.overlay setAlpha:0.0];
//    [self.gridTiles addSubview:self.overlay];
    [UIView animateWithDuration:speed delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:0.7 options:0 animations:^{
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
            [self.gridView addSubview:self.white];
            [self.gridView bringSubviewToFront:self.cameraView];
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
    [self.gridView addSubview:self.cameraView];
    
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
    Firebase *dataObject = [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@", MEDIA]] childByAutoId];
    NSString *dataPath = dataObject.name;
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:outputURL options:nil];
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [imageGenerator setAppliesPreferredTrackTransform:YES];
//    UIImage* image = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMake(0,1) actualTime:nil error:nil];
    
    UIImage *image = [[UIImage imageWithCGImage:imageRef] imageScaledToFitSize:CGSizeMake(TILE_WIDTH*2, TILE_HEIGHT*2)];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
    NSString *imageString = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    NSArray *colors = [self getColors:image];
    
//    for(NSString *color in colors){
//        NSLog(@"color: %@", color);
//    }
    
    [dataObject setValue:@{@"video":videoData, @"thumb":imageString} withCompletionBlock:^(NSError *error, Firebase *ref) {
    }];
    
    NSMutableDictionary *clique = (NSMutableDictionary *)[PFUser currentUser][@"clique"];
    [clique setObject:@1 forKeyedSubscript:[PFUser currentUser][@"phoneHash"]];
    
    for(NSString *hash in clique){
        NSLog(@"hash: %@", hash);
        NSString *escapedHash = [hash stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSString *path = [NSString stringWithFormat:@"%@/%@/%@", STREAM, escapedHash, dataPath];
        [[[[CNetworking currentUser] firebase] childByAppendingPath:path] setValue:@{@"type": type, @"user":[self humanName], @"colors":colors}];
    }
    
    NSFileManager * fm = [[NSFileManager alloc] init];
    NSError *err = nil;
    [fm moveItemAtURL:outputURL toURL:[dataPath movieUrl] error:&err];
    [imageData writeToURL:[dataPath imageUrl] options:NSDataWritingAtomic error:&err];

    if(err){
        NSLog(@"error: %@", err);
    }
    
}

- (NSArray *) getColors: (UIImage *) image {
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    const UInt8* data = CFDataGetBytePtr(pixelData);
    
    NSLog(@"width: %f, height:%f", width, height);
    
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    for(int i = 0; i < 16; i++){
        int col = i % 4;
        int row = i / 4;
        
        CGFloat x = col * (width/4) + width/8;
        CGFloat y = row * (height/4) + height/8;
        
        NSLog(@"x: %f, y: %f", x, y);
        
        int pixelInfo = (int) ((width * y) + x) * 4;
        
        UInt8 blue = data[pixelInfo];         // If you need this info, enable it
        UInt8 green = data[(pixelInfo + 1)]; // If you need this info, enable it
        UInt8 red = data[pixelInfo + 2];    // If you need this info, enable it
        
        UIColor* color = [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:255.0f/255.0f]; // The pixel color info

        [colors addObject:[color hexStringValue]];
        NSLog(@"color as string: %@", [color closestColorName]);
    }
    
    return colors;
}

- (BOOL)isWallPixel: (UIImage *) image xCor: (int) x yCor:(int) y {
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    
    int pixelInfo = ((image.size.width  * y) + x ) * 4; // The image is png
    
    //UInt8 red = data[pixelInfo];         // If you need this info, enable it
    //UInt8 green = data[(pixelInfo + 1)]; // If you need this info, enable it
    //UInt8 blue = data[pixelInfo + 2];    // If you need this info, enable it
    UInt8 alpha = data[pixelInfo + 3];     // I need only this info for my maze game
    CFRelease(pixelData);
    
    //UIColor* color = [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha/255.0f]; // The pixel color info
    
    if (alpha) return YES;
    else return NO;
    
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
//    [self.view setAlpha:0.0];
    if([self.flash boolValue] && [[self.videoInput device] position] == AVCaptureDevicePositionFront){
        [self switchFlashMode:nil];
    }
    [self closeCamera];
    for(TileCell *tile in [self.gridTiles visibleCells]){
        if([tile.state isEqualToNumber:[NSNumber numberWithInt: PLAYING]]){
            tile.state = [NSNumber numberWithInt:LOADED];
            tile.player = nil;
            [tile.player removeObservers];
        }
    }
}

- (void)willEnterForeground {
//    NSLog(@"will enter foreground");
//    [self.view setAlpha:1.0];
    [self initCamera:0];
    [self.gridTiles reloadData];

//    for(TileCell *tile in [self.gridTiles visibleCells]){
//        if([tile.state isEqualToNumber:[NSNumber numberWithInt: PLAYING]] || [tile.state  isEqualToNumber:[NSNumber numberWithInt:  LOADED]]){
//            [tile play];
//        }
//    }
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"memory warning?");
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
