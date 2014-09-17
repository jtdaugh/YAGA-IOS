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
#import "CliquePageControl.h"
#import "OnboardingNavigationController.h"
#import "OverlayViewController.h"

@interface CameraViewController ()

@end

@implementation CameraViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    if([PFUser currentUser]){
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
}

- (void)viewDidLoad
{
    NSLog(@"test!!!");
    
    [super viewDidLoad];
    if([PFUser currentUser]){
        [self setupView];
    }
    
    [self.view setBackgroundColor:SECONDARY_COLOR];
    
}

- (void)setupView {
    self.setup = [NSNumber numberWithBool:YES];
    // Do any additional setup after loading the view.
    self.cameraAccessories = [[NSMutableArray alloc] init];
    NSError *error = nil;
    if(error){
        NSLog(@"error: %@", error);
    }
    
//    [self initPlaque];
    [self initCameraView];
    [self initCamera:YES];
    [self initOverlay];
    
    NSLog(@"watup");
    
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
    [self setupGroups];

}

- (void) initOverlay {
    self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT*4)];
    [self.overlay setBackgroundColor:[UIColor blackColor]];
    [self.overlay setAlpha:0.0];
    
    [self.view addSubview:self.overlay];
}

- (void)presentOverlay:(TileCell *)tile {
    GroupViewController *groupView = (GroupViewController *) self.swipeView.currentItemView;
    tile.frame = CGRectMake(tile.frame.origin.x, tile.frame.origin.y - groupView.gridTiles.contentOffset.y + TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT);
    [self.view bringSubviewToFront:self.overlay];
    [self.overlay addSubview:tile];

    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        [self.overlay setAlpha:1.0];
        [tile.player setVolume:1.0];
        [tile setVideoFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH*2, TILE_HEIGHT*2)];
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
    GroupViewController *currentGroup = (GroupViewController *) self.swipeView.currentItemView;
    
    tile.frame = CGRectMake(0, currentGroup.gridTiles.contentOffset.y, TILE_WIDTH*2, TILE_HEIGHT*2);
    [currentGroup.gridTiles addSubview:tile];
    [self.overlay setAlpha:0.0];
    //    [self.gridTiles addSubview:self.overlay];
    [UIView animateWithDuration:speed delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:0.7 options:0 animations:^{
        NSIndexPath *ip = [currentGroup.gridTiles indexPathForCell:tile];
        [tile setVideoFrame:[currentGroup.gridTiles layoutAttributesForItemAtIndexPath:ip].frame];
        //
    } completion:^(BOOL finished) {
        //
    }];
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
            
            // fetch group meta data
            NSString *dataPath = [NSString stringWithFormat:@"groups/%@/data", child.name];
            NSLog(@"datapath: %@", dataPath);
            
            [[currentUser.firebase childByAppendingPath:dataPath] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
                
                // saving group data
                GroupInfo *info = [[GroupInfo alloc] init];
                info.name = dataSnapshot.value[@"name"];
                info.groupId = child.name;
                info.members = [[NSMutableArray alloc] init];
                
                for(NSString *member in dataSnapshot.value[@"members"]){
                    [info.members addObject:member];
                }
                
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
    
    self.swipeView = [[SwipeView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT*2, VIEW_WIDTH, VIEW_HEIGHT-TILE_HEIGHT*2)];
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
    [self.view addSubview:self.swipeView];
    
    CliquePageControl *pageControl = [[CliquePageControl alloc] init];
    [pageControl setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    pageControl.currentPage = 0;
    pageControl.numberOfPages = [[[CNetworking currentUser] groupInfo] count];
    [self.view addSubview:pageControl];
    self.pageControl = pageControl;
        
    NSDictionary *views = NSDictionaryOfVariableBindings(pageControl);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageControl]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[pageControl]|" options:0 metrics:nil views:views]];

}

#pragma mark - SwipeViewDataSource Method

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    //return the total number of items in the carousel
    return [[[CNetworking currentUser] groupInfo] count];
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView {
    return swipeView.frame.size;
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    CNetworking *currentUser = [CNetworking currentUser];
    GroupViewController *groupViewController;
    GroupInfo *groupInfo = [[currentUser groupInfo] objectAtIndex:index];
    
    NSLog(@"view for item at index: %lu, reuse: %@", index, view?@"true":@"false");
    
    if(view){
        groupViewController = (GroupViewController *) view;
        [groupViewController configureGroupInfo:groupInfo];
    } else {
        groupViewController = [[GroupViewController alloc] initWithFrame:swipeView.frame];
        groupViewController.cameraViewController = self;
        [groupViewController configureGroupInfo:groupInfo];
        
    }
    
    [groupViewController.detailView flash];
    
    NSLog(@"groupInfo: %@", groupInfo.name);
    if([self.notInitial boolValue]){
        [groupViewController setScrolling:[NSNumber numberWithBool:YES]];
    } else {
        NSLog(@"not initial");
        self.notInitial = [NSNumber numberWithBool:YES];
    }
    
    return groupViewController;
}

#pragma mark - SwipeViewDelegate Method

- (void)swipeViewWillBeginDragging:(SwipeView *)swipeView {
    [(GroupViewController *)swipeView.currentItemView setScrolling:[NSNumber numberWithBool:YES]];    
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView {
    self.pageControl.currentPage = swipeView.currentItemIndex;
}

- (void)swipeViewDidEndDragging:(SwipeView *)swipeView willDecelerate:(BOOL)decelerate {
    if(!decelerate){
        [self doneScrolling];
    }
}

- (void)swipeViewDidEndDecelerating:(SwipeView *)swipeView {
    [self doneScrolling];
}

- (void)doneScrolling {
    [(GroupViewController *)self.swipeView.currentItemView setScrolling:[NSNumber numberWithBool:NO]];
    [(GroupViewController *)self.swipeView.currentItemView scrollingEnded];
}

#pragma mark -
#pragma mark - Camera Shit

- (void)afterCameraInit {
    //    if(![[CNetworking currentUser] firebase]){
    //    [self initFirebase];
    //    }
}

- (void)initPlaque {
    UIView *plaque = [[UIView alloc] init];
    plaque.translatesAutoresizingMaskIntoConstraints = NO;
    plaque.backgroundColor = PRIMARY_COLOR;
    [self.view addSubview:plaque];
    self.plaque = plaque;
    
//    UILabel *text = [[UILabel alloc] init];
//    text.translatesAutoresizingMaskIntoConstraints = NO;
//    text.adjustsFontSizeToFitWidth = YES;
//    text.textAlignment = NSTextAlignmentCenter;
//    [text setTextColor:[UIColor whiteColor]];
//    [text setFont:[UIFont fontWithName:BIG_FONT size:25]];
//    [text sizeToFit];
//    [self.plaque addSubview:text];
//    self.text = text;
//    

    UIView *topLeftContainer = [[UIView alloc] init];
    topLeftContainer.translatesAutoresizingMaskIntoConstraints = NO;
    topLeftContainer.backgroundColor = self.plaque.backgroundColor;
    [self.plaque addSubview:topLeftContainer];
    
    UIView *topRightContainer = [[UIView alloc] init];
    topRightContainer.translatesAutoresizingMaskIntoConstraints = NO;
    topRightContainer.backgroundColor = PRIMARY_COLOR_ACCENT;
    [self.plaque addSubview:topRightContainer];
    
    UIView *bottomLeftContainer = [[UIView alloc] init];
    bottomLeftContainer.translatesAutoresizingMaskIntoConstraints = NO;
    bottomLeftContainer.backgroundColor = topRightContainer.backgroundColor;
    [self.plaque addSubview:bottomLeftContainer];
    
    UIView *bottomRightContainer = [[UIView alloc] init];
    bottomRightContainer.translatesAutoresizingMaskIntoConstraints = NO;
    bottomRightContainer.backgroundColor = topLeftContainer.backgroundColor;
    [self.plaque addSubview:bottomRightContainer];
    
    UIButton *addButton = [[UIButton alloc] init];
    addButton.translatesAutoresizingMaskIntoConstraints = NO;
    [addButton addTarget:self action:@selector(createGroup) forControlEvents:UIControlEventTouchUpInside];
    [addButton setImage:[UIImage imageNamed:@"Addv2"] forState:UIControlStateNormal];
    [addButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [topLeftContainer addSubview:addButton];
    
    UIButton *switchButton = [[UIButton alloc] init];
    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [switchButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.cameraAccessories addObject:switchButton];
    [topRightContainer addSubview:switchButton];
    self.switchButton = switchButton;
    
    UIButton *cliqueButton = [[UIButton alloc] init];
    cliqueButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cliqueButton addTarget:self action:@selector(manageClique) forControlEvents:UIControlEventTouchUpInside];
    [cliqueButton setImage:[UIImage imageNamed:@"Clique"] forState:UIControlStateNormal];
    [cliqueButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [bottomLeftContainer addSubview:cliqueButton];
    
    UIButton *flashButton = [[UIButton alloc] init];
    flashButton.translatesAutoresizingMaskIntoConstraints = NO;
    [flashButton addTarget:self action:@selector(switchFlashMode:) forControlEvents:UIControlEventTouchUpInside];
    [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.cameraAccessories addObject:flashButton];
    [bottomRightContainer addSubview:flashButton];
    self.flashButton = flashButton;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(plaque, topLeftContainer, topRightContainer, bottomLeftContainer, bottomRightContainer, addButton, switchButton, cliqueButton, flashButton);
    NSDictionary *trix = @{@"TILE_WIDTH":@(TILE_WIDTH), @"TILE_HEIGHT":@(TILE_HEIGHT), @"HALF_WIDTH":@(TILE_WIDTH/2), @"HALF_HEIGHT":@(TILE_HEIGHT/2)};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[plaque(TILE_WIDTH)]" options:0 metrics:trix views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[plaque(TILE_HEIGHT)]" options:0 metrics:trix views:views]];
    [self.plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[topLeftContainer(HALF_WIDTH)]" options:0 metrics:trix views:views]];
    [self.plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLeftContainer(HALF_HEIGHT)]" options:0 metrics:trix views:views]];
    [self.plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[topRightContainer(HALF_WIDTH)]|" options:0 metrics:trix views:views]];
    [self.plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topRightContainer(HALF_HEIGHT)]" options:0 metrics:trix views:views]];
    [self.plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomLeftContainer(HALF_WIDTH)]" options:0 metrics:trix views:views]];
    [self.plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomLeftContainer(HALF_HEIGHT)]|" options:0 metrics:trix views:views]];
    [self.plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[bottomRightContainer(HALF_WIDTH)]|" options:0 metrics:trix views:views]];
    [self.plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomRightContainer(HALF_HEIGHT)]|" options:0 metrics:trix views:views]];
    
    [topLeftContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[addButton(HALF_WIDTH)]" options:0 metrics:trix views:views]];
    [topLeftContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[addButton(HALF_HEIGHT)]" options:0 metrics:trix views:views]];
    [topLeftContainer addConstraint:[NSLayoutConstraint constraintWithItem:addButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:topLeftContainer attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [topLeftContainer addConstraint:[NSLayoutConstraint constraintWithItem:addButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:topLeftContainer attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    [topRightContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[switchButton(HALF_WIDTH)]" options:0 metrics:trix views:views]];
    [topRightContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[switchButton(HALF_HEIGHT)]" options:0 metrics:trix views:views]];
    [topRightContainer addConstraint:[NSLayoutConstraint constraintWithItem:switchButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:topRightContainer attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [topRightContainer addConstraint:[NSLayoutConstraint constraintWithItem:switchButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:topRightContainer attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    [bottomLeftContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[cliqueButton(HALF_WIDTH)]" options:0 metrics:trix views:views]];
    [bottomLeftContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[cliqueButton(HALF_HEIGHT)]" options:0 metrics:trix views:views]];
    [bottomLeftContainer addConstraint:[NSLayoutConstraint constraintWithItem:cliqueButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:bottomLeftContainer attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [bottomLeftContainer addConstraint:[NSLayoutConstraint constraintWithItem:cliqueButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:bottomLeftContainer attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    [bottomRightContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[flashButton(HALF_WIDTH)]" options:0 metrics:trix views:views]];
    [bottomRightContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[flashButton(HALF_HEIGHT)]" options:0 metrics:trix views:views]];
    [bottomRightContainer addConstraint:[NSLayoutConstraint constraintWithItem:flashButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:bottomRightContainer attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [bottomRightContainer addConstraint:[NSLayoutConstraint constraintWithItem:flashButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:bottomRightContainer attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
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
    
    GroupInfo *groupInfo = [(GroupViewController *)[self.swipeView currentItemView] groupInfo];
    NSLog(@"members: %@", groupInfo.members);
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
    self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH*2, TILE_HEIGHT*2)];
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
    
    CGFloat size = 50;
    UIButton *switchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width-size-20, 10, size, size)];
//    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [switchButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.cameraAccessories addObject:switchButton];
    self.switchButton = switchButton;
    [self.cameraView addSubview:self.switchButton];
    
    UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, size, size)];
//    flashButton.translatesAutoresizingMaskIntoConstraints = NO;
    [flashButton addTarget:self action:@selector(switchFlashMode:) forControlEvents:UIControlEventTouchUpInside];
    [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.cameraAccessories addObject:flashButton];
    self.flashButton = flashButton;
    [self.cameraView addSubview:self.flashButton];

    
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
        [self.indicator setFrame:CGRectMake(0, 0, self.cameraView.frame.size.width, TILE_HEIGHT/4)];
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
        
        GroupViewController *groupViewController = (GroupViewController *)[self.swipeView currentItemView];
        
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

    for(GroupViewController *gridView in [self.swipeView visibleItemViews]){
        [gridView conserveTiles];
    }
}

- (void)willResignActive {
    
}

- (void)willEnterForeground {
    [self initCamera:0];
    for(GroupViewController *gridView in [self.swipeView visibleItemViews]){
        [gridView.gridTiles reloadData];
    }
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
