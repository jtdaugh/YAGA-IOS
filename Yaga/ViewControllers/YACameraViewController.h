//
//  YACameraViewController.h
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AVCamPreviewView.h"
#import "GPUImage.h"

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

@property (strong, nonatomic) AVCamPreviewView *cameraView; // to remove
@property (strong, nonatomic) GPUImageView *gpuCameraView;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput; // to remove
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput; // to remove

@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;

@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;

@property (weak, nonatomic) id<YACameraViewControllerDelegate> delegate;

- (void)showCameraAccessories:(BOOL)show;

- (void)enableRecording:(BOOL)enable;
- (void)updateCurrentGroupName;
- (void)enableScrollToTop:(BOOL)enable;

- (void)showBottomShadow;
- (void)removeBottomShadow;
@end
