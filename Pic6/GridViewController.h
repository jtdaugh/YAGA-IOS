//
//  MainViewController.h
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>
#import "TileCell.h"
#import "CNetworking.h"
#import "AVCamPreviewView.h"
#import "ElevatorTableView.h"
#import "FBShimmeringView.h"

@interface GridViewController : UIViewController <AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIApplicationDelegate, CNetworkingDelegate, UITableViewDelegate>

@property (strong, nonatomic) NSNumber *setup;
@property (strong, nonatomic) NSNumber *appeared;
@property (strong, nonatomic) NSNumber *onboarding;

@property (strong, nonatomic) GroupInfo *groupInfo;

@property (strong, nonatomic) UIView *gridView;
@property (strong, nonatomic) UICollectionView *gridTiles;
@property (strong, nonatomic) NSMutableArray *gridData;
@property (strong, nonatomic) NSNumber *scrolling;
@property (strong, nonatomic) UIRefreshControl *pull;
@property (strong, nonatomic) UIActivityIndicatorView *loader;

@property FirebaseHandle valueQuery;
@property FirebaseHandle childQuery;

@property (strong, nonatomic) UIView *banner;

@property (strong, nonatomic) UIView *overlay;

@property (strong, nonatomic) Firebase *firebase;

@property (strong, nonatomic) TileCell *loaderTile;

@property (strong, nonatomic) UIButton *basketball;
@property (strong, nonatomic) ElevatorTableView *elevatorMenu;
@property (strong, nonatomic) NSNumber *elevatorOpen;

@property (strong, nonatomic) AVCamPreviewView *cameraView;
@property (strong, nonatomic) UIButton *cameraButton;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (strong, nonatomic) FBShimmeringView *instructions;
@property (strong, nonatomic) UIView *indicator;
@property (strong, nonatomic) UILabel *indicatorText;
@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSNumber *recording;
@property (strong, nonatomic) NSNumber *FrontCamera;
@property (strong, nonatomic) NSNumber *flash;
@property (strong, nonatomic) NSNumber *previousBrightness;
@property (strong, nonatomic) NSMutableArray *cameraAccessories;

@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;

@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;

- (void)collapse:(TileCell *)tile speed:(CGFloat)speed;

- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL;

- (void)initFirebase;

- (void)pagingStarted;
- (void)pagingEnded;
- (void)scrollingEnded;

- (void)conserveTiles;

- (void)configureGroupInfo:(GroupInfo *)groupInfo;

@end
