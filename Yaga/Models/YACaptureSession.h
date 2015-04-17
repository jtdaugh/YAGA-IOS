//
//  YACaptureSession.h
//  Yaga
//
//  Created by Iegor Shapanov on 4/17/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YACaptureSession : NSObject
+ (YACaptureSession*)captureSession;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

- (void)closeCamera;
- (void)switchCamera;
- (void)startRecordingVideo;
- (void)stopRecordingVideo;
@end
