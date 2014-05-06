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

@property (strong, nonatomic) UIView *gridView;
@property (strong, nonatomic) NSMutableArray *gridTiles;
@property (strong, nonatomic) NSMutableArray *gridData;

@property (strong, nonatomic) NSMutableDictionary *players;

@property (strong, nonatomic) UIView *selectedTile;
@property (strong, nonatomic) UIView *overlay;
@property (strong, nonatomic) UILabel *displayName;
@property (strong, nonatomic) NSMutableDictionary *enlarged;

@property (strong, nonatomic) Firebase *firebase;

@end
