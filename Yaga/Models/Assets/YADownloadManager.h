//
//  YADownloadManager.h
//  Yaga
//
//  Created by valentinkovalski on 2/6/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAVideo.h"

@interface YADownloadManager : NSObject

@property (nonatomic, assign) NSUInteger maxConcurentJobs;

@property (nonatomic, readonly) NSMutableDictionary *mp4DownloadProgress;

+ (instancetype)sharedManager;

- (void)cancelAllJobs;
- (void)waitUntilAllJobsAreFinished;

- (void)addDownloadJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob;
- (void)prioritizeDownloadJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob;
- (void)exclusivelyPrioritizeDownloadJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob;
@end
