//
//  YAGifCreationOperation.m
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YAVideo.h"
#import "YAUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import "YAGifCreationOperation.h"

@interface YAGifCreationOperation ()
@property (strong) YAVideo *video;
@property (strong) AVAssetImageGenerator *imageGenerator;
@end

@implementation YAGifCreationOperation

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
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        NSLog(@"gif creation started");
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *filename = [self.video.movFilename stringByDeletingPathExtension];
            NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:self.video.movFilename];
            NSURL *movURL = [NSURL fileURLWithPath:movPath];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSArray *keys = [NSArray arrayWithObject:@"duration"];
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
                
                [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
                    if(self.isCancelled) {
                        NSLog(@"gif creation cancelled");
                        return;
                    }
                    NSError *error = nil;
                    AVKeyValueStatus valueStatus = [asset statusOfValueForKey:@"duration" error:&error];
                    switch (valueStatus) {
                        case AVKeyValueStatusLoaded:
                            if ([asset tracksWithMediaCharacteristic:AVMediaTypeVideo]) {
                                self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                                
                                self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
                                self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
                                self.imageGenerator.appliesPreferredTrackTransform = YES;
                                
                                self.imageGenerator.maximumSize = CGSizeMake([[UIScreen mainScreen] applicationFrame].size.height/2, [[UIScreen mainScreen] applicationFrame].size.height/2);
                                
                                Float64 movieDuration = CMTimeGetSeconds([asset duration]);
                                NSUInteger framesCount = movieDuration * 10;
                                
                                NSMutableArray *times = [NSMutableArray arrayWithCapacity:framesCount];
                                for (int i = 0; i < framesCount; i++) {
                                    CGFloat frac = (CGFloat)i/(CGFloat)framesCount;
                                    [times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(movieDuration*frac, 30)]];
                                }
                                
                                __block NSMutableArray *imagesArray = [NSMutableArray arrayWithCapacity:framesCount];
                                [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime,
                                                                                                                 CGImageRef image,
                                                                                                                 CMTime actualTime,
                                                                                                                 AVAssetImageGeneratorResult result,
                                                                                                                 NSError *error) {
                                    
                                    NSLog(@"gif operation: cancelled:%d executing:%d finished:%d", self.isCancelled, self.isExecuting, self.isFinished);
                                    
                                    if(self.isCancelled && !self.finished) {
                                        dispatch_semaphore_signal(sem);
                                    }
                                    
                                    if (result == AVAssetImageGeneratorSucceeded) {
                                        UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
                                        newImage = [self deviceSpecificCroppedThumbnailFromImage:newImage];
                                        
                                        [imagesArray addObject:newImage];
                                        
                                        if([imagesArray count] == 1) {
                                            NSString *jpgFilename = [filename stringByAppendingPathExtension:@"jpg"];
                                            NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
                                            if([UIImageJPEGRepresentation(newImage, 0.8) writeToFile:jpgPath atomically:NO]) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self.video.realm beginWriteTransaction];
                                                    self.video.jpgFilename = jpgFilename;
                                                    [self.video.realm commitWriteTransaction];
                                                    
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:self.video];
                                                    NSLog(@"jpg created");
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
                                            
                                            [self makeAnimatedGifAtUrl:gifURL fromArray:imagesArray completionHandler:^(NSError *error) {
                                                if(error) {
                                                    NSLog(@"Error occured: %@", error);
                                                    //[self.videosToProcess removeObject:video];
                                                }
                                                else {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [self.video.realm beginWriteTransaction];
                                                        self.video.gifFilename = gifFilename;
                                                        [self.video.realm commitWriteTransaction];
                                                        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION
                                                                                                            object:self.video];
                                                        dispatch_semaphore_signal(sem);
                                                    });
                                                }
                                                
                                            }];
                                        }
                                        
                                    }
                                    
                                    if (result == AVAssetImageGeneratorFailed) {
                                        NSLog(@"AVAssetImageGeneratorFailed with error: %@", [error localizedDescription]);
                                        dispatch_semaphore_signal(sem);
                                    }
                                    if (result == AVAssetImageGeneratorCancelled) {
                                        NSLog(@"AVAssetImageGeneratorCancelled");
                                        dispatch_semaphore_signal(sem);
                                    }
                                }];
                                break;
                            }
                        case AVKeyValueStatusFailed: {
                            NSLog(@"createJPGAndGIFForVideo Error finding duration");
                            dispatch_semaphore_signal(sem);
                        }
                            break;
                        case AVKeyValueStatusCancelled: {
                            NSLog(@"createJPGAndGIFForVideo Cancelled");
                        }
                            break;
                        default:
                            break;
                    }
                }];
            });
            
        });
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        if(self.isCancelled) {
            if(self.imageGenerator) {
                [self.imageGenerator cancelAllCGImageGeneration];
                NSLog(@"cancelling gif generator");
            }
            NSLog(@"gif creation cancelled");
        }
        NSLog(@"finished gif creation");
    }
    
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
    
    //        if(!saved) {
    //            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    //            saved = YES;
    //        }
    
    
    return result;
}

- (void)makeAnimatedGifAtUrl:(NSURL*)fileURL fromArray:(NSArray*)images completionHandler:(gifCreatedCompletionHandler)handler {
    
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
            if(self.isCancelled)
                return;
            
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

@end
