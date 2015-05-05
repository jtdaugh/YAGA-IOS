//
//  YAGIFOperation.h
//  Yaga
//
//  Created by valentinkovalski on 1/2/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "YAVideo.h"
#import "YAGroup.h"
#import "AFHTTPRequestOperation.h"

#define kGifWidth (200)
#define kGifFPS_HQ (30.f)
#define kGifFPS_LQ (4.f)
#define kGifPixellationSize (15.f)
#define kGifSpeed (1.5f)

typedef void (^videoConcatenationCompletion)(NSURL *filePath, NSError *error);
typedef void (^stopOperationsCompletion)(void);
typedef void (^jpgCompletion)(void);

@interface YAAssetsCreator : NSObject

+ (instancetype)sharedCreator;

- (void)addBumberToVideoAtURL:(NSURL*)videoURL completion:(videoConcatenationCompletion)completion;
- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl addToGroup:(YAGroup*)group;
- (void)createVideoFromSequenceOfURLs:(NSArray *)videoURLs addToGroup:(YAGroup*)group;
- (void)enqueueAssetsCreationJobForVisibleVideos:(NSArray*)visibleVideos invisibleVideos:(NSArray*)invisibleVideos;

- (void)stopAllJobsWithCompletion:(stopOperationsCompletion)completion;

// on background
- (void)waitForAllOperationsToFinish;

//
- (void)enqueueJpgCreationForVideo:(YAVideo*)video;
- (UIImage *)deviceSpecificCroppedThumbnailFromImage:(UIImage*)img;
- (void)cancelGifOperations;


@end
