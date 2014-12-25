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
@end

@interface YACameraViewController : UIViewController<UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>

- (void)switchFlashMode:(id)sender;
- (void)closeCamera;
- (void)initCamera:(void (^)())block;

@property (assign, nonatomic) BOOL flash;
@property (strong, nonatomic) AVCamPreviewView *cameraView;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;

@property (weak, nonatomic) id<YACameraViewControllerDelegate> delegate;

@property (strong, nonatomic) UIButton *recordButton;
@property (nonatomic, strong) UIButton *switchGroupsButton;
@end
