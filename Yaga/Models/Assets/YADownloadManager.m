//
//  YADownloadManager.m
//  Yaga
//
//  Created by valentinkovalski on 4/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YADownloadManager.h"
#import "YAAssetsCreator.h"
#import "YAUser.h"

@interface YADownloadManager ()
//keeps executing and paused AFDownloadRequestOperations in memory so they can be resumed
@property (atomic, strong) NSMutableDictionary *downloadJobs;

@property (atomic, strong) NSMutableArray *waitingUrls;

@property (atomic, strong) NSMutableSet *executingUrls;

@property (strong) dispatch_semaphore_t waiting_semaphore;
@end

#define kDefaultCountOfConcurentJobs 4

@implementation YADownloadManager

+ (instancetype)sharedManager {
    static YADownloadManager *s = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        s = [[self alloc] init];
    });
    return s;
}

- (id)init {
    self = [super init];
    if(self) {
        self.downloadJobs = [NSMutableDictionary new];
        self.waitingUrls = [NSMutableArray new];
        self.executingUrls = [NSMutableSet new];
        self.maxConcurentJobs = kDefaultCountOfConcurentJobs;
        _mp4DownloadProgress = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - Public

- (AFDownloadRequestOperation*)createJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob {
    
    NSString *stringUrl = gifJob ? video.gifUrl : video.url;
    
    if(!stringUrl.length)
        return nil;
    
    //do nothing if job is enqueued already
    if([self.downloadJobs.allKeys containsObject:stringUrl])
        return self.downloadJobs[stringUrl];
    
    NSURL *url = [NSURL URLWithString:stringUrl];
    
    NSString *hashStr   = url.lastPathComponent;
    NSString *filename  = [hashStr stringByAppendingPathExtension:gifJob ? @"gif" : @"mp4"];
    NSString *filePath  = [[YAUtils cachesDirectory] stringByAppendingPathComponent:filename];
    NSURL    *fileUrl   = [NSURL fileURLWithPath:filePath];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:fileUrl.path shouldResume:NO];
    operation.shouldOverwrite = YES;
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (![video isInvalidated]) {
                [video.realm beginWriteTransaction];
                if(gifJob)
                    video.gifFilename = filename;
                else
                    video.mp4Filename = filename;
                
                video.localCreatedAt = [NSDate date];
                [video.realm commitWriteTransaction];
                
                NSDictionary *notificationOptions = gifJob ? @{kShouldReloadVideoCell:[NSNumber numberWithBool:YES]} : nil;
                [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION
                                                                    object:video userInfo:notificationOptions];
                [self jobFinishedForUrl:stringUrl video:video gifJob:gifJob];
            }
            else {
                [self jobFinishedForUrl:stringUrl video:nil gifJob:gifJob];
            }
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(error.code == NSURLErrorCancelled) {
            DLog(@"download job cancelled");
        }
        else {
            DLog(@"Error downloading video %@", error);
        }
        [self jobFinishedForUrl:stringUrl video:nil gifJob:gifJob];
    }];
    
    [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        
        float progress = (float)totalBytesReadForFile / (float)totalBytesExpectedToReadForFile;
        
        if(!gifJob)
            [self.mp4DownloadProgress setObject:[NSNumber numberWithFloat:progress] forKey:stringUrl];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:stringUrl userInfo:@{kVideoDownloadNotificationUserInfoKey: [NSNumber numberWithFloat:progress]}];
    }];
    
    [self.downloadJobs setObject:operation forKey:stringUrl];
    
    return operation;
}

- (void)reorderJobs:(NSArray*)orderedUrls {
    [self.waitingUrls removeObjectsInArray:orderedUrls];
    
    NSMutableArray *newWaitingUrls = [NSMutableArray arrayWithArray:orderedUrls];
    [newWaitingUrls addObjectsFromArray:self.waitingUrls];
    
    self.waitingUrls = newWaitingUrls;
}

- (void)pauseExecutingJobs {
    //using reverse enumerator in order to keep the same order in waiting jobs
    for (NSString *executingUrl in self.executingUrls) {
        AFDownloadRequestOperation *executingJob = self.downloadJobs[executingUrl];
        [executingJob pause];
        
        [self.waitingUrls insertObject:executingUrl atIndex:0];
    }
    [self.executingUrls removeAllObjects];
    
    DLog(@"download jobs are paused...");
}

- (NSString*)nextUrl {
    if(self.waitingUrls.count)
        return self.waitingUrls[0];
    
    return nil;
}

- (void)resumeJobs {
    DLog(@"Resume jobs called");
    if([self nextUrl]) {
        //fill in the executing queue to the max capacity
        while (self.executingUrls.count < self.maxConcurentJobs && [self nextUrl]) {
            NSString *waitingUrl = [self nextUrl];
            
            if(!waitingUrl.length)
                break;
            
            __block AFDownloadRequestOperation *nextJob = [self.downloadJobs objectForKey:waitingUrl];
            
            if(!nextJob) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *predicate = [NSString stringWithFormat:@"gifUrl = '%@'", waitingUrl];
                    RLMResults *results = [YAVideo objectsWhere:predicate];
                    
                    BOOL gifJob = results.count;
                    if(results.count > 1) {
                        YAVideo *v1 = [results objectAtIndex:0];
                        YAVideo *v2 = [results objectAtIndex:1];
                        DLog(@"WTF IS THIS:\n1. serverId:%@, localId: %@\n2. serverID:%@, localId: %@",v1.serverId, v1.localId, v2.serverId, v2.localId);
                    }

                    if(!gifJob) {
                        predicate = [NSString stringWithFormat:@"url = '%@'", waitingUrl];
                        results = [YAVideo objectsWhere:predicate];
                    }
                    
                    if(results.count) {
                        YAVideo *video = results[0];
                        
                        nextJob = [self createJobForVideo:video gifJob:gifJob];
                        if(nextJob) {
                            [self.downloadJobs setObject:nextJob forKey:waitingUrl];
                            
                            [nextJob start];
                        }
                    }
                });
            }
            else {
                [nextJob resume];
            }
            
            [self.executingUrls addObject:waitingUrl];
            
            [self.waitingUrls removeObject:waitingUrl];
        }
    }
    else {
        DLog(@"resumeJobs: nothing to resume");
    }
}

- (void)waitUntilAllJobsAreFinished {
    if(self.executingUrls.count == 0 && self.waitingUrls.count == 0)
        return;
    
    self.waiting_semaphore = dispatch_semaphore_create(0);
    
    DLog(@"Waiting Until All Jobs Are Finished");
    dispatch_semaphore_wait(self.waiting_semaphore, DISPATCH_TIME_FOREVER);
    DLog(@"Done waiting for jobs to Finish");
}

- (void)cancelAllJobs {
    for (NSString *executingUrl in self.executingUrls) {
        [self.downloadJobs[executingUrl] cancel];
    }
    [self.executingUrls removeAllObjects];
    
    for (NSString *waitingUrl in self.waitingUrls) {
        [self.downloadJobs[waitingUrl] cancel];
    }
    
    [self.waitingUrls removeAllObjects];
}

#pragma mark - Private
- (void)jobFinishedForUrl:(NSString*)url video:(YAVideo*)video gifJob:(BOOL)gifJob {
    
    if(video && !gifJob)
        [[YAAssetsCreator sharedCreator] enqueueJpgCreationForVideo:video];
    
    [self.executingUrls removeObject:url];
    [self.downloadJobs removeObjectForKey:url];
    
    DLog(@"%@ finished", gifJob ? @"gif" : @"mp4");
    
    if(self.executingUrls.count == 0 && self.waitingUrls.count == 00) {
        DLog(@"YADownloadManager all done");
        if(self.waiting_semaphore)
            dispatch_semaphore_signal(self.waiting_semaphore);
        return;
    }
    
    [self resumeJobs];
}

- (void)exclusivelyDownloadMp4IfNeededForVideo:(YAVideo*)video thenPrioritizeNearbyDownloads:(NSArray *)nearbyVideosToPrioritize {
    
    if (!video.mp4Filename.length) {
        [self pauseExecutingJobs];
        AFDownloadRequestOperation *nextJob = [self createJobForVideo:video gifJob:NO];
        if(!nextJob)
            return;
        
        [self.downloadJobs setObject:nextJob forKey:video.url];
        if(nextJob.isPaused)
            [nextJob resume];
        else
            [nextJob start];
        
        [self.waitingUrls removeObject:video.url];
        [self.executingUrls addObject:video.url];
    }
    
    
    for (YAVideo *video in nearbyVideosToPrioritize) {
        if(video && !video.mp4Filename.length) {
            [self.waitingUrls removeObject:video.url];
            [self.waitingUrls addObject:video.url];
        }
    }
}

#pragma mark - Helper methods

- (BOOL)isMp4DownloadJob:(AFDownloadRequestOperation*)job {
    return [job.targetPath.pathExtension isEqualToString:@"mp4"];
}

- (NSString*)jobName:(AFDownloadRequestOperation*)job {
    return [self isMp4DownloadJob:job] ? @"mp4" : @"gif";
}

@end
