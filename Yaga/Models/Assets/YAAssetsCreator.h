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

typedef void (^videoOperationCompletion)(NSURL *filePath, NSError *error);
typedef void (^videoConcatenationCompletion)(NSURL *filePath, NSTimeInterval totalDuration, NSError *error);
typedef void (^stopOperationsCompletion)(void);
typedef void (^jpgCompletion)(void);

@interface YAAssetsCreator : NSObject

+ (instancetype)sharedCreator;

- (void)addBumberToVideoAtURL:(NSURL*)videoURL completion:(videoOperationCompletion)completion;

- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl
                   withCaptionText:(NSString *)captionText
                                 x:(CGFloat)x
                                 y:(CGFloat)y
                             scale:(CGFloat)scale
                          rotation:(CGFloat)rotation
                       addToGroups:(NSArray *)groups;

+ (void)reformatExternalVideoAtUrl:(NSURL *)videoUrl withCompletion:(videoConcatenationCompletion)completion;

- (void)concatenateAssetsAtURLs:(NSArray *)assetURLs
                  withOutputURL:(NSURL *)outputURL
                  exportQuality:(NSString *)exportQuality
                     completion:(videoConcatenationCompletion)completion;

//- (void)createVideoFromSequenceOfURLs:(NSArray *)videoURLs addToGroup:(YAGroup*)group;
- (void)enqueueAssetsCreationJobForVisibleVideos:(NSArray*)visibleVideos invisibleVideos:(NSArray*)invisibleVideos killExistingJobs:(BOOL)killExisting;

- (void)stopAllJobsWithCompletion:(stopOperationsCompletion)completion;

// on background
- (void)waitForAllOperationsToFinish;

//
- (void)enqueueJpgCreationForVideo:(YAVideo*)video;
- (UIImage *)deviceSpecificCroppedThumbnailFromImage:(UIImage*)img;
- (void)cancelGifOperations;


@end
