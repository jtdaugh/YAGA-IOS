//
//  YACameraViewController.h
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AVCamPreviewView.h"

@protocol YACameraViewControllerDelegate <NSObject>
- (void)toggleGroups;
- (void)openGroupOptions;
- (void)scrollToTop;
@end

#define recordButtonWidth 60.0
@interface YACameraViewController : UIViewController<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>

- (void)switchFlashMode:(id)sender;
- (void)closeCamera;
- (void)initCamera;

@property (assign, nonatomic) BOOL flash;
@property (strong, nonatomic) AVCamPreviewView *cameraView;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;

@property (weak, nonatomic) id<YACameraViewControllerDelegate> delegate;

- (void)showCameraAccessories:(BOOL)show;

- (void)enableRecording:(BOOL)enable;
- (void)updateCurrentGroupName;
- (void)enableScrollToTop:(BOOL)enable;
@end
