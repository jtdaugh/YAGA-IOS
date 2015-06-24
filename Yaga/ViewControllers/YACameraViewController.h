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
- (void)openGroupOptions;
- (void)scrollToTop;
- (void)backPressed;
- (void)presentNewlyRecordedVideo:(YAVideo *)video;
@end

#define recordButtonWidth 60.0
@interface YACameraViewController : UIViewController<UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<YACameraViewControllerDelegate> delegate;
@property (strong, nonatomic) NSNumber *recording;

- (void)showCameraAccessories:(BOOL)show;

- (void)enableRecording:(BOOL)enable;
- (void)updateCurrentGroupName;
- (void)enableScrollToTop:(BOOL)enable;

- (void)showBottomShadow;
- (void)removeBottomShadow;

- (void)updateCameraAccessories;
@end
