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
- (void)showCreateGroup;
- (void)presentNewlyRecordedVideo:(YAVideo *)video;
@end

typedef NS_ENUM(NSUInteger, YACameraTopAccessoriesMode) {
    YACameraTopAccessoriesModeNone,
    YACameraTopAccessoriesModeHome,
    YACameraTopAccessoriesModeGrid
};

@interface YACameraViewController : UIViewController<UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<YACameraViewControllerDelegate> delegate;
@property (strong, nonatomic) NSNumber *recording;

- (void)showCameraAccessories:(BOOL)show;

- (void)enableRecording:(BOOL)enable;
- (void)enableScrollToTop:(BOOL)enable;

- (void)setCameraButtonMode:(YACameraTopAccessoriesMode)mode;

@end
