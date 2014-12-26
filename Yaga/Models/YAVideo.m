//
//  YAVideo.m
//  Yaga
//
//  Created by valentinkovalski on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAVideo.h"
#import "YAUtils.h"
#import "YAUser.h"

#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "AZNotification.h"

@implementation YAVideo

+ (void)crateVideoAndAddToCurrentGroupFromRecording:(NSURL*)recordingUrl completionHandler:(videoCreatedCompletionHandler)completionHandler jpgCreatedHandler:(jpgCreatedCompletionHandler)jpgHandler {
    
    NSString *hashStr = [YAUtils uniqueId];
    NSString *moveFilename = [hashStr stringByAppendingPathExtension:@"mov"];
    NSString *gifFilename = [hashStr stringByAppendingPathExtension:@"gif"];
    NSString *jpgFilename = [hashStr stringByAppendingPathExtension:@"jpg"];
    NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
    NSString *gifPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:gifFilename];
    NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
    NSURL *movURL = [NSURL fileURLWithPath:movPath];
    NSURL *gifURL = [NSURL fileURLWithPath:gifPath];
    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:recordingUrl toURL:movURL error:&error];
    
    //upload
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RLMRealm defaultRealm] beginWriteTransaction];
        YAVideo *video = [YAVideo new];
        video.movFilename = moveFilename;
        video.jpgFilename = @"";
        video.gifFilename = @"";
        video.uploaded = NO;
        [[YAUser currentUser].currentGroup.videos insertObject:video atIndex:0];
        [[RLMRealm defaultRealm] commitWriteTransaction];
        
        //start uploading while generating gif
        [YAVideo uploadMovFile:movURL withCompletion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(!error)
                    video.uploaded = YES;
            });
        }];
        
        NSArray *keys = [NSArray arrayWithObject:@"duration"];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
        
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
                        
                        __block NSMutableArray *imagesArray = [NSMutableArray arrayWithCapacity:framesCount];
                        
                        [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime,
                                                                                                         CGImageRef image,
                                                                                                         CMTime actualTime,
                                                                                                         AVAssetImageGeneratorResult result,
                                                                                                         NSError *error) {
                            
                            if (result == AVAssetImageGeneratorSucceeded) {
                                
                                UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1.9 orientation:UIImageOrientationUp];
                                newImage = [self deviceSpecificCroppedThumbnailFromImage:newImage];
                                
                                if(!gifDataDic[@"width"]) {
                                    
                                    gifDataDic[@"width"] = [NSNumber numberWithFloat:newImage.size.width];
                                    gifDataDic[@"height"] = [NSNumber numberWithFloat:newImage.size.height];
                                    
                                    [sizes setObject:gifDataDic forKey:filename];
                                    [[NSUserDefaults standardUserDefaults] setObject:sizes forKey:@"gifSizes"];
                                    [[NSUserDefaults standardUserDefaults] synchronize];
                                }
                                
                                [imagesArray addObject:newImage];
                                
                                if([imagesArray count] == 1) {
                                    if([UIImageJPEGRepresentation(newImage, 1.0) writeToFile:jpgPath atomically:NO]) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [[RLMRealm defaultRealm] beginWriteTransaction];
                                            video.jpgFilename = jpgFilename;
                                            [[RLMRealm defaultRealm] commitWriteTransaction];
                                            jpgHandler(nil, jpgHandler);
                                        });
                                    }
                                    else {
                                        completionHandler([NSError errorWithDomain:@"Can't save jpg" code:0 userInfo:nil], nil);
                                        return;
                                    }
                                }
                                
                                if (imagesArray.count == framesCount) {
                                    [self makeAnimatedGifAtUrl:gifURL fromArray:imagesArray completionHandler:^(NSError *error) {
                                        if(error) {
                                            completionHandler(error, nil);
                                        }
                                        else {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [[RLMRealm defaultRealm] beginWriteTransaction];
                                                video.gifFilename = gifFilename;
                                                [[RLMRealm defaultRealm] commitWriteTransaction];
                                                completionHandler(nil, video);
                                            });
                                        }
                                    }];
                                }
                                
                            }
                            
                            if (result == AVAssetImageGeneratorFailed) {
                                NSLog(@"Failed with error: %@", [error localizedDescription]);
                                completionHandler(error, nil);
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

#pragma mark - Server
+ (void)uploadMovFile:(NSURL*)movURL withCompletion:(uploadCompletionHandler)handler {
    handler([NSError errorWithDomain:@"not implemented" code:0 userInfo:nil]);
    return;
    
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_LOW), ^{
        NSError *error;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if(error) {
                [AZNotification showNotificationWithTitle:[NSString stringWithFormat:@"Unable to upload recording, %@", error.localizedDescription] controller:[UIApplication sharedApplication].keyWindow.rootViewController
                                         notificationType:AZNotificationTypeError
                                             startedBlock:nil];
            }
            else {
                handler(error);
            }
        });
        
    });
}



@end
