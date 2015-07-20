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
#import "YADownloadManager.h"
#import "UIImage+Resize.h"
#import "YACameraManager.h"

@interface YAAssetsCreator ()
@property (nonatomic, strong) NSOperationQueue *gifQueue;
@property (nonatomic, strong) NSOperationQueue *jpgQueue;

@property (nonatomic, strong) UIImage *capturePreviewImage;

@property (nonatomic, strong) AVAssetExportSession *exportSession;
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

#pragma mark GIF and JPEG generation

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
}


#pragma mark - Video composition

- (void)concatenateAssetsAtURLs:(NSArray *)assetURLs
                  withOutputURL:(NSURL *)outputURL
                  exportQuality:(NSString *)exportQuality
                     completion:(videoProcessingCompletion)completion {
    AVMutableComposition *combinedVideoComposition = [self buildVideoSequenceCompositionFromURLS:assetURLs];
    if (!exportQuality) exportQuality = AVAssetExportPresetMediumQuality;
    
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:combinedVideoComposition
                                                          presetName:exportQuality];
    
    self.exportSession.outputURL = outputURL;
    self.exportSession.outputFileType = AVFileTypeMPEG4;
    self.exportSession.shouldOptimizeForNetworkUse = YES;
    if([UIDevice currentDevice].systemVersion.floatValue >= 8)
        self.exportSession.canPerformMultiplePassesOverSourceMediaData = YES;
    
    __weak __typeof(self)weakSelf = self;
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^(void ) {
        if (weakSelf.exportSession.status == AVAssetExportSessionStatusCompleted){
            completion(weakSelf.exportSession.outputURL, nil);
        } else {
            completion(nil, [NSError new]);
        }
        weakSelf.exportSession = nil;
    }];
}

- (void)addBumberToVideoAtURL:(NSURL *)videoURL completion:(videoProcessingCompletion)completion {
    NSURL *outputUrl = [YAUtils urlFromFileName:@"YAGA.mp4"];
    [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
    NSMutableArray *assetURLsToConcatenate = [NSMutableArray arrayWithObject:videoURL];
    NSString *bumperPath = [[NSBundle mainBundle] pathForResource:@"bumper" ofType:@"mp4"];
    [assetURLsToConcatenate addObject:[NSURL fileURLWithPath:bumperPath]];
    
    [self concatenateAssetsAtURLs:assetURLsToConcatenate
                    withOutputURL:outputUrl
                    exportQuality:AVAssetExportPresetMediumQuality
                       completion:^(NSURL *filePath, NSError *error) {
                           if(completion)
                               completion(filePath, error);
                       }];
}


- (AVMutableComposition*)buildVideoSequenceCompositionFromURLS:(NSArray *)assetURLs {
    if (![assetURLs count]) return nil;
    
    AVAsset *firstAsset = [AVAsset assetWithURL:[assetURLs firstObject]];
    
    CGSize vidsize = ((AVAssetTrack *)[firstAsset tracksWithMediaType:AVMediaTypeVideo].firstObject).naturalSize;
    DLog(@"vidsize x: %f, y: %f", vidsize.width, vidsize.height);
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *firstVideoTrack = [[firstAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (firstVideoTrack && compositionVideoTrack) {
        [compositionVideoTrack setPreferredTransform:firstVideoTrack.preferredTransform]; // Rotate the video
    }
    
    CMTime vidLength = CMTimeMake(0, firstAsset.duration.timescale);
    
    for (int i = 0; i < [assetURLs count]; i++) {
        AVAsset *currentAsset = [AVAsset assetWithURL:assetURLs[i]];
        AVAssetTrack *videoTrack = [[currentAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVAssetTrack *audioTrack = [[currentAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        CMTime assetDuration = currentAsset.duration;
        CMTime blipDuration = CMTimeMakeWithSeconds(0.066f, assetDuration.timescale);
        if ((CMTimeCompare(assetDuration, blipDuration) > 0) && (i < [assetURLs count] - 1)) {
            // shave off last .05 seconds to remove black blip. Only if the asset is long enough and not last clip.
            assetDuration.value -= blipDuration.value;
        }
        
        if (videoTrack) {
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetDuration)
                                           ofTrack:videoTrack atTime:vidLength error:nil];
        }
        if (audioTrack) {
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(kCMTimeZero, assetDuration))
                                           ofTrack:audioTrack atTime:vidLength error:nil];
        }
        
        vidLength.value += assetDuration.value;
    }
    
    return mixComposition;
}

#pragma mark - Queue operations

+ (UIInterfaceOrientation)orientationForTrack:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIInterfaceOrientationPortrait;
}


+ (void)reformatExternalVideoAtUrl:(NSURL *)videoUrl withCompletion:(videoProcessingCompletion)completion {
    
    AVAsset *asset = [AVAsset assetWithURL:videoUrl];
    CGSize vidSize = ((AVAssetTrack *)([asset tracksWithMediaType:AVMediaTypeVideo][0])).naturalSize;
    CGSize correctSize = CGSizeMake(480.0, 640.0);
    
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    
    movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
//    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = NO;

//    UIInterfaceOrientation orientation = [self orientationForTrack:asset];
   
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/PreProcessedMovie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];;
    [videoSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [videoSettings setObject:[NSNumber numberWithInteger:480] forKey:AVVideoWidthKey];
    [videoSettings setObject:[NSNumber numberWithInteger:640] forKey:AVVideoHeightKey];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:correctSize fileType:AVFileTypeMPEG4 outputSettings:videoSettings];

    CGFloat xMultiple = vidSize.width / correctSize.width;
    CGFloat yMultiple = vidSize.height / correctSize.height;
    
    if (xMultiple > yMultiple) {
        // The video needs to trim off the sides
        CGFloat croppedWidth = correctSize.width * yMultiple;
        CGRect cropRegion = CGRectMake(((vidSize.width - croppedWidth)/vidSize.width) / 2, 0, croppedWidth / vidSize.width, 1);
        filter = [[GPUImageCropFilter alloc] initWithCropRegion:cropRegion];
        [movieFile addTarget:filter];
        [filter addTarget:movieWriter];

    } else {
        // The video is skinnier than 3:4. Most likely a snapchat. Convert to 3:4 & Leave black bars on the sides.
        filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 1, 1)];
        [filter forceProcessingAtSizeRespectingAspectRatio:correctSize];
        [movieFile addTarget:filter];
        [filter addTarget:movieWriter];
    }
    

    // This might fuck stuff up IDK
//    switch (orientation)
//    {
//        case UIInterfaceOrientationLandscapeLeft:
//            [filter setInputRotation:kGPUImageNoRotation atIndex:0];
//            
//            break;
//        case UIInterfaceOrientationLandscapeRight:
//            [filter setInputRotation:kGPUImageRotate180 atIndex:0];
//            
//            break;
//        case UIInterfaceOrientationPortraitUpsideDown:
//            [filter setInputRotation:kGPUImageRotateLeft atIndex:0];
//            
//            break;
//        default:
//            [filter setInputRotation:kGPUImageRotateRight atIndex:0];
//            
//    };
    
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                   [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                                   [ NSNumber numberWithFloat: 16000.0 ], AVSampleRateKey,
                                   [ NSData dataWithBytes:&channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
                                   [ NSNumber numberWithInt: 32000 ], AVEncoderBitRateKey,
                                   nil];
    
    movieWriter.shouldPassthroughAudio = YES; // default YES
//    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0){
////        [movieWriter setHasAudioTrack:YES audioSettings:audioSettings];
//        [movieWriter setHasAudioTrack:YES audioSettings:nil];
//        movieFile.audioEncodingTarget = movieWriter;
//    } else {//no audio
        [movieWriter setHasAudioTrack:NO];
        movieFile.audioEncodingTarget = nil;
//    }

    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];

    __weak typeof(movieWriter) weakMovieWriter = movieWriter;
    [movieWriter setCompletionBlock:^{
        NSLog(@"Completed Successfully");
        [movieFile removeTarget:filter];
        [filter removeTarget:weakMovieWriter];
        [weakMovieWriter finishRecording];
        [movieFile description]; // just so it gets retained :)
        [videoSettings description]; // just so it gets retained :)
        [movieURL description]; // just so it gets retained :)
        [asset description]; // just 9so it gets retained :)
//        [audioSettings description]; // just so it gets retained :)
        completion(movieURL, nil);
    }];
    
//    [movieWriter setFailureBlock:^(NSError *error) {
//        NSLog(@"Completed Successfully");
//        [filter removeTarget:weakMovieWriter];
//        [weakMovieWriter finishRecording];
//        [movieFile description]; // just so it gets retained :)
//        [videoSettings description]; // just so it gets retained :)
//        [movieURL description]; // just so it gets retained :)
//        [asset description]; // just 9so it gets retained :)
//        //        [audioSettings description]; // just so it gets retained :)
//        completion(nil, error);
//    }];
}


- (void)createUnsentVideoFromRecodingURL:(NSURL*)recordingUrl {
    YAVideo *video = [YAVideo video];
    
    NSString *hashStr = [YAUtils uniqueId];
    NSString *mp4Filename = [hashStr stringByAppendingPathExtension:@"mp4"];
    NSString *jpgFilename = [hashStr stringByAppendingPathExtension:@"jpg"];
    NSString *mp4Path = [[YAUtils cachesDirectory] stringByAppendingPathComponent:mp4Filename];
    NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
    NSURL    *mp4Url = [NSURL fileURLWithPath:mp4Path];
    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:recordingUrl toURL:mp4Url error:&error];
    if(error) {
        DLog(@"Error in createVideoFromRecodingURL, can't move recording, %@", error);
        return;
    }
    
    NSDate *currentDate = [NSDate date];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        video.creator = [[YAUser currentUser] username];
        video.createdAt = currentDate;
        video.mp4Filename = mp4Filename;
        
        UIImage *previewImage = [YACameraManager sharedManager].capturePreviewImage;
        if(previewImage != nil) {
            previewImage = [self deviceSpecificFullscreenImageFromImage:previewImage];
            if([UIImageJPEGRepresentation(previewImage, 0.6) writeToFile:jpgPath atomically:NO]) {
                video.jpgFullscreenFilename = jpgFilename;
            }
        }
        
        
        if(previewImage == nil)
            [self enqueueJpgCreationForVideo:video];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RECORDED_VIDEO_IS_SHOWABLE_NOTIFICAITON object:video userInfo:nil];
    });
    
}

- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl
                        addToGroup:(YAGroup*)group
       isImmediatelyAfterRecording:(BOOL)isImmediatelyAfterRecording {
    
    YAVideo *video = [YAVideo video];
    
    NSString *hashStr = [YAUtils uniqueId];
    NSString *mp4Filename = [hashStr stringByAppendingPathExtension:@"mp4"];
    NSString *jpgFilename = [hashStr stringByAppendingPathExtension:@"jpg"];
    NSString *mp4Path = [[YAUtils cachesDirectory] stringByAppendingPathComponent:mp4Filename];
    NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
    NSURL    *mp4Url = [NSURL fileURLWithPath:mp4Path];
    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:recordingUrl toURL:mp4Url error:&error];
    if(error) {
        DLog(@"Error in createVideoFromRecodingURL, can't move recording, %@", error);
        return;
    }
    
    NSDate *currentDate = [NSDate date];
    dispatch_sync(dispatch_get_main_queue(), ^{
        video.creator = [[YAUser currentUser] username];
        video.createdAt = currentDate;
        video.mp4Filename = mp4Filename;
        video.group = group;
        video.pending = group.publicGroup;
        
        UIImage *previewImage = [YACameraManager sharedManager].capturePreviewImage;
        if(previewImage != nil) {
            previewImage = [self deviceSpecificFullscreenImageFromImage:previewImage];
            if([UIImageJPEGRepresentation(previewImage, 0.6) writeToFile:jpgPath atomically:NO]) {
                video.jpgFullscreenFilename = jpgFilename;
            }
        }
        
        if (isImmediatelyAfterRecording)
            [[NSNotificationCenter defaultCenter] postNotificationName:RECORDED_VIDEO_IS_SHOWABLE_NOTIFICAITON object:video userInfo:nil];
        
        [group.realm beginWriteTransaction];
        [group.videos insertObject:video atIndex:0];
        [group.realm commitWriteTransaction];
        
        //start uploading while generating gif
        [[YAServerTransactionQueue sharedQueue] addUploadVideoTransaction:video toGroup:group];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_DID_REFRESH_NOTIFICATION object:group userInfo:@{kNewVideos:@[video]}];
        
        
        if(previewImage == nil)
            [self enqueueJpgCreationForVideo:video];
    });
    
    //no need to create gif here, recording operation will post GROUP_DID_REFRESH_NOTIFICATION and AssetsCreator will make sure gif is created for the new item
    //in case of two gif operations for the same video there will be the following issue:
    //one operation can create gif earlier and start uploading, second operation will clean up the file for saving new gif date and and that moment zero bytes are read for uploading.
}

// Was used for stiching switch-cam videos. GPU image made this method unneeded for now
//- (void)createVideoFromSequenceOfURLs:(NSArray *)videoURLs
//                        addToGroup:(YAGroup*)group {
//    NSURL *outputUrl = [YAUtils urlFromFileName:@"concatenated.mp4"];
//    [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
//
//    [self concatenateAssetsAtURLs:videoURLs
//                    withOutputURL:outputUrl
//                    exportQuality:AVAssetExportPreset640x480
//                       completion:^(NSURL *filePath, NSError *error) {
//        if (!error) {
//            [self createVideoFromRecodingURL:filePath addToGroup:[YAUser currentUser].currentGroup];
//        }
//    }];
//}


- (void)stopAllJobsWithCompletion:(stopOperationsCompletion)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[YADownloadManager sharedManager] cancelAllJobs];
        [self.gifQueue cancelAllOperations];
        
        
        [[YADownloadManager sharedManager] waitUntilAllJobsAreFinished];
        [self.gifQueue waitUntilAllOperationsAreFinished];
        
        if(completion)
            completion();
        
        //meaning recording queue will still be alive, as it's important to save recordings
        DLog(@"All jobs stopped");
    });
}

//GIF jobs should always go first
- (void)enqueueAssetsCreationJobForVisibleVideos:(NSArray*)visibleVideos invisibleVideos:(NSArray*)invisibleVideos killExistingJobs:(BOOL)killExisting {
    
    if (killExisting) {
        [[YADownloadManager sharedManager] cancelAllJobs];
    } else {
        [[YADownloadManager sharedManager] pauseExecutingJobs];
    }
    NSArray *orderedUrlsToDownload = [self orderedDownloadUrlsFromVideos:visibleVideos invisibleVideos:invisibleVideos];
    
    [[YADownloadManager sharedManager] reorderJobs:orderedUrlsToDownload];
    
    [[YADownloadManager sharedManager] resumeJobs];
}

- (NSArray*)orderedDownloadUrlsFromVideos:(NSArray*)visibleVideos invisibleVideos:(NSArray*)invisibleVideos {
    
    NSMutableArray *gifUrlsForVisible = [NSMutableArray new];
    NSMutableArray *mp4UrlsForVisible = [NSMutableArray new];
    NSMutableArray *gifUrlsForInvisible = [NSMutableArray new];
    NSMutableArray *mp4UrlsForInvisible = [NSMutableArray new];
    NSUInteger localGifCreationVisibleCount = 0;
    NSUInteger localGifCreationInvisibleCount = 0;
    for(YAVideo *video in visibleVideos) {
        
        BOOL hasRemoteMOVButNoLocal = video.url.length && !video.mp4Filename.length;
        BOOL hasLocalMOVButNoGIF = video.mp4Filename.length && !video.gifFilename.length;
        BOOL hasRemoteGIFButNoLocal = video.gifUrl.length && !video.gifFilename.length && !video.mp4Filename.length;
        
        if(hasRemoteMOVButNoLocal) {
            [mp4UrlsForVisible addObject:video.url];
        }
        
        if(hasLocalMOVButNoGIF) {
            [self addGifCreationOperationForVideo:video quality:YAGifCreationNormalQuality];
            localGifCreationVisibleCount++;
        }
        
        if(hasRemoteGIFButNoLocal) {
            [gifUrlsForVisible addObject:video.gifUrl];
        }
    }
    
    for(YAVideo *video in invisibleVideos) {
        
        BOOL hasRemoteMOVButNoLocal = video.url.length && !video.mp4Filename.length;
        BOOL hasLocalMOVButNoGIF = video.mp4Filename.length && !video.gifFilename.length;
        BOOL hasRemoteGIFButNoLocal = video.gifUrl.length && !video.gifFilename.length && !video.mp4Filename.length;
        
        if(hasRemoteMOVButNoLocal) {
            [mp4UrlsForInvisible addObject:video.url];
        }
        
        if(hasLocalMOVButNoGIF) {
            [self addGifCreationOperationForVideo:video quality:YAGifCreationNormalQuality];
            localGifCreationInvisibleCount++;
        }
        
        if(hasRemoteGIFButNoLocal) {
            [gifUrlsForInvisible addObject:video.gifUrl];
        }
    }
    
    DLog(@"orderedDownloadUrlsFromVideos: gif_visible:%lu, gif_invisible:%lu, mp4_visible:%lu, mp4_invisible:%lu", (unsigned long)gifUrlsForVisible.count, (unsigned long)gifUrlsForInvisible.count, (unsigned long)mp4UrlsForVisible.count, (unsigned long)mp4UrlsForInvisible.count);
    DLog(@"localGifCreationsFromPriorMP4Downloads: visible:%lu, invisible:%lu", (unsigned long)localGifCreationVisibleCount, (unsigned long)localGifCreationInvisibleCount);
    
    NSMutableArray *result = [NSMutableArray arrayWithArray:gifUrlsForVisible];
    [result addObjectsFromArray:mp4UrlsForVisible];
    [result addObjectsFromArray:gifUrlsForInvisible];
    [result addObjectsFromArray:mp4UrlsForInvisible];
    
    return result;
}

- (void)addGifCreationOperationForVideo:(YAVideo*)video quality:(YAGifCreationQuality)quality {
    if(!video.mp4Filename.length)
        return;
    
    if([self gifOperationInProgressForUrl:video.url])
        return;
    
    YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video quality:quality];
    [self.gifQueue addOperation:gifCreationOperation];
}

- (BOOL)gifOperationInProgressForUrl:(NSString*)url {
    for(YAGifCreationOperation *op in self.gifQueue.operations) {
        if([op.videoUrl isEqualToString:url]) {
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
    [self.jpgQueue waitUntilAllOperationsAreFinished];
    [[YADownloadManager sharedManager] waitUntilAllJobsAreFinished];
    [self.gifQueue waitUntilAllOperationsAreFinished];
}

- (void)createJpgForVideo:(YAVideo*)video {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:video.mp4Filename];
        NSURL *movURL = [NSURL fileURLWithPath:movPath];
        NSString *filename =  [video.mp4Filename stringByDeletingPathExtension];
        NSString *jpgFilename = [filename stringByAppendingPathExtension:@"jpg"];
        NSString *jpgFullscreenFilename = [[filename  stringByAppendingString:@"_fullscreen"] stringByAppendingPathExtension:@"jpg"];
        NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
        NSString *jpgFullscreenPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFullscreenFilename];
        BOOL hasGif = video.gifFilename.length != 0;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
            
            AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
            imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
            imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
            imageGenerator.appliesPreferredTrackTransform = YES;
            CMTime time = CMTimeMakeWithSeconds(0, asset.duration.timescale);
            
            NSError *error;
            CMTime actualTime;
            CGImageRef image = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
            UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
            if(newImage) {
                
                //generate cropped jpeg in only case there is no gif
                UIImage *croppedImage;
                if(!hasGif)
                    croppedImage = [self deviceSpecificCroppedThumbnailFromImage:newImage];
                
                newImage = [self deviceSpecificFullscreenImageFromImage:newImage];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self createJpgFromImage:newImage croppedImage:croppedImage atPath:(NSString*)jpgFullscreenPath croppedPath:jpgPath forVideo:video];
                    CFRelease(image);
                });
            }
            
            dispatch_semaphore_signal(sema);
        });
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self jpgCreatedForVideo:video];
    });
}

- (void)enqueueJpgCreationForVideo:(YAVideo*)video {
    [self.jpgQueue addOperationWithBlock:^{
        [self createJpgForVideo:video];
    }];
}

- (UIImage *)deviceSpecificFullscreenImageFromImage:(UIImage *)image{
    //make resized fullscreen image
    CGFloat f = [UIScreen mainScreen].bounds.size.height/image.size.height;
    CGSize fullscreenSize = CGSizeMake(image.size.width * f, image.size.height *f);
    
    image = [image resizedImageToFitInSize:fullscreenSize scaleIfSmaller:YES];
    
    image = [self croppedImageFromImage:image cropSize:[UIScreen mainScreen].bounds.size];
    return image;
}

- (UIImage *)deviceSpecificCroppedThumbnailFromImage:(UIImage*)img {
    CGSize thumbnailSize = CGSizeMake(kGifWidth, kGifWidth);
    return [self croppedImageFromImage:img cropSize:thumbnailSize];
}

- (UIImage *)croppedImageFromImage:(UIImage*)img cropSize:(CGSize)cropSize {
    CGSize gifFrameSize = cropSize;
    
    CGFloat widthDiff = img.size.width - gifFrameSize.width ;
    CGFloat heightDiff = img.size.height - gifFrameSize.height;
    
    CGRect cropRect = CGRectMake(round(widthDiff/2), round(heightDiff/2), gifFrameSize.width, gifFrameSize.height);
    
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

- (void)createJpgFromImage:(UIImage*)image croppedImage:(UIImage*)croppedImage atPath:(NSString*)jpgPath croppedPath:(NSString*)jpgCroppedPath forVideo:(YAVideo*)video {
    
    [video.realm beginWriteTransaction];
    
    if(image && [UIImageJPEGRepresentation(image, 0.6) writeToFile:jpgPath atomically:NO]) {
        video.jpgFullscreenFilename = jpgPath.lastPathComponent;
    }
    
    if(croppedImage && [UIImageJPEGRepresentation(croppedImage, 0.8) writeToFile:jpgCroppedPath atomically:NO]) {
        video.jpgFilename = jpgCroppedPath.lastPathComponent;
    }
    
    [video.realm commitWriteTransaction];
}

#pragma mark -
- (void)jpgCreatedForVideo:(YAVideo*)video {
    if(!video.gifFilename.length)
        [self addGifCreationOperationForVideo:video quality:YAGifCreationNormalQuality];
}

#pragma mark - Application events
- (void)applicationWillResignActive:(NSNotification*)notif {
    [self.exportSession cancelExport];
    self.exportSession = nil;
}

@end
