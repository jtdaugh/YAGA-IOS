//
//  YADownloadManager.m
//  Yaga
//
//  Created by valentinkovalski on 2/6/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YADownloadManager.h"
#import "OrderedDictionary.h"
#import "YAUtils.h"
#import "YAAssetsCreator.h"
#import "AFDownloadRequestOperation.h"

@interface YADownloadManager ()
@property (strong) MutableOrderedDictionary *waitingJobs;
@property (strong) MutableOrderedDictionary *executingJobs;
@property (strong) dispatch_semaphore_t waiting_semaphore;
@end

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
        self.waitingJobs = [MutableOrderedDictionary new];
        self.executingJobs = [MutableOrderedDictionary new];
        self.maxConcurentJobs = 4;
    }
    return self;
}

- (AFDownloadRequestOperation*)createJobForVideo:(YAVideo*)video {
    
    NSURL *url = [NSURL URLWithString:video.url];
    
    NSString *hashStr       = url.lastPathComponent;
    NSString *moveFilename  = [hashStr stringByAppendingPathExtension:@"mov"];
    NSString *movPath       = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
    NSURL    *movURL        = [NSURL fileURLWithPath:movPath];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:movURL.path shouldResume:YES];
    
    operation.name = video.url;
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [video.realm beginWriteTransaction];
            video.movFilename = moveFilename;
            video.localCreatedAt = [NSDate date];
            [video.realm commitWriteTransaction];
            
            [self jobFinishedForVideo:video];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(error.code == NSURLErrorCancelled) {
            NSLog(@"video download cancelled");
        }
        else {
            NSLog(@"Error downloading video %@", error);
        }
        [self jobFinishedForVideo:video];
    }];
    
    [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:video.url userInfo:@{kVideoDownloadNotificationUserInfoKey: [NSNumber numberWithFloat:(totalBytesReadForFile - totalBytesReadForFile * 0.3) /(float)totalBytesExpectedToReadForFile]}];
    }];
    return operation;
}

- (void)addJobForVideo:(YAVideo*)video {
    //already executing?
    if([self.executingJobs objectForKey:video.url])
        return;
    
    AFDownloadRequestOperation *job = [self createJobForVideo:video];
    
    //can start immediately?
    if(self.executingJobs.allKeys.count < self.maxConcurentJobs) {
        [self.executingJobs setObject:job forKey:video.url];
        [job start];
    }
    else {
        [self.waitingJobs setObject:job forKey:video.url];
    }
    
    [self logState:@"addJobForVideo"];
}

- (void)prioritizeJobForVideo:(YAVideo*)video {
    //already executing?
    if([self.executingJobs objectForKey:video.url])
        return;
    
    //get paused or create new one
    AFDownloadRequestOperation *job = [self.waitingJobs objectForKey:video.url];
    if(!job)
        job = [self createJobForVideo:video];
    
    //start or resume immediately
    if(job.isPaused)
        [job resume];
    else
        [job start];
    
    //can add without pausing another?
    if(self.executingJobs.allKeys.count < self.maxConcurentJobs) {
        [self.executingJobs setObject:job forKey:video.url];
        [self.waitingJobs removeObjectForKey:video.url];
        [self logState:@"prioritizeJobForVideo"];
        return;
    }
    
    //at max capacity? pause first one
    AFDownloadRequestOperation *jobToPause = [self.executingJobs objectAtIndex:0];
    [jobToPause pause];
    
    NSString *urlToPause = [self.executingJobs keyAtIndex:0];
    [self.executingJobs removeObjectForKey:urlToPause];
    
    [self.waitingJobs insertObject:jobToPause forKey:urlToPause atIndex:0];
    
    //then add new one
    [self.executingJobs setObject:job forKey:video.url];
    [self.waitingJobs removeObjectForKey:video.url];
    
    [self logState:@"prioritizeJobForVideo"];
}

- (void)jobFinishedForVideo:(YAVideo*)video {
    [[YAAssetsCreator sharedCreator] addGifCreationOperationForVideo:video];
    [self logState:@"jobFinishedForVideo"];
    
    [self.executingJobs removeObjectForKey:video.url];
    
    if(self.executingJobs.count == 0 && self.waitingJobs.count == 0) {
        NSLog(@"YADownloadManager all done");
        dispatch_semaphore_signal(self.waiting_semaphore);
        return;
    }
    
    if(self.waitingJobs.count == 0)
        return;
    
    //start/resume waiting job
    NSString *waitingUrl = [self.waitingJobs keyAtIndex:0];
    AFDownloadRequestOperation *waitingJob = [self.waitingJobs objectAtIndex:0];
    if(waitingJob.isPaused)
        [waitingJob resume];
    else
        [waitingJob start];
    
    [self.executingJobs setObject:waitingJob forKey:waitingUrl];
    [self.waitingJobs removeObjectForKey:waitingUrl];
}

- (BOOL)executingOperationForVideo:(YAVideo*)video {
    return [self.executingJobs objectForKey:video.url] != nil;
}

- (void)logState:(NSString*)method {
    NSLog(@"%@: executing: %lu, waiting: %lu", method, self.executingJobs.allKeys.count, self.waitingJobs.allKeys.count);
}

- (void)cancelAllJobs {
    for (AFDownloadRequestOperation *executingJob in self.executingJobs.allValues) {
        [executingJob cancel];
    }
    [self.executingJobs removeAllObjects];
    
    for (AFDownloadRequestOperation *waitingJob in self.waitingJobs.allValues) {
        if(waitingJob.isPaused)
            [waitingJob cancel];
    }
    
    [self.waitingJobs removeAllObjects];
}

- (void)waitUntilAllJobsAreFinished {
    if(self.executingJobs.count == 0 && self.waitingJobs.count == 0)
        return;
    
    self.waiting_semaphore = dispatch_semaphore_create(0);
    
    dispatch_semaphore_wait(self.waiting_semaphore, DISPATCH_TIME_FOREVER);
}
@end
