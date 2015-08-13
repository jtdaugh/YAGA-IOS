//
//  YADownloadManager2.h
//  Yaga
//
//  Created by valentinkovalski on 4/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFDownloadRequestOperation.h"

@interface YADownloadManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) NSUInteger maxConcurentJobs;

//to keep download progress in memory
@property (nonatomic, readonly) NSMutableDictionary *mp4DownloadProgress;

- (AFDownloadRequestOperation*)createJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob;
- (void)reorderJobs:(NSArray*)orderedUrls;
- (void)pauseExecutingJobs;
- (void)resumeJobs;
- (void)waitUntilAllJobsAreFinished;
- (void)cancelAllJobs;

- (void)exclusivelyDownloadMp4ForVideo:(YAVideo*)video;

@end
