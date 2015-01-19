//
//  YAVideoDownloadOperation.m
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YAUtils.h"
#import "YAVideoDownloadOperation.h"
@interface YAVideoDownloadOperation ()
@property (nonatomic, strong) YAVideo *video;
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

- (void)main
{
    @autoreleasepool {
        __block NSString *videoUrl;

        dispatch_sync(dispatch_get_main_queue(), ^{
            videoUrl = self.video.url;
        });
        
        NSURL *remoteURL = [NSURL URLWithString:videoUrl];
        NSData *data = [NSData dataWithContentsOfURL:remoteURL];
        
        NSString *hashStr       = [YAUtils uniqueId];
        NSString *moveFilename  = [hashStr stringByAppendingPathExtension:@"mov"];
        NSString *movPath       = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
        NSURL    *movURL        = [NSURL fileURLWithPath:movPath];
        
        BOOL result = [data writeToURL:movURL atomically:YES];
        if(!result) {
            NSLog(@"Critical Error: can't save video data from remote data, url %@", remoteURL);
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.video.realm beginWriteTransaction];
                self.video.movFilename = moveFilename;
                [self.video.realm commitWriteTransaction];
                [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:self.video];
//                
//                [self createJPGAndGIFForVideo:video];
            });
        }
    }
}

@end
