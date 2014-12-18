//
//  YACameraViewController.h
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVPlayer+AVPlayer_Async.h"
#import "AVCamPreviewView.h"

@interface YACameraViewController : UIViewController<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>

- (void)switchFlashMode:(id)sender;
- (void)closeCamera;
- (void)initCamera:(void (^)())block;

@property (assign, nonatomic) BOOL flash;
@property (strong, nonatomic) AVCamPreviewView *cameraView;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;

@property (assign, nonatomic) id toggleGroupDelegate;
@property (assign, nonatomic) SEL toggleGroupSeletor;
@end
