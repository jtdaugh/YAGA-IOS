//
//  YAGifCreationOperation.m
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import "YAGifCreationOperation.h"
#import "YAAssetsCreator.h"
#import "YAServer.h"

@interface YAGifCreationOperation ()
@property (strong) NSString *filename;
@property YAGifCreationQuality quality;
@end

@implementation YAGifCreationOperation

- (instancetype)initWithVideo:(YAVideo*)video quality:(YAGifCreationQuality)quality {
    if (self = [super init]) {
        _video = video;
        _quality = quality;
        self.name = video.url;
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
    
//    if(_finished) {
//        DLog(@"gif creation finished, cancelled: %d", self.isCancelled);
//    }
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isExecuting {
    return _executing;
}

- (void)start {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            //skip if gif is generated already
            bool highQualityMode = self.quality == YAGifCreationHighQuality;
            if(self.video.gifFilename.length && !highQualityMode) {
                [self setExecuting:NO];
                [self setFinished:YES];
                return;
            }
            
            NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:self.video.mp4Filename];
            NSURL *movURL = [NSURL fileURLWithPath:movPath];
            self.filename = [self.video.mp4Filename stringByDeletingPathExtension];
            
            unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:movPath error:nil] fileSize];
            
            DLog((@"mov file size: %llu", fileSize);

            [self setExecuting:YES];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
                NSArray *images = [self imagesArrayFromAsset:asset];
                
                if(self.isCancelled) {
                    [self setExecuting:NO];
                    [self setFinished:YES];
                    return;
                }
                NSString *gifFilename;
                if (self.quality == YAGifCreationNormalQuality) {
                    gifFilename = [self.filename stringByAppendingPathExtension:@"gif"];
                } else {
                    gifFilename = [[self.filename stringByAppendingString:@"High"] stringByAppendingPathExtension:@"gif"];
                }
                NSString *gifPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:gifFilename];;
                NSURL *gifURL = [NSURL fileURLWithPath:gifPath];
                
                [self makeAnimatedGifAtUrl:gifURL fromArray:images completionHandler:^(NSError *error) {
                    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:gifPath error:nil] fileSize];
                    
                    DLog((@"gif file size: %llu", fileSize);
                    
                    if(error) {
                        DLog(@"makeAnimatedGifAtUrl Error occured: %@", error);
                        [self setExecuting:NO];
                        [self setFinished:YES];
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![self.video isInvalidated]){
                                [self.video.realm beginWriteTransaction];
                                if (self.quality == YAGifCreationHighQuality) {
                                    self.video.highQualityGifFilename = gifFilename;
                                } else {
                                    self.video.gifFilename = gifFilename;
                                }
                                [self.video.realm commitWriteTransaction];
                                [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION
                                                                                    object:self.video];
                                
                                //check whether we need to upload gif
                                [[YAServer sharedServer] uploadGIFForVideoWithServerId:self.video.serverId];
                            }
                            else
                            {
                                DLog(NSLocalizedString(@"Couldn't create gif, video invalidated", @""));
                            }
                            [self setExecuting:NO];
                            [self setFinished:YES];
                            
                        });
                    }
                    
                }];
            });
        });
    }
}

//- (CGImageRef)pixellateImage:(CGImageRef)cgImg {
//    CIContext *context = [CIContext contextWithOptions:nil];               // 1
//    CIImage *image = [CIImage imageWithCGImage:cgImg];               // 2
//    CIFilter *filter = [CIFilter filterWithName:@"CIPixellate"];           // 3
//    [filter setDefaults];
//    [filter setValue:image forKey:kCIInputImageKey];
//    [filter setValue:[NSNumber numberWithFloat:kGifPixellationSize] forKey:@"inputScale"];
//    CIImage *result = [filter valueForKey:kCIOutputImageKey];              // 4
//    CGRect extent = [result extent];
//    return [context createCGImage:result fromRect:extent];   // 5
//}

- (NSArray*)imagesArrayFromAsset:(AVURLAsset*)asset {
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    CGFloat maxWidth = kGifWidth;
    CGFloat aspectRatio = [[UIScreen mainScreen] applicationFrame].size.height / [[UIScreen mainScreen] applicationFrame].size.width;
    imageGenerator.maximumSize = CGSizeMake(maxWidth, maxWidth * aspectRatio);
    
    Float64 movieDuration = CMTimeGetSeconds([asset duration]);
    NSUInteger frames = self.quality == YAGifCreationHighQuality ? kGifFPS_HQ : kGifFPS_LQ;
    CGFloat framesCount = movieDuration * frames;
    if(framesCount < 1)
        framesCount = 1;
    
    NSMutableArray *imagesArray = [NSMutableArray arrayWithCapacity:framesCount];
    
    for (int i = 0; i < framesCount; i++) {
        CGFloat frac = (CGFloat)i/(CGFloat)framesCount;
        CMTime time = CMTimeMakeWithSeconds(movieDuration*frac, asset.duration.timescale);
        
        NSError *error;
        CMTime actualTime;
        CGImageRef image = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
        UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
        
        
        
        if(newImage) {
            if (self.quality == YAGifCreationNormalQuality) {
                newImage = [[YAAssetsCreator sharedCreator] deviceSpecificCroppedThumbnailFromImage:newImage];
                CFRelease(image);
            }
            [imagesArray addObject:newImage];
            
            if(self.isCancelled) {
                DLog(@"gif creation cancelled");
                break;
            }
        }
        
        if(self.isCancelled) {
            DLog(@"gif creation cancelled");
            break;
        }
    }
    return imagesArray;
}

- (void)makeAnimatedGifAtUrl:(NSURL*)fileURL fromArray:(NSArray*)images completionHandler:(gifCreatedCompletionHandler)handler {
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    NSNumber *centiseconds = self.quality == YAGifCreationHighQuality ? @(kGifFPS_HQ) : @(1/kGifFPS_LQ/kGifSpeed);
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: centiseconds, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, images.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (UIImage *frameImage in images) {
        if(self.isCancelled)
            break;
        
        CGImageDestinationAddImage(destination, frameImage.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        DLog(@"failed to finalize image destination");
        CFRelease(destination);
        handler([NSError errorWithDomain:@"YA" code:0 userInfo:nil]);
        return;
    }
    
    
    CFRelease(destination);
    
    handler(nil);
}

@end
