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

+ (instancetype)sharedManager;

- (void)cancelAllJobs;
- (void)waitUntilAllJobsAreFinished;

- (void)addDownloadJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob;
- (void)prioritizeDownloadJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob;

//additional methods for exclusive downloads in enlarged mode
- (void)cancelGifJobsInProgress;
- (NSArray*)pauseVideoJobsInProgress;
- (void)resumeDownloadJobs:(NSArray*)jobs;
@end
