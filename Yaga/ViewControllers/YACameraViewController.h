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
@end

#define recordButtonWidth 60.0
@interface YACameraViewController : UIViewController<UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<YACameraViewControllerDelegate> delegate;

- (void)showCameraAccessories:(BOOL)show;

- (void)enableRecording:(BOOL)enable;
- (void)updateCurrentGroupName;
- (void)enableScrollToTop:(BOOL)enable;

- (void)showBottomShadow;
- (void)removeBottomShadow;
@end
