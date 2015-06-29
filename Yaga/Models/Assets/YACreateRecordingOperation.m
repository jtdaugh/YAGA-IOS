//
//  YAVideoCreateOperation.m
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACreateRecordingOperation.h"
#import "YAServerTransactionQueue.h"
#import "YAUtils.h"
#import "YAUser.h"
#import <AVFoundation/AVFoundation.h>


@interface YACreateRecordingOperation ()
@property (nonatomic, strong) YAGroup *group;
@property (nonatomic, strong) NSURL *recordingURL;
@property (nonatomic, strong) YAVideo *video;
@end

@implementation YACreateRecordingOperation
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

- (void)setExecuting:(BOOL)value {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = value;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)value {
    [self willChangeValueForKey:@"isFinished"];
    _finished = value;
    [self didChangeValueForKey:@"isFinished"];
    
    if(_finished) {
        DLog(@"Create video from Recording finished, cancelled: %d", self.isCancelled);
    }
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isExecuting {
    return _executing;
}

- (void)start {
    @autoreleasepool {
        DLog(@"Create video from Recording operation started");
        
        [self setExecuting:YES];
        
        NSString *hashStr = [YAUtils uniqueId];
        NSString *movFilename = [hashStr stringByAppendingPathExtension:@"mov"];
        NSString *mp4Filename = [hashStr stringByAppendingPathExtension:@"mp4"];
        NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:movFilename];
        NSString *mp4Path = [[YAUtils cachesDirectory] stringByAppendingPathComponent:mp4Filename];
        NSURL    *movURL = [NSURL fileURLWithPath:movPath];
        
        NSError *error;
        [[NSFileManager defaultManager] moveItemAtURL:self.recordingURL toURL:movURL error:&error];
        if(error) {
            DLog(@"Error in createVideoFromRecodingURL, can't move recording, %@", error);
            return;
        }
        
        // Encoding mov to mp4
        AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movURL options:nil];
        
        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
        DLog(@"%@", compatiblePresets);
        
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset
                                                                              presetName:AVAssetExportPresetHighestQuality];
        
        exportSession.outputURL = [NSURL fileURLWithPath:mp4Path];
        exportSession.shouldOptimizeForNetworkUse = NO;
        exportSession.outputFileType = AVFileTypeMPEG4;
        if([UIDevice currentDevice].systemVersion.floatValue >= 8)
            exportSession.canPerformMultiplePassesOverSourceMediaData = YES;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusCompleted:
                {
                    NSDate *currentDate = [NSDate date];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.group.realm beginWriteTransaction];
                        self.video.creator = [[YAUser currentUser] username];
                        self.video.createdAt = currentDate;
                        self.video.mp4Filename = mp4Filename;
                        self.video.group = self.group;
                        self.group.updatedAt = currentDate;
                        [self.group.videos insertObject:self.video atIndex:0];
                        
                        [self.group.realm commitWriteTransaction];
                        
                        //update local update time so the "new" badge isn't shown
//                        NSMutableDictionary *groupsUpdatedAt = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT]];
//                        
//                        [groupsUpdatedAt setObject:currentDate forKey:self.group.localId];
//                        [[NSUserDefaults standardUserDefaults] setObject:groupsUpdatedAt forKey:YA_GROUPS_UPDATED_AT];

                        //start uploading while generating gif
                        [[YAServerTransactionQueue sharedQueue] addUploadVideoTransaction:self.video toGroup:self.group];

                        [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_DID_REFRESH_NOTIFICATION object:self.group userInfo:@{kNewVideos:@[self.video]}];
                                                
                        [self setExecuting:NO];
                        [self setFinished:YES];
                    });
                    
                    break;
                }
                default:
                    DLog(@"Error: Unable to convert mov to mp4!");
                    break;
            }
            
        }];
    }
}



@end
