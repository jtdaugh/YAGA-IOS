//
//  YACameraManager.h
//  Yaga
//
//  Created by Jesse on 6/21/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

typedef void (^YARecordingCompletionBlock)(NSURL *outputUrl);
typedef void (^YAPostCaptureCompletionBlock)(NSURL *outputUrl, NSTimeInterval duration, UIImage *firstFrameImage);

@interface YACameraView : GPUImageView
// Just fo abstraction
@end

@protocol YACameraManagerDelegate <NSObject>

- (void)setFrontFacingFlash:(BOOL)showFlash;

@end

@interface YACameraManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, weak) id<YACameraManagerDelegate> delegate;

- (void)initCamera;
- (void)pauseCameraAndStop:(BOOL)stop;
- (void)resumeCameraAndNeedsRestart:(BOOL)restart;
- (void)stopContiniousRecordingAndPrepareOutput:(BOOL)prepareOutput completion:(YAPostCaptureCompletionBlock)completion;
- (void)switchCamera;
- (void)forceFrontFacingCamera; // probably only used by inviteVC right meow
- (void)toggleFlash:(BOOL)flashOn;

- (void)setCameraView:(YACameraView *)cameraView;

@end
