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
#import "YACreateRecordingOperation.h"
#import "AFHTTPRequestOperation.h"

@interface YAAssetsCreator ()
@property (nonatomic, copy) cameraRollCompletion cameraRollCompletionBlock;
@property (strong) NSOperationQueue *downloadQueue;
@property (strong) NSOperationQueue *gifQueue;
@property (strong) NSOperationQueue *recordingQueue;
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

        self.downloadQueue = [[NSOperationQueue alloc] init];
        self.downloadQueue.maxConcurrentOperationCount = 4;
        
        self.gifQueue = [[NSOperationQueue alloc] init];
        self.gifQueue.maxConcurrentOperationCount = 4;
        
        self.recordingQueue = [[NSOperationQueue alloc] init];
        self.recordingQueue.maxConcurrentOperationCount = 4;
    }
    return self;
}

#pragma mark GIF and JPEG generation

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

#pragma mark - Queue operations
- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl
                        addToGroup:(YAGroup*)group {
    
    YAVideo *video = [YAVideo video];
    YACreateRecordingOperation *recordingOperation = [[YACreateRecordingOperation alloc] initRecordingURL:recordingUrl group:group video:video];
    [self.recordingQueue addOperation:recordingOperation];
    
    YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video];
    [gifCreationOperation addDependency:recordingOperation];
    [self.recordingQueue addOperation:gifCreationOperation];
}

- (void)createAssetsForGroup:(YAGroup*)group {
    for(YAVideo *video in group.videos) {
        [self createAssetsForVideo:video inGroup:group];
    }
}

- (void)stopAllJobsWithCompletion:(stopOperationsCompletion)completion {
    [self.downloadQueue cancelAllOperations];
    [self.gifQueue cancelAllOperations];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.downloadQueue waitUntilAllOperationsAreFinished];
        [self.gifQueue waitUntilAllOperationsAreFinished];
        
        if(completion)
            completion();
        
        NSLog(@"All jobs stopped");
    });
}

- (void)createAssetsForVideo:(YAVideo*)video inGroup:(YAGroup*)group
{
    if(!video.movFilename.length) {
       [self addVideoDownloadOperationForVideo:video];
    }
    else if(!video.gifFilename.length) {
        [self addGifCreationOperationForVideo:video];
    }
}

- (void)addGifCreationOperationForVideo:(YAVideo*)video {
    YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video];
    [self.gifQueue addOperation:gifCreationOperation];
    NSLog(@"Gif creation operation created for %@", video.localId);
}

- (void)addVideoDownloadOperationForVideo:(YAVideo*)video {
    NSURL *url = [NSURL URLWithString:video.url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.name = video.url;
    //    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData* videoData = (NSData*)responseObject;
        
        NSString *hashStr       = [YAUtils uniqueId];
        NSString *moveFilename  = [hashStr stringByAppendingPathExtension:@"mov"];
        NSString *movPath       = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
        NSURL    *movURL        = [NSURL fileURLWithPath:movPath];
        
        BOOL result = [videoData writeToURL:movURL atomically:YES];
        if(result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [video.realm beginWriteTransaction];
                video.movFilename = moveFilename;
                [video.realm commitWriteTransaction];
                
                NSLog(@"remote video downloaded for %@", video.localId);
                [self addGifCreationOperationForVideo:video];
            });
        }
        else {
            NSLog(@"Error saving remote video data");
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(error.code == NSURLErrorCancelled) {
            NSLog(@"video download cancelled");
        }
        else {
            NSLog(@"Error downloading video %@", error);
        }
    }];

    //uncomment me if you want to track progress
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_DOWNLOAD_PART_NOTIFICATION object:video.url userInfo:@{@"progress": [NSNumber numberWithFloat:(totalBytesRead - totalBytesRead * 0.3f) /(float)totalBytesExpectedToRead]}];
    }];
    
    NSLog(@"download operation created %@", operation.name);
    [self.downloadQueue addOperation:operation];
}

- (BOOL)urlDownloadInProgress:(NSString*)url {
    for(NSOperation *op in self.downloadQueue.operations) {
        if(!op.isExecuting)
            continue;
        
        if([op.name isEqualToString:url])
            return YES;
    }
    return NO;
}

- (void)waitForAllOperationsToFinish
{
    [self.recordingQueue waitUntilAllOperationsAreFinished];
    [self.downloadQueue waitUntilAllOperationsAreFinished];
    [self.gifQueue waitUntilAllOperationsAreFinished];
}

@end
