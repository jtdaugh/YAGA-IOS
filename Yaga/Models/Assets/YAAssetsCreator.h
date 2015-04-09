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

typedef void (^bumperVideoCompletion)(NSURL *filePath, NSError *error);
typedef void (^stopOperationsCompletion)(void);
typedef void (^jpgCompletion)(void);

@interface YAAssetsCreator : NSObject

+ (instancetype)sharedCreator;

- (void)addBumberToVideoAtURLAndSaveToCameraRoll:(NSURL*)videoURL completion:(bumperVideoCompletion)completion;

- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl addToGroup:(YAGroup*)group;
- (void)enqueueAssetsCreationJobForVideos:(NSArray*)videos prioritizeDownload:(BOOL)prioritize;

- (void)stopAllJobsWithCompletion:(stopOperationsCompletion)completion;

// on background
- (void)waitForAllOperationsToFinish;

//
- (void)enqueueJpgCreationForVideo:(YAVideo*)video;
- (UIImage *)deviceSpecificCroppedThumbnailFromImage:(UIImage*)img;
- (void)cancelGifOperations;


@end
