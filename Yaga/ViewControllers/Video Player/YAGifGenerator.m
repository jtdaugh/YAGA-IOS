//
//  YAImageListGenerator.m
//  CreatingSnapshots
//
//  Created by Iegor on 12/23/14.
//  Copyright (c) 2014 Iegor. All rights reserved.
//
#import "YAGifGenerator.h"
///
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "YAUtils.h"
#import "YAUser.h"

@interface YAGifGenerator ()
@property (atomic, strong) NSMutableArray *array;
@end

@implementation YAGifGenerator

- (void)crateGifAtUrl:(NSURL*)gifURL fromAsset:(AVURLAsset*)asset completionHandler:(generatorCompletionHandler)handler {
    
    currentOrientation = [[UIDevice currentDevice] orientation];
    
    NSArray *keys = [NSArray arrayWithObject:@"duration"];
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
                    NSUInteger framesCount = movieDuration * 20;
                    NSLog(@"movie duration: %f", movieDuration);
                    
                    NSMutableDictionary *sizes = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"gifSizes"]];
                    NSString *filename = [gifURL lastPathComponent];
                    
                    NSMutableDictionary *gifDataDic = [NSMutableDictionary new];
                    gifDataDic[@"duration"] = [NSNumber numberWithFloat:movieDuration];
                    gifDataDic[@"frames"] = [NSNumber numberWithLong:framesCount];
                    
                    NSMutableArray *times = [NSMutableArray arrayWithCapacity:framesCount];
                    for (int i = 0; i < framesCount; i++) {
                        CGFloat frac = (CGFloat)i/(CGFloat)framesCount;
                        [times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(movieDuration*frac, 30)]];
                    }
                    
                    self.array = [NSMutableArray arrayWithCapacity:framesCount];

                    [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime,
                                                                                                     CGImageRef image,
                                                                                                     CMTime actualTime,
                                                                                                     AVAssetImageGeneratorResult result,
                                                                                                     NSError *error) {
                        
                        if (result == AVAssetImageGeneratorSucceeded) {
                            
                            UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:3 orientation:UIImageOrientationUp];
                            
                            if(!gifDataDic[@"width"]) {

                                gifDataDic[@"width"] = [NSNumber numberWithFloat:newImage.size.width];
                                gifDataDic[@"height"] = [NSNumber numberWithFloat:newImage.size.height];
                                
                                [sizes setObject:gifDataDic forKey:filename];
                                [[NSUserDefaults standardUserDefaults] setObject:sizes forKey:@"gifSizes"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                            }
                            
                            [self.array addObject:newImage];
                            
                            if (self.array.count == framesCount) {
                                [self makeAnimatedGifAtUrl:gifURL fromArray:self.array completionHandler:handler];
                            }
                            
                        }
                        
                        if (result == AVAssetImageGeneratorFailed) {
                            NSLog(@"Failed with error: %@", [error localizedDescription]);
                            handler(error, nil);
                        }
                        if (result == AVAssetImageGeneratorCancelled) {
                            NSLog(@"Canceled");
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
}

- (void)makeAnimatedGifAtUrl:(NSURL*)fileURL fromArray:(NSArray*)images completionHandler:(generatorCompletionHandler)handler {
    
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
        handler([NSError errorWithDomain:@"YA" code:0 userInfo:nil], nil);
        CFRelease(destination);
        return;
    }
    
    CFRelease(destination);
    
    handler(nil, fileURL);
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end


