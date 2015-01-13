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

@interface YAAssetsCreator ()
@property (atomic, strong) NSMutableArray *videosToProcess;
@property (atomic, strong) NSMutableSet *failedVideoIds;

@property (atomic, assign) BOOL inProgress;

@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@property (nonatomic, strong) NSMutableDictionary *gifCreationOpearationsQueueDict;
@property (nonatomic, strong) NSOperationQueue *videoDownloadingQueue;
@property (nonatomic, copy) cameraRollCompletion cameraRollCompletionBlock;
@end

#warning TODO: 1. use operation queue for downloads and gif generations

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
        self.failedVideoIds = [NSMutableSet set];
        //concurent downloads but serial gif generation..
        self.downloadQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        self.gifCreationOpearationsQueueDict = [NSMutableDictionary new];
        
        self.videoDownloadingQueue = [NSOperationQueue new];
        self.videoDownloadingQueue.underlyingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        self.videoDownloadingQueue.maxConcurrentOperationCount = 2;
    }
    return self;
}

- (NSOperationQueue*)gifCreationOperationQueueForGroup:(YAGroup*)group
{
    if ([self.gifCreationOpearationsQueueDict.allKeys containsObject:group.localId]) {
        return [self.gifCreationOpearationsQueueDict objectForKey:group.localId];
    } else {
        //
        NSOperationQueue *opQueue = [NSOperationQueue new];
        opQueue.underlyingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        [self.gifCreationOpearationsQueueDict setObject:opQueue forKey:group.localId];
        return opQueue;
    }
}

#pragma mark GIF and JPEG generation

- (void)createJPGAndGIFForVideo:(YAVideo*)video {
    NSBlockOperation *operation = [self gifCreationOperationForVideo:video];
    NSOperationQueue *opQueue = [self gifCreationOperationQueueForGroup:video.group];
    [opQueue addOperation:operation];
}

- (NSBlockOperation*)gifCreationOperationForVideo:(YAVideo*)video {
    NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:video.movFilename];
    NSURL *movURL = [NSURL fileURLWithPath:movPath];
    NSArray *keys = [NSArray arrayWithObject:@"duration"];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
       
        
        [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
            NSError *error = nil;
            AVKeyValueStatus valueStatus = [asset statusOfValueForKey:@"duration" error:&error];
            switch (valueStatus) {
                case AVKeyValueStatusLoaded:
                    [self processAsset:asset forVideo:video];
                    break;
                case AVKeyValueStatusFailed:
                    NSLog(@"createJPGAndGIFForVideo Error finding duration");
                    break;
                case AVKeyValueStatusCancelled:
                    NSLog(@"createJPGAndGIFForVideo Cancelled finding duration");
                    break;
                default:
                    break;
            }
        }];
    }];
    
    return operation;
}

- (void)processAsset:(AVURLAsset*)asset forVideo:(YAVideo*)video {
    if ([asset tracksWithMediaCharacteristic:AVMediaTypeVideo]) {
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        imageGenerator.appliesPreferredTrackTransform = YES;
        
        NSArray* allVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if ([allVideoTracks count] > 0) {
            AVAssetTrack* track = [[asset tracksWithMediaType:AVMediaTypeVideo]
                                   objectAtIndex:0];
            CGSize size = [track naturalSize];
            imageGenerator.maximumSize = CGSizeMake(size.width/2, size.height/2);
        }
        
        Float64 movieDuration = CMTimeGetSeconds([asset duration]);
        NSUInteger framesCount = movieDuration * 10;
        NSLog(@"movie duration: %f", movieDuration);
        
        NSMutableArray *times = [NSMutableArray arrayWithCapacity:framesCount];
        for (int i = 0; i < framesCount; i++) {
            CGFloat frac = (CGFloat)i/(CGFloat)framesCount;
            [times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(movieDuration*frac, 30)]];
        }
        
        __block NSMutableArray *imagesArray = [NSMutableArray arrayWithCapacity:framesCount];

        [imageGenerator generateCGImagesAsynchronouslyForTimes:times
                                             completionHandler:^(CMTime requestedTime,
                                                                 CGImageRef image,
                                                                 CMTime actualTime,
                                                                 AVAssetImageGeneratorResult result,
                                                                 NSError *error) {
                                                 
                                                 if (result == AVAssetImageGeneratorSucceeded) {
                                                     UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
                                                     newImage = [YAAssetsCreator deviceSpecificCroppedThumbnailFromImage:newImage];

                                                     [imagesArray addObject:newImage];
                                                     //Always perform on the thread where video was created
                                                     __block NSString *filename = nil;
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         if (![video isInvalidated])
                                                         {
                                                             filename = [video.movFilename stringByDeletingPathExtension];
                                                         }
                                                     });
                                                     if([imagesArray count] == 1) {
                                                         
                                                         NSString *jpgFilename = [filename stringByAppendingPathExtension:@"jpg"];
                                                         NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
                                                         if([UIImageJPEGRepresentation(newImage, 0.8) writeToFile:jpgPath atomically:NO]) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 [video.realm beginWriteTransaction];
                                                                 video.jpgFilename = jpgFilename;
                                                                 [video.realm commitWriteTransaction];
                                                                 
                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:video];
                                                                 
                                                                 return;
                                                             });
                                                         }
                                                         else {
                                                             NSLog(@"Error: Can't save jpg by some reason...");
                                                             return;
                                                         }
                                                     }
                                                     
                                                     if (imagesArray.count == framesCount) {
                                                         NSString *gifFilename = [filename stringByAppendingPathExtension:@"gif"];
                                                         NSString *gifPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:gifFilename];
                                                         NSURL *gifURL = [NSURL fileURLWithPath:gifPath];
                                                         
                                                         [YAAssetsCreator makeAnimatedGifAtUrl:gifURL fromArray:imagesArray completionHandler:^(NSError *error) {
                                                             if(error) {
                                                                 NSLog(@"Error occured: %@", error);
                                                                 [self.videosToProcess removeObject:video];
                                                             }
                                                             else {
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     NSLog(@"%@", gifURL);
                                                                     [video.realm beginWriteTransaction];
                                                                     video.gifFilename = gifFilename;
                                                                     [video.realm commitWriteTransaction];
                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:video];
                                                                 });
                                                             }
                                                         }];
                                                     }
                                                     
                                                 }
                                                 
                                                 if (result == AVAssetImageGeneratorFailed) {
                                                     NSLog(@"AVAssetImageGeneratorFailed with error: %@", [error localizedDescription]);
                                                 }
                                                 if (result == AVAssetImageGeneratorCancelled) {
                                                     NSLog(@"AVAssetImageGeneratorCancelled");
                                                 }
                                             }];
    }
}

- (void)generateNextGIFAsync {
    if(!self.videosToProcess.count) {
        return;
    }
    
    self.inProgress = YES;
    YAVideo *video = self.videosToProcess[0];
    
    NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:video.movFilename];
    NSURL *movURL = [NSURL fileURLWithPath:movPath];
    
    NSArray *keys = [NSArray arrayWithObject:@"duration"];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
    
    NSString *filename = [video.movFilename stringByDeletingPathExtension];
    
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
        NSError *error = nil;
        AVKeyValueStatus valueStatus = [asset statusOfValueForKey:@"duration" error:&error];
        switch (valueStatus) {
            case AVKeyValueStatusLoaded:
                if ([asset tracksWithMediaCharacteristic:AVMediaTypeVideo]) {
                    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                    
                    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
                    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
                    imageGenerator.appliesPreferredTrackTransform = YES;
                    
                    NSArray* allVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                    if ([allVideoTracks count] > 0) {
                        AVAssetTrack* track = [[asset tracksWithMediaType:AVMediaTypeVideo]
                                               objectAtIndex:0];
                        CGSize size = [track naturalSize];
                        imageGenerator.maximumSize = CGSizeMake(size.width/2, size.height/2);
                    }
                    
                    Float64 movieDuration = CMTimeGetSeconds([asset duration]);
                    NSUInteger framesCount = movieDuration * 10;
                    NSLog(@"movie duration: %f", movieDuration);
                    
                    NSMutableArray *times = [NSMutableArray arrayWithCapacity:framesCount];
                    for (int i = 0; i < framesCount; i++) {
                        CGFloat frac = (CGFloat)i/(CGFloat)framesCount;
                        [times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(movieDuration*frac, 30)]];
                    }
                    
                    __block NSMutableArray *imagesArray = [NSMutableArray arrayWithCapacity:framesCount];
                    
                    [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime,
                                                                                                     CGImageRef image,
                                                                                                     CMTime actualTime,
                                                                                                     AVAssetImageGeneratorResult result,
                                                                                                     NSError *error) {
                        
                        if (result == AVAssetImageGeneratorSucceeded) {
                            UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
                            newImage = [YAAssetsCreator deviceSpecificCroppedThumbnailFromImage:newImage];
                            //UIImageWriteToSavedPhotosAlbum(newImage, self, @selector(imageSavedToPhotosAlbum: didFinishSavingWithError: contextInfo:), nil);
                            [imagesArray addObject:newImage];
                            
                            if([imagesArray count] == 1) {
                                NSString *jpgFilename = [filename stringByAppendingPathExtension:@"jpg"];
                                NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
                                if([UIImageJPEGRepresentation(newImage, 0.8) writeToFile:jpgPath atomically:NO]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [video.realm beginWriteTransaction];
                                        video.jpgFilename = jpgFilename;
                                        [video.realm commitWriteTransaction];
                                        
                                        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:video];
                                        
                                        return;
                                    });
                                }
                                else {
                                    NSLog(@"Error: Can't save jpg by some reason...");
                                    return;
                                }
                            }
                            
                            if (imagesArray.count == framesCount) {
                                NSString *gifFilename = [filename stringByAppendingPathExtension:@"gif"];
                                NSString *gifPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:gifFilename];
                                NSURL *gifURL = [NSURL fileURLWithPath:gifPath];
                                
                                [YAAssetsCreator makeAnimatedGifAtUrl:gifURL fromArray:imagesArray completionHandler:^(NSError *error) {
                                    if(error) {
                                        NSLog(@"Error occured: %@", error);
                                        [self.videosToProcess removeObject:video];
                                    }
                                    else {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [video.realm beginWriteTransaction];
                                            video.gifFilename = gifFilename;
                                            [video.realm commitWriteTransaction];
                                            [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:video];
                                            
                                            [self finishGIFGenerationAndStartNext:video errorsDuringProcessing:NO];
                                        });
                                    }
                                }];
                            }
                            
                        }
                        
                        if (result == AVAssetImageGeneratorFailed) {
                            NSLog(@"AVAssetImageGeneratorFailed with error: %@", [error localizedDescription]);
                            [self finishGIFGenerationAndStartNext:video errorsDuringProcessing:YES];
                        }
                        if (result == AVAssetImageGeneratorCancelled) {
                            NSLog(@"AVAssetImageGeneratorCancelled");
                            [self finishGIFGenerationAndStartNext:video errorsDuringProcessing:YES];
                        }
                    }];
                }
                break;
            case AVKeyValueStatusFailed:
                NSLog(@"createJPGAndGIFForVideo Error finding duration");
                [self finishGIFGenerationAndStartNext:video errorsDuringProcessing:YES];
                break;
            case AVKeyValueStatusCancelled:
                NSLog(@"createJPGAndGIFForVideo Cancelled finding duration");
                [self finishGIFGenerationAndStartNext:video errorsDuringProcessing:YES];
                break;
            default:
                break;
        }
    }];
}

- (void)finishGIFGenerationAndStartNext:(YAVideo*)video errorsDuringProcessing:(BOOL)errors {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.inProgress = NO;
        [self.videosToProcess removeObject:video];
        
        if(errors) {
            [YAUtils showNotification:[NSString stringWithFormat:@"Error fetching video with id %@", video.serverId] type:AZNotificationTypeError];
            
            [self.failedVideoIds addObject:video.serverId];
            //[video removeFromCurrentGroup];
        }
        
        [self generateNextGIFAsync];
    });
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
}


+ (UIImage *)deviceSpecificCroppedThumbnailFromImage:(UIImage*)img {
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
    
    //        if(!saved) {
    //            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    //            saved = YES;
    //        }
    
    
    return result;
}

+ (void)makeAnimatedGifAtUrl:(NSURL*)fileURL fromArray:(NSArray*)images completionHandler:(gifCreatedCompletionHandler)handler {
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @0.05f, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, images.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (UIImage *frameImage in images) {
        @autoreleasepool {
            CGImageDestinationAddImage(destination, frameImage.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
        handler([NSError errorWithDomain:@"YA" code:0 userInfo:nil]);
        if (destination) { CFRelease(destination); }
        return;
    }
    
    CFRelease(destination);
    
    handler(nil);
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
- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl addToGroup:(YAGroup*)group {
    
    NSString *hashStr = [YAUtils uniqueId];
    NSString *moveFilename = [hashStr stringByAppendingPathExtension:@"mov"];
    NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
    NSURL    *movURL = [NSURL fileURLWithPath:movPath];
    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:recordingUrl toURL:movURL error:&error];
    if(error) {
        NSLog(@"Error in createVideoFromRecodingURL, can't move recording, %@", error);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [group.realm beginWriteTransaction];
        YAVideo *video = [YAVideo video];
        video.creator = [[YAUser currentUser] username];
        video.createdAt = [NSDate date];
        video.movFilename = moveFilename;
        video.group = group;
        [group.videos insertObject:video atIndex:0];
        
        [group.realm commitWriteTransaction];
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_ADDED_NOTIFICATION object:video];
        
        //start uploading while generating gif
        [[YAServerTransactionQueue sharedQueue] addUploadVideoTransaction:video];
        
        [self createJPGAndGIFForVideo:video];
    });
}

- (void)createVideoFromRemoteDictionary:(NSDictionary*)videoDic addToGroup:(YAGroup*)group {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *videoId = videoDic[YA_RESPONSE_ID];
        if([self.failedVideoIds containsObject:videoId]) {
            NSLog(@"%@ failed last time, skipping...", videoId);
        }
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
        
        [self getRemoteContentForVideo:video];
    });
}

- (void)getRemoteContentForVideo:(YAVideo*)video {
    NSString *videoUrl = video.url;

        NSURL *remoteURL = [NSURL URLWithString:videoUrl];
        NSLog(@"getRemoteContentForVideo: %@", remoteURL.absoluteString);
 
    
    NSBlockOperation *videoDownloadOpertaion = [NSBlockOperation blockOperationWithBlock:^{
        NSData *data = [NSData dataWithContentsOfURL:remoteURL];
        NSLog(@"getRemoteContentForVideo done for %@", remoteURL);
        
        NSString *hashStr = [YAUtils uniqueId];
        NSString *moveFilename = [hashStr stringByAppendingPathExtension:@"mov"];
        NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
        NSURL    *movURL = [NSURL fileURLWithPath:movPath isDirectory:NO];
        
        BOOL result = [data writeToURL:movURL atomically:YES];
        if(!result) {
            NSLog(@"Critical Error: can't save video data from remote data, url %@", remoteURL);
        }
        else {
                dispatch_async(dispatch_get_main_queue(), ^{

                    
                    [video.realm beginWriteTransaction];
                    video.movFilename = moveFilename;
                    [video.realm commitWriteTransaction];
                    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:video];
                    
                    [self createJPGAndGIFForVideo:video];
                });
        }

    }];
    
    [self.videoDownloadingQueue addOperation:videoDownloadOpertaion];
}

- (void)createAssetsForGroup:(YAGroup*)group {
    [[self.gifCreationOpearationsQueueDict objectForKey:group] setSuspended:NO];
    for(YAVideo *video in group.videos) {
        if(video.url.length && !video.movFilename.length)
            [self getRemoteContentForVideo:video];
        else if(video.movFilename.length && !video.gifFilename.length) {
            [self createJPGAndGIFForVideo:video];
        }
    }
}

- (void)stopAllJobsForGroup:(YAGroup*)group {
        #warning TODO: 2. kill all downloads and gif generations when group is changed
    [self.videoDownloadingQueue cancelAllOperations];
    [[self.gifCreationOpearationsQueueDict objectForKey:group] setSuspended:YES];
}

- (void)waitForAllOperationsToFinish
{
    [self.videoDownloadingQueue cancelAllOperations];
    NSArray *keys = self.gifCreationOpearationsQueueDict.allKeys;
    for (NSString *key in keys) {
        NSOperationQueue *que = [self.gifCreationOpearationsQueueDict objectForKey:key];
        [que waitUntilAllOperationsAreFinished];
    }
}

@end
