//
//  YAGIFOperation.m
//  Yaga
//
//  Created by valentinkovalski on 1/2/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGIFCreator.h"
#import "YAUtils.h"

#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>


@interface YAGIFCreator ()
@property (nonatomic, strong) dispatch_queue_t gifQueue;
@property (nonatomic, strong) NSMutableSet *videosInProgress;
@end

@implementation YAGIFCreator

+ (instancetype)sharedCreator {
    static YAGIFCreator *s = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        s = [[self alloc] init];
    });
    return s;
}

- (instancetype)init {
    if (self = [super init]) {
        self.gifQueue = dispatch_queue_create("GIF Creator queue", NULL);
        self.videosInProgress = [NSMutableSet set];
    }
    return self;
}

- (void)createJPGAndGIFForVideo:(YAVideo*)video {
    if([self.videosInProgress containsObject:video])
        return;
    
    NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:video.movFilename];
    NSURL *movURL = [NSURL fileURLWithPath:movPath];
    
    NSArray *keys = [NSArray arrayWithObject:@"duration"];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
    
    NSString *filename = [video.movFilename stringByDeletingPathExtension];
    [self.videosInProgress addObject:video];
    
    dispatch_async(self.gifQueue, ^{
        
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
                                
                                UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1.9 orientation:UIImageOrientationUp];
                                newImage = [YAGIFCreator deviceSpecificCroppedThumbnailFromImage:newImage];
                                
                                [imagesArray addObject:newImage];
                                
                                if([imagesArray count] == 1) {
                                    NSString *jpgFilename = [filename stringByAppendingPathExtension:@"jpg"];
                                    NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
                                    if([UIImageJPEGRepresentation(newImage, 1.0) writeToFile:jpgPath atomically:NO]) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [video.realm beginWriteTransaction];
                                            video.jpgFilename = jpgFilename;
                                            [video.realm commitWriteTransaction];
                                            [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_VIDEO_NOTIFICATION object:video];
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
                                    [YAGIFCreator makeAnimatedGifAtUrl:gifURL fromArray:imagesArray completionHandler:^(NSError *error) {
                                        if(error) {
                                            NSLog(@"Error occured: %@", error);
                                        }
                                        else {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [video.realm beginWriteTransaction];
                                                video.gifFilename = gifFilename;
                                                [video.realm commitWriteTransaction];
                                                [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_VIDEO_NOTIFICATION object:video];
                                                [self.videosInProgress removeObject:video];
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
                    NSLog(@"Error finding duration");
                    break;
                case AVKeyValueStatusCancelled:
                    NSLog(@"Cancelled finding duration");
                    break;
                default: break;
            }
        }];
    });
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

@end
