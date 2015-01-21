//
//  YAVideoDownloadOperation.m
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YAUtils.h"
#import "YAVideoDownloadOperation.h"
@interface YAVideoDownloadOperation (){
    @private
    // properties to maintain the NSOperation
    BOOL finished;
    BOOL executing;
}
@property (nonatomic, strong) YAVideo *video;

- (BOOL)isConcurrent;
- (BOOL)isFinished;
- (BOOL)isExecuting;

@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *data;
@property (atomic) BOOL done;
@end

@implementation YAVideoDownloadOperation
- (instancetype)initWithVideo:(YAVideo*)video
{
    if (self = [super init])
    {
        _video = video;
    }
    return self;
}

- (void)start{
    if (![self isCancelled]) {
        [self willChangeValueForKey:@"isExecuting"];
        executing = YES;
        //set up the thread and kick it off...
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        __block NSString *videoUrl;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            videoUrl = self.video.url;
        });
        
        NSURL *remoteURL = [NSURL URLWithString:videoUrl];
        [NSThread detachNewThreadSelector:@selector(download:) toTarget:self withObject:remoteURL];
        [self didChangeValueForKey:@"isExecuting"];
        
    } else {
        // If it's already been cancelled, mark the operation as finished.
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}


- (void)download:(NSURL *)url {
    @autoreleasepool {
        
        self.done = NO;
        self.data = [NSMutableData data];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:url];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        if (self.urlConnection != nil) {
            do {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            } while (!self.done);
        }
        [self willChangeValueForKey:@"isFinished"];
        [self willChangeValueForKey:@"isExecuting"];
        finished = YES;
        executing = NO;
        // Clean up.
        self.urlConnection = nil;

        NSLog(@"download and parse cleaning up");
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
    
    }
}

#pragma mark - NSURLConnection

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self isCancelled])
    {
        self.data = nil;
        _done = YES;
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            RLMRealm *realm = self.video.realm;
            [realm beginWriteTransaction];
            [realm deleteObject:self.video];
            [realm commitWriteTransaction];
            
        });
    }
    else
    {
        NSString *hashStr       = [YAUtils uniqueId];
        NSString *moveFilename  = [hashStr stringByAppendingPathExtension:@"mov"];
        NSString *movPath       = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
        NSURL    *movURL        = [NSURL fileURLWithPath:movPath];
        
        BOOL result = [self.data writeToURL:movURL atomically:YES];
        if(!result) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSURL *remoteURL = [NSURL URLWithString:self.video.url];
                NSLog(@"Critical Error: can't save video data from remote data, url %@", remoteURL);
                self.done = YES;
            });
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.video.realm beginWriteTransaction];
                self.video.movFilename = moveFilename;
                [self.video.realm commitWriteTransaction];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:self.video];
            });
            self.done = YES;
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([self isCancelled])
    {
        self.data = nil;
        self.done = YES;
        dispatch_sync(dispatch_get_main_queue(), ^{

            RLMRealm *realm = self.video.realm;
            [realm beginWriteTransaction];
            [realm deleteObject:self.video];
            [realm commitWriteTransaction];
            
        });
    }
    else
    {
        [self.data appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.data = nil;
    self.done = YES;
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        RLMRealm *realm = self.video.realm;
        [realm beginWriteTransaction];
        [realm deleteObject:self.video];
        [realm commitWriteTransaction];
        
    });

}

@end
