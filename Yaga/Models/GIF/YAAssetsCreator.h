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

typedef void (^cameraRollCompletion)(NSError *error);

@interface YAAssetsCreator : NSObject

+ (instancetype)sharedCreator;
- (void)createJPGAndGIFForVideo:(YAVideo*)video;

- (void)addBumberToVideoAtURLAndSaveToCameraRoll:(NSURL*)videoURL completion:(cameraRollCompletion)completion;

- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl addToGroup:(YAGroup*)group;
- (void)createVideoFromRemoteDictionary:(NSDictionary*)videoDic addToGroup:(YAGroup*)group;

//
- (void)createAssetsForGroup:(YAGroup*)group;
- (void)stopAllJobsForGroup:(YAGroup*)group;

// on background
- (void)waitForAllOperationsToFinish;
@end
