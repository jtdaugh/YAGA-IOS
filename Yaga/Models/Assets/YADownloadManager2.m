//
//  YADownloadManager2.m
//  Yaga
//
//  Created by valentinkovalski on 4/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YADownloadManager2.h"
#import "YAAssetsCreator.h"
#import "YAUser.h"

@interface YADownloadManager2 ()
//keeps executing and paused AFDownloadRequestOperations in memory so they can be resumed
@property (nonatomic, strong) NSMutableDictionary *downloadJobs;

@property (nonatomic, strong) NSMutableArray *waitingUrls;
@property (nonatomic, strong) NSMutableSet *executingUrls;

@property (strong) dispatch_semaphore_t waiting_semaphore;
@end

#define kDefaultCountOfConcurentJobs 4

@implementation YADownloadManager2

+ (instancetype)sharedManager {
    static YADownloadManager2 *s = nil;
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
    
    //do nothing if job is enqueued already
    if([self.downloadJobs.allKeys containsObject:stringUrl])
        return self.downloadJobs[stringUrl];
    
    NSURL *url = [NSURL URLWithString:stringUrl];
    
    NSString *hashStr   = url.lastPathComponent;
    NSString *filename  = [hashStr stringByAppendingPathExtension:gifJob ? @"gif" : @"mp4"];
    NSString *filePath  = [[YAUtils cachesDirectory] stringByAppendingPathComponent:filename];
    NSURL    *fileUrl   = [NSURL fileURLWithPath:filePath];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
#warning test shouldResume:YES
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:fileUrl.path shouldResume:NO];
    operation.shouldOverwrite = YES;
    
    operation.name = stringUrl;
    
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
                
                [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION
                                                                    object:video];
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
    NSMutableArray *allUrls = [NSMutableArray arrayWithArray:self.waitingUrls];
    [allUrls removeObjectsInArray:orderedUrls];
    
    NSMutableArray *waitingUrlsMutable = [NSMutableArray arrayWithArray:orderedUrls];
    [waitingUrlsMutable addObjectsFromArray:self.waitingUrls];
    
    self.waitingUrls = waitingUrlsMutable;
}

- (void)pauseExecutingJobs {
    //using reverse enumerator in order to keep the same order in waiting jobs
    for (NSString *executingUrl in self.executingUrls) {
        [self.downloadJobs[executingUrl] pause];
        [self.waitingUrls insertObject:executingUrl atIndex:0];
    }
    [self.executingUrls removeAllObjects];
}

- (void)resumeJobs {
    if(self.waitingUrls.count) {
        
        //sort waiting jobs so gifs go first
        
#warning TODO:sort waiting jobs so gifs always go first        
        
        //fill in the executing queue to the max capacity
        while (self.executingUrls.count < self.maxConcurentJobs && self.waitingUrls.count) {
            NSString *waitingUrl = [self.waitingUrls objectAtIndex:0];
            __block AFDownloadRequestOperation *nextJob = [self.downloadJobs objectForKey:waitingUrl];
            
            if(!nextJob) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *predicate = [NSString stringWithFormat:@"gifUrl = '%@'", waitingUrl];
                    RLMResults *results = [YAVideo objectsWhere:predicate];
                    
                    BOOL gifJob = results.count;

                    if(!gifJob) {
                        predicate = [NSString stringWithFormat:@"url = '%@'", waitingUrl];
                        results = [YAVideo objectsWhere:predicate];
                    }
                    
                    YAVideo *video = results[0];
                    
                    nextJob = [self createJobForVideo:video gifJob:gifJob];
                    [self.downloadJobs setObject:nextJob forKey:waitingUrl];
                    
                    [nextJob start];
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
    
    dispatch_semaphore_wait(self.waiting_semaphore, DISPATCH_TIME_FOREVER);
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
    
    if(self.executingUrls.count == 0 && self.waitingUrls.count == 0) {
        DLog(@"YADownloadManager all done");
        if(self.waiting_semaphore)
            dispatch_semaphore_signal(self.waiting_semaphore);
        return;
    }
    
    if(self.waitingUrls.count == 0)
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
        
        [self resumeJobs];
    });
}

#pragma mark - Helper methods

- (BOOL)isMp4DownloadJob:(AFDownloadRequestOperation*)job {
    return [job.targetPath.pathExtension isEqualToString:@"mp4"];
}

- (NSString*)jobName:(AFDownloadRequestOperation*)job {
    return [self isMp4DownloadJob:job] ? @"mp4" : @"gif";
}

@end
