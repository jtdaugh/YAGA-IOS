//
//  MainViewController.h
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Firebase/Firebase.h>
#import "Tile.h"

@interface MainViewController : UIViewController<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) UIView *cameraView;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (strong, nonatomic) UIView *indicator;
@property BOOL recording;

@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) UIView *loader;
@property (strong, nonatomic) NSMutableArray *loaderTiles;
@property (strong, nonatomic) NSTimer *loaderTimer;
@property BOOL loading;

@property (strong, nonatomic) NSMutableArray *tiles;
@property (strong, nonatomic) UIView *gridView;
@property (strong, nonatomic) UICollectionView *gridTiles;
@property (strong, nonatomic) NSMutableArray *gridData;

@property (strong, nonatomic) UIView *plaque;
@property (strong, nonatomic) UIButton *switchButton;

@property (strong, nonatomic) UIView *overlay;
@property (strong, nonatomic) UILabel *displayName;
@property (strong, nonatomic) UIButton *likeButton;
@property (strong, nonatomic) UILabel *likeCount;

@property (strong, nonatomic) Tile *enlargedTile;

@property (strong, nonatomic) Firebase *firebase;

@end
