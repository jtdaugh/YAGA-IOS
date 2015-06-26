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

typedef NS_ENUM(NSUInteger, YACameraButtonMode) {
    YACameraButtonModeNoButtons,
    YACAmeraButtonModeFindAndCreate,
    YACameraButtonModeBackAndInfo
};

@interface YACameraViewController : UIViewController<UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<YACameraViewControllerDelegate> delegate;
@property (strong, nonatomic) NSNumber *recording;

- (void)showCameraAccessories:(BOOL)show;

- (void)enableRecording:(BOOL)enable;
- (void)enableScrollToTop:(BOOL)enable;

- (void)setCameraButtonMode:(YACameraButtonMode)mode;

@end
