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
@property (atomic, assign) BOOL inProgress;

@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@end

CGFloat degreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

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
        self.downloadQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

#pragma mark GIF and JPEG generation

- (void)createJPGAndGIFForVideo:(YAVideo*)video {
    if([self.videosToProcess containsObject:video])
        return;
    
    [self.videosToProcess addObject:video];
    
    if(!self.inProgress)
        [self processNextVideoAsync];
}

- (void)processNextVideoAsync {
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
    [self.videosToProcess addObject:video];
    
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
                    imageGenerator.maximumSize = CGSizeMake(imageGenerator.asset.naturalSize.width/2, imageGenerator.asset.naturalSize.height/2);
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
                                        
                                        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_VIDEO_TAKEN_NOTIFICATION object:video];
                                        
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
                                            [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_VIDEO_NOTIFICATION object:video];
                                            
                                            self.inProgress = NO;
                                            [self.videosToProcess removeObject:video];
                                            [self processNextVideoAsync];
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
                break;
            case AVKeyValueStatusFailed:
                NSLog(@"createJPGAndGIFForVideo Error finding duration");
                [self.videosToProcess removeObject:video];
                break;
            case AVKeyValueStatusCancelled:
                NSLog(@"createJPGAndGIFForVideo Cancelled finding duration");
                [self.videosToProcess removeObject:video];
                break;
            default:
                break;
        }
    }];
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
        CFRelease(destination);
        return;
    }
    
    CFRelease(destination);
    
    handler(nil);
}

#pragma mark - Camera roll
- (void)addBumberToVideoAtURLAndSaveToCameraRoll:(NSURL*)videoURL {
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
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError: contextInfo:), nil);
    }];
}

-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error)
    {
        [AZNotification showNotificationWithTitle:NSLocalizedString(@"Can't save photos", @"")
                                       controller:[UIApplication sharedApplication].keyWindow.rootViewController
                                 notificationType:AZNotificationTypeError
                                     startedBlock:nil];
    }
    else
    {
        [AZNotification showNotificationWithTitle:NSLocalizedString(@"Video saved to camera roll successfully", @"")
                                       controller:[UIApplication sharedApplication].keyWindow.rootViewController
                                 notificationType:AZNotificationTypeMessage
                                     startedBlock:nil];
    }
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
            videoCompositionInstruction.layerInstructions = @[layerInstruction];
        } else {
            CGFloat xMove = [UIScreen mainScreen].bounds.size.width/2;
            CGFloat yMove = [UIScreen mainScreen].bounds.size.height/2;
            CGAffineTransform transform = CGAffineTransformTranslate(assetTrack.preferredTransform,
                                                                     xMove,
                                                                     yMove);
     
            [layerInstruction setTransform:transform atTime:kCMTimeZero];
            videoCompositionInstruction.layerInstructions = @[layerInstruction];
        }
        
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
        
        [group.videos insertObject:video atIndex:0];
        [group.realm commitWriteTransaction];
        
        //start uploading while generating gif
        [[YAServerTransactionQueue sharedQueue] addUploadVideoTransaction:video];
        
        [video generateGIF];
    });
}

- (void)createVideoFromRemoteDictionary:(NSDictionary*)videoDic addToGroup:(YAGroup*)group {
    NSString *hashStr = [YAUtils uniqueId];
    NSString *moveFilename = [hashStr stringByAppendingPathExtension:@"mov"];
    NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
    NSURL    *movURL = [NSURL fileURLWithPath:movPath];
    
    dispatch_async(self.downloadQueue, ^{
        NSURL *remoteURL = [NSURL URLWithString:videoDic[YA_VIDEO_ATTACHMENT]];
        NSData *data = [NSData dataWithContentsOfURL:remoteURL];
        BOOL result = [data writeToURL:movURL atomically:YES];
        if(!result) {
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *videoId = videoDic[YA_RESPONSE_ID];
            
            [group.realm beginWriteTransaction];
            
            YAVideo *video = [YAVideo video];
            video.serverId = videoId;
            video.creator = videoDic[YA_RESPONSE_USER][YA_RESPONSE_NAME];
            NSTimeInterval timeInterval = [videoDic[YA_VIDEO_READY_AT] integerValue];
            video.createdAt = [NSDate dateWithTimeIntervalSince1970:timeInterval];
            video.url = videoDic[YA_VIDEO_ATTACHMENT];
            video.movFilename = moveFilename;
            [group.videos insertObject:video atIndex:0];
            
            [group.realm commitWriteTransaction];
            
            [video generateGIF];
        });
    });
}

@end
