//
//  YACameraViewController.h
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AVCamPreviewView.h"

@protocol YAInviteCameraViewControllerDelegate <NSObject>
- (void)finishedRecordingVideoToURL:(NSURL *)videoURL;
- (void)beganHold;
- (void)endedHold;
@end

#define recordButtonWidth 60.0
@interface YAInviteCameraViewController : UIViewController<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>

- (void)switchFlashMode:(id)sender;
- (void)closeCamera;
- (void)initCamera;

@property (assign, nonatomic) BOOL flash;
@property (nonatomic) CGRect smallCameraFrame;
@property (strong, nonatomic) AVCamPreviewView *cameraView;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;

@property (nonatomic, weak)id<YAInviteCameraViewControllerDelegate> delegate;

- (void)showCameraAccessories:(BOOL)show;

- (void)enableRecording:(BOOL)enable;

@end
