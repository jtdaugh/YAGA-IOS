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

- (void)addJobForVideo:(YAVideo*)video;
- (void)prioritizeJobForVideo:(YAVideo*)video;

- (BOOL)executingOperationForVideo:(YAVideo*)video;
@end
