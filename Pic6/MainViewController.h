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

@interface MainViewController : UIViewController<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>

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
@property int tickCount;

@property (strong, nonatomic) NSMutableArray *tiles;
@property (strong, nonatomic) UIView *gridView;

@property (strong, nonatomic) NSMutableDictionary *players;

@property (strong, nonatomic) UIView *carousel;
@property (strong, nonatomic) UIView *blackBG;
@property (strong, nonatomic) NSMutableArray *reactions;
@property int carouselPosition;

@property (strong, nonatomic) UIView *selectedTile;
@property (strong, nonatomic) UIButton *closeButton;
@property (strong, nonatomic) UILabel *displayName;

@property (strong, nonatomic) Tile *enlargedTile;
@property (strong, nonatomic) NSString *enlargedId;

@property (strong, nonatomic) Firebase *firebase;

@end
