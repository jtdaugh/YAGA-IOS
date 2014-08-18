//
//  MainViewController.h
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>
#import "AVCamPreviewView.h"
#import "TileCell.h"
#import "CNetworking.h"
#import "GridViewController.h"
@import AVFoundation;

@interface GroupViewController : GridViewController<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIApplicationDelegate, CNetworkingDelegate>

@property (strong, nonatomic) AVCamPreviewView *cameraView;
@property (strong, nonatomic) UIButton *cameraButton;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (strong, nonatomic) UIView *instructions;
@property (strong, nonatomic) UIView *indicator;
@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSNumber *recording;
@property (strong, nonatomic) NSNumber *FrontCamera;
@property (strong, nonatomic) NSNumber *flash;
@property (strong, nonatomic) NSNumber *previousBrightness;
@property (strong, nonatomic) NSMutableArray *cameraAccessories;

@property (strong, nonatomic) NSNumber *setup;
@property (strong, nonatomic) NSNumber *appeared;
@property (strong, nonatomic) NSNumber *onboarding;

@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;

@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) NSString *groupId;

@property (strong, nonatomic) UIView *gridView;
@property (strong, nonatomic) UICollectionView *gridTiles;
@property (strong, nonatomic) NSMutableArray *gridData;
@property (strong, nonatomic) NSNumber *scrolling;
@property (strong, nonatomic) UIRefreshControl *pull;
@property (strong, nonatomic) UIActivityIndicatorView *loader;

@property (strong, nonatomic) UIView *plaque;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;

@property (strong, nonatomic) UIView *overlay;

//@property (strong, nonatomic) Tile *enlargedTile;

@property (strong, nonatomic) Firebase *firebase;

@property (strong, nonatomic) TileCell *loaderTile;

- (void)collapse:(TileCell *)tile speed:(CGFloat)speed;

@end
