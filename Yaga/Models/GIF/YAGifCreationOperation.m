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
@property (nonatomic, strong) YAVideo *video;
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
        __block NSArray *keys;
        __block AVURLAsset *asset;
        __block NSString *filename;
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:self.video.movFilename];
            NSURL *movURL = [NSURL fileURLWithPath:movPath];
            
            keys = [NSArray arrayWithObject:@"duration"];
            asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
            
            filename = [self.video.movFilename stringByDeletingPathExtension];
            
        });
        NSLog(@"------ YAGifCreationOperation started %@", filename);

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
                                newImage = [YAGifCreationOperation deviceSpecificCroppedThumbnailFromImage:newImage];
                                //UIImageWriteToSavedPhotosAlbum(newImage, self, @selector(imageSavedToPhotosAlbum: didFinishSavingWithError: contextInfo:), nil);
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
                                    
                                    [YAGifCreationOperation makeAnimatedGifAtUrl:gifURL fromArray:imagesArray completionHandler:^(NSError *error) {
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
                                                
//                                                [self finishGIFGenerationAndStartNext:self.video
//                                                               errorsDuringProcessing:NO];
                                                
                                                NSLog(@"------  YAGifCreationOperation  finished %@", filename);
                                            });
                                        }
                                    }];
                                }
                                
                            }
                            
                            if (result == AVAssetImageGeneratorFailed) {
                                NSLog(@"AVAssetImageGeneratorFailed with error: %@", [error localizedDescription]);
                                //[self finishGIFGenerationAndStartNext:self.video errorsDuringProcessing:YES];
                            }
                            if (result == AVAssetImageGeneratorCancelled) {
                                NSLog(@"AVAssetImageGeneratorCancelled");
                                //[self finishGIFGenerationAndStartNext:self.video errorsDuringProcessing:YES];
                            }
                        }];
                    }
                    break;
                case AVKeyValueStatusFailed:
                    NSLog(@"createJPGAndGIFForVideo Error finding duration");
                    //[self finishGIFGenerationAndStartNext:video errorsDuringProcessing:YES];
                    break;
                case AVKeyValueStatusCancelled:
                    NSLog(@"createJPGAndGIFForVideo Cancelled finding duration");
                    //[self finishGIFGenerationAndStartNext:video errorsDuringProcessing:YES];
                    break;
                default:
                    break;
            }
        }];
    }
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
