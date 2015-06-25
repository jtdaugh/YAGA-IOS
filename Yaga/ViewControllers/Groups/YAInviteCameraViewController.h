//
//  YACameraViewController.h
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "YACameraManager.h"

@protocol YAInviteCameraViewControllerDelegate <NSObject>
- (void)finishedRecordingVideoToURL:(NSURL *)videoURL;
- (void)beganHold;
- (void)endedHold;
@end

@interface YAInviteCameraViewController : UIViewController<UIGestureRecognizerDelegate>

@property (nonatomic) CGRect smallCameraFrame;
@property (strong, nonatomic) YACameraView *cameraView;

@property (nonatomic, weak)id<YAInviteCameraViewControllerDelegate> delegate;

- (void)showCameraAccessories:(BOOL)show;

- (void)enableRecording:(BOOL)enable;

@end
