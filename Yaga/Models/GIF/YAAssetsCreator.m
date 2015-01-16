//
//  YAGIFOperation.m
//  Yaga
//
//  Created by valentinkovalski on 1/2/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAAssetsCreator.h"
#import "YAUtils.h"

#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "YAServer.h"
#import "YAUser.h"
#import "YAServerTransactionQueue.h"

#import "YAGifCreationOperation.h"
#import "YAVideoDownloadOperation.h"
#import "YAVideoCreateOperation.h"

@interface YAAssetsCreator ()
@property (atomic, strong) NSMutableArray *videosToProcess;
@property (nonatomic, copy) cameraRollCompletion cameraRollCompletionBlock;
@property (nonatomic, strong) NSOperationQueue *queue;
@end


@implementation YAAssetsCreator

+ (instancetype)sharedCreator {
    static YAAssetsCreator *s = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        s = [[self alloc] init];
    });
    return s;
}

- (instancetype)init {
    if (self = [super init]) {
        self.videosToProcess = [NSMutableArray array];
        //concurent downloads but serial gif generation..
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 3;
    }
    return self;
}

#pragma mark GIF and JPEG generation

- (void)createJPGAndGIFForVideo:(YAVideo*)video
{
    [self.queue addOperation:[[YAGifCreationOperation alloc] initWithVideo:video]];
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
}

#pragma mark - Camera roll
- (void)addBumberToVideoAtURLAndSaveToCameraRoll:(NSURL*)videoURL completion:(cameraRollCompletion)completion {
    NSURL *outputUrl = [YAUtils urlFromFileName:@"for_camera_roll.mov"];
    [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
    
    AVPlayerItem *playerItem = [self buildVideoSequenceComposition:videoURL];
    
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:(AVAsset*)playerItem.asset
                                                                     presetName:AVAssetExportPresetHighestQuality];
    session.videoComposition = playerItem.videoComposition;
    
    session.outputURL = outputUrl;
    session.outputFileType = AVFileTypeQuickTimeMovie;
    [session exportAsynchronouslyWithCompletionHandler:^(void ) {
        NSString *path = outputUrl.path;
        self.cameraRollCompletionBlock = completion;
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError: contextInfo:), nil);
    }];
}

-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    self.cameraRollCompletionBlock(error);
}

- (AVPlayerItem*)buildVideoSequenceComposition:(NSURL*)realVideoUrl {
    AVAsset *asset1 = [AVAsset assetWithURL:realVideoUrl];
    NSString *filePath2 = [[NSBundle mainBundle] pathForResource:@"bumper_360x480" ofType:@"mov"];
    AVAsset *asset2 = [AVAsset assetWithURL:[NSURL fileURLWithPath:filePath2]];
    
    NSArray *assets = @[asset1, asset2];
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSMutableArray *instructions = [NSMutableArray new];
    CGSize size = CGSizeZero;
    
    CMTime time = kCMTimeZero;
    
    for (AVAsset *asset in assets) {
        AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *audioAssetTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        
        NSError *error;
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetTrack.timeRange.duration)
                                       ofTrack:assetTrack
                                        atTime:time
                                         error:&error];
        
        if (error) {
            NSLog(@"Error - %@", error.debugDescription);
        }
        
        [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetTrack.timeRange.duration)
                                       ofTrack:audioAssetTrack
                                        atTime:time
                                         error:&error];
        if (error) {
            NSLog(@"Error - %@", error.debugDescription);
        }
        
        AVMutableVideoCompositionInstruction *videoCompositionInstruction =
        [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        videoCompositionInstruction.timeRange = CMTimeRangeMake(time, assetTrack.timeRange.duration);
        
        videoCompositionInstruction.layerInstructions =
        @[[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack]];
        AVMutableVideoCompositionLayerInstruction *layerInstruction =
        [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetTrack];
        
        if([assets indexOfObject:asset] == 0)
        {
            
            [layerInstruction setTransform:assetTrack.preferredTransform
                                    atTime:kCMTimeZero];
            
        } else {
            NSLog(@"%@", NSStringFromCGSize(assetTrack.naturalSize));
            NSLog(@"%@", NSStringFromCGRect([UIScreen mainScreen].nativeBounds));
            CGFloat xMove = ([UIScreen mainScreen].nativeBounds.size.width - assetTrack.naturalSize.width)/2;
            CGFloat yMove = ([UIScreen mainScreen].nativeBounds.size.height - assetTrack.naturalSize.height)/2;
            CGAffineTransform transform = CGAffineTransformTranslate(assetTrack.preferredTransform,
                                                                     xMove,
                                                                     yMove);
            
            
            [layerInstruction setTransform:transform atTime:kCMTimeZero];
        }
        
        videoCompositionInstruction.layerInstructions = @[layerInstruction];
        [instructions addObject:videoCompositionInstruction];
        
        
        time = CMTimeAdd(time, assetTrack.timeRange.duration);
        
        if (CGSizeEqualToSize(size, CGSizeZero))
        {
            size = assetTrack.naturalSize;;
        }
    }
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.instructions = instructions;
    
    // Set the frame duration to an appropriate value (i.e. 30 frames per second for video).
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    mutableVideoComposition.renderSize = CGSizeMake(size.height, size.width);
    
    AVPlayerItem *pi = [AVPlayerItem playerItemWithAsset:mutableComposition];
    pi.videoComposition = mutableVideoComposition;
    return pi;
}

#pragma mark - Realm
- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl
                        addToGroup:(YAGroup*)group {
    
    YAVideo *video = [YAVideo video];
    YAVideoCreateOperation *videoCreateOperation = [[YAVideoCreateOperation alloc] initRecordingURL:recordingUrl group:group video:video];
    YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video];
    [gifCreationOperation addDependency:videoCreateOperation];
    [self.queue addOperation:videoCreateOperation];
    [self.queue addOperation:gifCreationOperation];
}

- (void)createVideoFromRemoteDictionary:(NSDictionary*)videoDic
                             addToGroup:(YAGroup*)group {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *videoId = videoDic[YA_RESPONSE_ID];

        [group.realm beginWriteTransaction];
        
        YAVideo *video = [YAVideo video];
        video.serverId = videoId;
        video.creator = videoDic[YA_RESPONSE_USER][YA_RESPONSE_NAME];
        NSTimeInterval timeInterval = [videoDic[YA_VIDEO_READY_AT] integerValue];
        video.createdAt = [NSDate dateWithTimeIntervalSince1970:timeInterval];
        video.url = videoDic[YA_VIDEO_ATTACHMENT];
        video.group = group;
        [group.videos insertObject:video atIndex:0];
        
        [group.realm commitWriteTransaction];
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_ADDED_NOTIFICATION object:video];
        
        [self createDownloadTaskForVideo:video inGroup:group];
    });
}

- (void)createAssetsForGroup:(YAGroup*)group {
    for(YAVideo *video in group.videos) {
        [self createDownloadTaskForVideo:video inGroup:group];
    }
}

- (void)stopAllJobsForGroup:(YAGroup*)group {
    for (NSOperation *op in self.queue.operations) {
        if ([op.name isEqualToString:group.name])
        {
            NSLog(@"CANCELING OPERATION %@", group.name);
            [op cancel];
        }
    }
}

- (void)createDownloadTaskForVideo:(YAVideo*)video inGroup:(YAGroup*)group
{
    YAVideoDownloadOperation *downloadOperation = [[YAVideoDownloadOperation alloc] initWithVideo:video];
    downloadOperation.name = group.name;
    YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video];
    [gifCreationOperation addDependency:downloadOperation];
    gifCreationOperation.name = group.name;
    [self.queue addOperation:downloadOperation];
    [self.queue addOperation:gifCreationOperation];
}

- (void)waitForAllOperationsToFinish
{
    [self.queue waitUntilAllOperationsAreFinished];
}

@end
