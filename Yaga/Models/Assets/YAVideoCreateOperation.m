//
//  YAVideoCreateOperation.m
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAVideoCreateOperation.h"
#import "YAServerTransactionQueue.h"
#import "YAUtils.h"
#import "YAUser.h"

@interface YAVideoCreateOperation ()
@property (nonatomic, strong) YAGroup *group;
@property (nonatomic, strong) NSURL *recordingURL;
@property (nonatomic, strong) YAVideo *video;
@end
@implementation YAVideoCreateOperation
- (instancetype)initRecordingURL:(NSURL*)recordingURL group:(YAGroup*)group video:(YAVideo *)video
{
    if (self = [super init])
    {
        _group = group;
        _recordingURL = recordingURL;
        _video = video;
    }
    return self;
}

- (void)main
{
    @autoreleasepool {
        NSString *hashStr = [YAUtils uniqueId];
        NSString *moveFilename = [hashStr stringByAppendingPathExtension:@"mov"];
        NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
        NSURL    *movURL = [NSURL fileURLWithPath:movPath];
        
        NSError *error;
        [[NSFileManager defaultManager] moveItemAtURL:self.recordingURL toURL:movURL error:&error];
        if(error) {
            NSLog(@"Error in createVideoFromRecodingURL, can't move recording, %@", error);
            return;
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.group.realm beginWriteTransaction];
            self.video.creator = [[YAUser currentUser] username];
            self.video.createdAt = [NSDate date];
            self.video.movFilename = moveFilename;
            self.video.group = self.group;
            [self.group.videos insertObject:self.video atIndex:0];
            
            [self.group.realm commitWriteTransaction];
            [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_ADDED_NOTIFICATION object:self.video];
            
            //start uploading while generating gif
            [[YAServerTransactionQueue sharedQueue] addUploadVideoTransaction:self.video];
            
        //    [self createJPGAndGIFForVideo:video];
        });
    }
}
@end
