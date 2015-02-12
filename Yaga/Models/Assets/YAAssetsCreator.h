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

typedef void (^cameraRollCompletion)(NSError *error);
typedef void (^stopOperationsCompletion)(void);

@interface YAAssetsCreator : NSObject

+ (instancetype)sharedCreator;

- (void)addBumberToVideoAtURLAndSaveToCameraRoll:(NSURL*)videoURL completion:(cameraRollCompletion)completion;

- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl addToGroup:(YAGroup*)group;
- (void)addGifCreationOperationForVideo:(YAVideo*)video quality:(YAGifCreationQuality)quality;
- (void)enqueueAssetsCreationJobForVideo:(YAVideo*)video prioritizeDownload:(BOOL)prioritize;

- (void)stopAllJobsWithCompletion:(stopOperationsCompletion)completion;

// on background
- (void)waitForAllOperationsToFinish;
@end
