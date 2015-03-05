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
#import "YADownloadManager.h"

@interface YAAssetsCreator ()
@property (nonatomic, copy) cameraRollCompletion cameraRollCompletionBlock;
@property (nonatomic, strong) NSOperationQueue *gifQueue;
@property (nonatomic, strong) NSOperationQueue *jpgQueue;
@property (nonatomic, strong) NSOperationQueue *recordingQueue;
@property (strong) NSMutableArray *prioritizedVideos;
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
        self.gifQueue = [[NSOperationQueue alloc] init];
        self.gifQueue.maxConcurrentOperationCount = 4;
        
        self.jpgQueue = [[NSOperationQueue alloc] init];
        self.jpgQueue.maxConcurrentOperationCount = 2;
        
        self.recordingQueue = [[NSOperationQueue alloc] init];
        self.recordingQueue.maxConcurrentOperationCount = 4;
        
        self.prioritizedVideos = [NSMutableArray new];
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
            // Unkoment for medium quality
//            NSLog(@"%@", NSStringFromCGSize(assetTrack.naturalSize));
//            NSLog(@"%@", NSStringFromCGRect([UIScreen mainScreen].nativeBounds));
//            CGAffineTransform transform = CGAffineTransformTranslate(assetTrack.preferredTransform,
//                                                                     50.f,
//                                                                     0.0f);
            
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
    
    YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video quality:YAGifCreationNormalQuality];
    [gifCreationOperation addDependency:recordingOperation];
    [self.recordingQueue addOperation:gifCreationOperation];
}

- (void)stopAllJobsWithCompletion:(stopOperationsCompletion)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[YADownloadManager sharedManager] cancelAllJobs];
        [self.gifQueue cancelAllOperations];
    
        
        [[YADownloadManager sharedManager] waitUntilAllJobsAreFinished];
        [self.gifQueue waitUntilAllOperationsAreFinished];
        
        if(completion)
            completion();
        
        //meaning recording queue will still be alive, as it's important to save recordings
        NSLog(@"All jobs stopped");
    });
}

- (void)enqueueAssetsCreationJobForVideos:(NSArray*)videos prioritizeDownload:(BOOL)prioritize {
    void (^enqueueBlock)(void) = ^{
        
#warning refactor YADownloadManager in a way the following block can be executed not on main thread, that will fix the freeze on collection view when next 100 items are enqueued for download
        
        for(YAVideo *video in videos) {
            if(video.url.length && !video.movFilename.length ) {
                if(prioritize)
                    [[YADownloadManager sharedManager] prioritizeJobForVideo:video];
                else
                    [[YADownloadManager sharedManager] addJobForVideo:video];
            }
            else if(video.movFilename.length && !video.gifFilename.length) {
                if(prioritize) {
                    [self.prioritizedVideos removeObject:video];
                    [self addGifCreationOperationForVideo:video quality:YAGifCreationNormalQuality];
                }
                
            }
        }
    };
    
    if(prioritize) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.gifQueue cancelAllOperations];
            
            self.prioritizedVideos = [NSMutableArray arrayWithArray:videos];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                enqueueBlock();
            });
        });
    }
    else {
        enqueueBlock();
    }
}

- (void)addGifCreationOperationForVideo:(YAVideo*)video quality:(YAGifCreationQuality)quality {
    if(!video.movFilename.length)
        return;
    
    if([self gifOperationInProgressForUrl:video.url])
        return;
    
    YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video quality:quality];
    [self.gifQueue addOperation:gifCreationOperation];
}

- (BOOL)gifOperationInProgressForUrl:(NSString*)url {
    for(NSOperation *op in self.gifQueue.operations) {
        if([op.name isEqualToString:url]) {
            return YES;
        }
    }
    return NO;
}

- (void)cancelGifOperations {
    [self.gifQueue cancelAllOperations];
}

- (void)waitForAllOperationsToFinish
{
    [self.recordingQueue waitUntilAllOperationsAreFinished];
    [[YADownloadManager sharedManager] waitUntilAllJobsAreFinished];
    [self.gifQueue waitUntilAllOperationsAreFinished];
}

- (void)enqueueJpgCreationForVideo:(YAVideo*)video {
    [self.jpgQueue addOperationWithBlock:^{
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:video.movFilename];
            NSURL *movURL = [NSURL fileURLWithPath:movPath];
            NSString *filename =  [video.movFilename stringByDeletingPathExtension];
            NSString *jpgFilename = [filename stringByAppendingPathExtension:@"jpg"];
            NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
                
                AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
                imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
                imageGenerator.appliesPreferredTrackTransform = YES;
                imageGenerator.maximumSize = CGSizeMake([[UIScreen mainScreen] applicationFrame].size.height/2, [[UIScreen mainScreen] applicationFrame].size.height/2);
                CMTime time = CMTimeMakeWithSeconds(0, asset.duration.timescale);
                
                NSError *error;
                CMTime actualTime;
                CGImageRef image = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
                UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
                if(newImage) {
                    newImage = [self deviceSpecificCroppedThumbnailFromImage:newImage];
                    [self createJpgFromImage:newImage atPath:(NSString*)jpgPath forVideo:video];
                    
                    CFRelease(image);
                }
                
                dispatch_semaphore_signal(sema);
            });
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self jpgCreatedForVideo:video];
        });
    
    }];
}

- (UIImage *)deviceSpecificCroppedThumbnailFromImage:(UIImage*)img {
    CGSize gifFrameSize = CGSizeMake([[UIScreen mainScreen] applicationFrame].size.width/2, [[UIScreen mainScreen] applicationFrame].size.height/4);
    
    CGFloat widthDiff = img.size.width - gifFrameSize.width ;
    CGFloat heightDiff = img.size.height - gifFrameSize.height;
    
    CGRect cropRect = CGRectMake(widthDiff/2, heightDiff/2, gifFrameSize.width, gifFrameSize.height);
    
    if (img.scale > 1.0f) {
        cropRect = CGRectMake(cropRect.origin.x * img.scale,
                              cropRect.origin.y * img.scale,
                              cropRect.size.width * img.scale,
                              cropRect.size.height * img.scale);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(img.CGImage, cropRect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:img.scale orientation:img.imageOrientation];
    CGImageRelease(imageRef);
    
    
    return result;
}

- (BOOL)createJpgFromImage:(UIImage*)image atPath:(NSString*)jpgPath forVideo:(YAVideo*)video {
    BOOL result = YES;
    if([UIImageJPEGRepresentation(image, 0.8) writeToFile:jpgPath atomically:NO]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [video.realm beginWriteTransaction];
            video.jpgFilename = jpgPath.lastPathComponent;
            [video.realm commitWriteTransaction];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:video];
        });
    }
    else {
        NSLog(@"Error: Can't save jpg by some reason...");
        result = NO;
    }
    return result;
}

#pragma mark -
- (void)jpgCreatedForVideo:(YAVideo*)video {
    if([self.prioritizedVideos containsObject:video]) {
        [self.prioritizedVideos removeObject:video];
        [self addGifCreationOperationForVideo:video quality:YAGifCreationNormalQuality];
    }
}
@end
