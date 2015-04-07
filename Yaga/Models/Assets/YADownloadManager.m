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
#import "YAUser.h"

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

- (AFDownloadRequestOperation*)createJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob {
    
    NSString *stringUrl = gifJob ? video.gifUrl : video.url;
    
    NSURL *url = [NSURL URLWithString:stringUrl];
    
    NSString *hashStr   = url.lastPathComponent;
    NSString *filename  = [hashStr stringByAppendingPathExtension:gifJob ? @"gif" : @"mp4"];
    NSString *filePath  = [[YAUtils cachesDirectory] stringByAppendingPathComponent:filename];
    NSURL    *fileUrl   = [NSURL fileURLWithPath:filePath];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:fileUrl.path shouldResume:NO];
    operation.shouldOverwrite = YES;
    
    operation.name = stringUrl;
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [video.realm beginWriteTransaction];
            if(gifJob)
                video.gifFilename = filename;
            else
                video.mp4Filename = filename;
            
            video.localCreatedAt = [NSDate date];
            [video.realm commitWriteTransaction];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION
                                                                object:video];
            [self jobFinishedForVideo:video gifJob:gifJob];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(error.code == NSURLErrorCancelled) {
            DLog(@"video download cancelled");
        }
        else {
            DLog(@"Error downloading video %@", error);
        }
        [self jobFinishedForVideo:video gifJob:gifJob];
    }];
    
    [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:stringUrl userInfo:@{kVideoDownloadNotificationUserInfoKey: [NSNumber numberWithFloat:(float)totalBytesReadForFile / (float)totalBytesExpectedToReadForFile]}];
    }];
    return operation;
}

- (void)addDownloadJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob {
    NSString *url = gifJob ? video.gifUrl : video.url;
    
    //already executing?
    if([self.executingJobs objectForKey:url]) {
        DLog(@"addJobForVideo: %@ is already executing, skipping.", url);
        return;
    }
    
    //waiting already?
    if([self.waitingJobs objectForKey:url]) {
        DLog(@"addJobForVideo: %@ is already waiting, skipping.", url);
        return;
    }
    
    AFDownloadRequestOperation *job = [self createJobForVideo:video gifJob:gifJob];
    
    //can start immediately?
    if(self.executingJobs.allKeys.count < self.maxConcurentJobs) {
        [self.executingJobs setObject:job forKey:url];
        [job start];
    }
    else {
        [self.waitingJobs setObject:job forKey:url];
    }
    
    [self logState:@"addJobForVideo"];
}

- (void)prioritizeDownloadJobForVideo:(YAVideo*)video gifJob:(BOOL)gifJob {
    NSString *url = gifJob ? video.gifUrl : video.url;
    
    //already executing?
    if([self.executingJobs objectForKey:url]) {
        DLog(@"prioritizeJobForVideo: %@ is already executing, skipping.", url);
        return;
    }
        
    //get paused or create new one
    AFDownloadRequestOperation *job = [self.waitingJobs objectForKey:url];
    if(!job)
        job = [self createJobForVideo:video gifJob:gifJob];
    
    //start or resume immediately
    if(job.isPaused)
        [job resume];
    else
        [job start];
    
    //can add without pausing another?
    if(self.executingJobs.allKeys.count < self.maxConcurentJobs) {
        [self.executingJobs setObject:job forKey:url];
        [self.waitingJobs removeObjectForKey:url];
        [self logState:[NSString stringWithFormat:@"prioritizeJobForVideo, gifJob: %d", gifJob]];
        return;
    }
    
    //at max capacity? pause first one
    AFDownloadRequestOperation *jobToPause = [self.executingJobs objectAtIndex:0];
    [jobToPause pause];
    
    NSString *urlToPause = [self.executingJobs keyAtIndex:0];
    [self.executingJobs removeObjectForKey:urlToPause];
    
    [self.waitingJobs insertObject:jobToPause forKey:urlToPause atIndex:0];
    
    //then add new one
    [self.executingJobs setObject:job forKey:url];
    [self.waitingJobs removeObjectForKey:url];
    
    [self logState:[NSString stringWithFormat:@"prioritizeJobForVideo, gifJob: %d", gifJob]];
}

- (void)logState:(NSString*)method {
    DLog(@"%@: executing: %lu, waiting: %lu", method, (unsigned long)self.executingJobs.allKeys.count, (unsigned long)self.waitingJobs.allKeys.count);
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

- (void)jobFinishedForVideo:(YAVideo*)video gifJob:(BOOL)gifJob {
    if(!gifJob)
        [[YAAssetsCreator sharedCreator] enqueueJpgCreationForVideo:video];
    
    [self logState:[NSString stringWithFormat:@"jobFinishedForVideo, gifJob: %d", gifJob]];
    
    NSString *url = gifJob ? video.gifUrl : video.url;
    
    [self.executingJobs removeObjectForKey:url];
    
    if(self.executingJobs.count == 0 && self.waitingJobs.count == 0) {
        DLog(@"YADownloadManager all done");
        if(self.waiting_semaphore)
            dispatch_semaphore_signal(self.waiting_semaphore);
        return;
    }
    
    if(self.waitingJobs.count == 0)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //caches folder too big?
        if([[YAUser currentUser] assetsFolderSizeExceeded]) {
            //stop downloads in background mode
            if([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
                return;
            else {
                //delete oldest to keep folder size static
                [[YAUser currentUser] purgeOldVideos];
            }
        }
        
        //start/resume waiting job
        if(self.waitingJobs.allKeys.count) {
            NSString *waitingUrl = [self.waitingJobs keyAtIndex:0];
            AFDownloadRequestOperation *waitingJob = [self.waitingJobs objectAtIndex:0];
            if(waitingJob.isPaused)
                [waitingJob resume];
            else
                [waitingJob start];
            
            if(self.executingJobs.allKeys.count < self.maxConcurentJobs) {
                [self.executingJobs setObject:waitingJob forKey:waitingUrl];
                [self.waitingJobs removeObjectForKey:waitingUrl];
            }
        }
    });
}

@end
