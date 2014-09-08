//
//  CameraViewController.h
//  Pic6
//
//  Created by Raj Vir on 8/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVCamPreviewView.h"
#import "CliquePageControl.h"
#import "SwipeView.h"
#import "TileCell.h"
@import AVFoundation;

@interface CameraViewController : UIViewController <AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate, SwipeViewDataSource, SwipeViewDelegate>

@property (strong, nonatomic) NSNumber *appeared;
@property (strong, nonatomic) NSNumber *setup;
@property (strong, nonatomic) NSNumber *notInitial;

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic) NSInteger vcIndex;
@property (strong, nonatomic) SwipeView *swipeView;

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

@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;

@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) UIView *plaque;
@property (nonatomic, strong) CliquePageControl *pageControl;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;

@property (strong, nonatomic) UIView *overlay;

- (void) presentOverlay:(TileCell *)tile;
- (void) collapse:(TileCell *)tile speed:(CGFloat)speed;

@end
