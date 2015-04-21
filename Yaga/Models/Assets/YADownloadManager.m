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
        self.waitingJobs = [MutableOrderedDictionary new];
        self.executingJobs = [MutableOrderedDictionary new];
        self.maxConcurentJobs = kDefaultCountOfConcurentJobs;
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

- (BOOL)gifJobsInProgress {
    for(AFDownloadRequestOperation *job in self.executingJobs.allValues) {
        if([job.targetPath.pathExtension isEqualToString:@"gif"])
            return YES;
    }
    return NO;
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
    else {
        //should start immediately?
        //only gif job can be started immediately, or there are no gif jobs in progress
        if(gifJob || ![self gifJobsInProgress])
            [job start];
    }
    
    if(gifJob || [self gifJobsInProgress]) {
        [self pauseVideoJobsInProgress];
    }
    
    //can add without pausing another?
    if(self.executingJobs.allKeys.count < self.maxConcurentJobs) {
        
        //only gif job can be added immediately, or there are no gif jobs in progress
        if(gifJob || ![self gifJobsInProgress]) {
            [self.executingJobs setObject:job forKey:url];
            [self.waitingJobs removeObjectForKey:url];
            [self logState:[NSString stringWithFormat:@"prioritizeJobForVideo, gifJob: %d", gifJob]];
            return;
        }
    }
    
    //video job but other gif jobs in progress? add to waiting queue
    if(!gifJob && [self gifJobsInProgress]) {
        [self.waitingJobs insertObject:job forKey:url atIndex:0];
        [self logState:@"prioritizeJobForVideo:video job added to the waiting queue"];
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

- (void)pauseVideoJobsInProgress {
    //pause all executing video jobs and move them to waiting queue
    for (NSString *url in self.executingJobs.allKeys) {
        AFDownloadRequestOperation *job = [self.executingJobs objectForKey:url];
                                           
        if([job.targetPath.pathExtension isEqualToString:@"mp4"]) {
            [self.executingJobs removeObjectForKey:url];
            
            [job pause];
            
            [self.waitingJobs insertObject:job forKey:url atIndex:0];
        }
    }
}

- (void)logState:(NSString*)method {
    NSArray *executingTypes = [[[self.executingJobs allValues] valueForKey:@"targetPath"] valueForKey:@"pathExtension"];
    NSUInteger countOfExecutingGif = [executingTypes indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqualToString:@"gif"];
    }].count;
    NSUInteger countOfExecutingMp4 = [executingTypes indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqualToString:@"mp4"];
    }].count;

    
    NSArray *waitingTypes = [[[self.waitingJobs allValues] valueForKey:@"targetPath"] valueForKey:@"pathExtension"];
    NSUInteger countOfWaitingGif = [waitingTypes indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqualToString:@"gif"];
    }].count;
    NSUInteger countOfWaitingMp4 = [waitingTypes indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqualToString:@"mp4"];
    }].count;
    
    DLog(@"%@: executing GIF:%lu MP4:%lu , waiting: GIF:%lu MP4:%lu", method, countOfExecutingGif, countOfExecutingMp4, countOfWaitingGif, countOfWaitingMp4);
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
    
    NSString *url = gifJob ? video.gifUrl : video.url;
    
    [self.executingJobs removeObjectForKey:url];
    
    [self logState:[NSString stringWithFormat:@"jobFinishedForVideo %@ ", gifJob ? @"gif" : @"mp4"]];
    
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
        
        //do not start new jobs until gif jobs are in progress
        if([self gifJobsInProgress])
            return;
        
        //restore max capacity for videos
        self.maxConcurentJobs = kDefaultCountOfConcurentJobs;
        
        //start/resume waiting job
        if(self.waitingJobs.allKeys.count) {
            //fill in the executing queue to the max capacity
            while (self.executingJobs.allKeys.count < self.maxConcurentJobs && self.waitingJobs.count) {
                NSString *waitingUrl = [self.waitingJobs keyAtIndex:0];
                AFDownloadRequestOperation *waitingJob = [self.waitingJobs objectAtIndex:0];
                if(waitingJob.isPaused)
                    [waitingJob resume];
                else
                    [waitingJob start];
                
                [self.executingJobs setObject:waitingJob forKey:waitingUrl];
                [self.waitingJobs removeObjectForKey:waitingUrl];
            }
            
        }
    });
}
@end
