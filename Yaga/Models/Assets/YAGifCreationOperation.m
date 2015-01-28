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
@property (strong) NSString *filename;
@end

@implementation YAGifCreationOperation

- (instancetype)initWithVideo:(YAVideo*)video {
    if (self = [super init]) {
        _video = video;
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
    
    if(_finished) {
        NSLog(@"gif creation finished, cancelled: %d", self.isCancelled);
    }
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
            NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:self.video.movFilename];
            NSURL *movURL = [NSURL fileURLWithPath:movPath];
            self.filename = [self.video.movFilename stringByDeletingPathExtension];
            
            NSLog(@"gif creation started");
            
            [self setExecuting:YES];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:movURL options:nil];
                NSArray *images = [self imagesArrayFromAsset:asset];
                
                if(self.isCancelled) {
                    [self setExecuting:NO];
                    [self setFinished:YES];
                    return;
                }
                
                NSString *gifFilename = [self.filename stringByAppendingPathExtension:@"gif"];
                NSString *gifPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:gifFilename];
                NSURL *gifURL = [NSURL fileURLWithPath:gifPath];
                
                [self makeAnimatedGifAtUrl:gifURL fromArray:images completionHandler:^(NSError *error) {
                    if(error) {
                        NSLog(@"makeAnimatedGifAtUrl Error occured: %@", error);
                        [self setExecuting:NO];
                        [self setFinished:YES];
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.video.realm beginWriteTransaction];
                            self.video.gifFilename = gifFilename;
                            [self.video.realm commitWriteTransaction];
                            [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION
                                                                                object:self.video];
                            NSLog(@"gif created");
                            [self setExecuting:NO];
                            [self setFinished:YES];
                            
                        });
                    }
                    
                }];
            });
        });
    }
}

- (NSArray*)imagesArrayFromAsset:(AVURLAsset*)asset {
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    imageGenerator.maximumSize = CGSizeMake([[UIScreen mainScreen] applicationFrame].size.height/2, [[UIScreen mainScreen] applicationFrame].size.height/2);
    
    Float64 movieDuration = CMTimeGetSeconds([asset duration]);
    NSUInteger framesCount = movieDuration * 10;
    
    NSMutableArray *imagesArray = [NSMutableArray arrayWithCapacity:framesCount];
    
    for (int i = 0; i < framesCount; i++) {
        CGFloat frac = (CGFloat)i/(CGFloat)framesCount;
        CMTime time = CMTimeMakeWithSeconds(movieDuration*frac, asset.duration.timescale);
        
        NSError *error;
        CMTime actualTime;
        CGImageRef image = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
        UIImage *newImage = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
        if(newImage) {
            newImage = [self deviceSpecificCroppedThumbnailFromImage:newImage];
            [imagesArray addObject:newImage];
            CFRelease(image);
            
            if(self.isCancelled) {
                NSLog(@"gif creation cancelled");
                break;
            }
            
            if(i == 0) {
                [self createJpgFromImage:newImage];
            }
            
        }
        
        if(self.isCancelled) {
            NSLog(@"gif creation cancelled");
            break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat currentFrame = i + 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_GENERATE_PART_NOTIFICATION object:self.video.url userInfo:@{@"progress": [NSNumber numberWithFloat:currentFrame * 0.3 / framesCount + 0.7]}];
        });
    }
    return imagesArray;
}

- (void)createJpgFromImage:(UIImage*)image {
    NSString *jpgFilename = [self.filename stringByAppendingPathExtension:@"jpg"];
    NSString *jpgPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:jpgFilename];
    
    if([UIImageJPEGRepresentation(image, 0.8) writeToFile:jpgPath atomically:NO]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.video.realm beginWriteTransaction];
            weakSelf.video.jpgFilename = jpgFilename;
            [weakSelf.video.realm commitWriteTransaction];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:self.video];
            NSLog(@"jpg created");
        });
    }
    else {
        NSLog(@"Error: Can't save jpg by some reason...");
        [self cancel];
        return;
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
            if(self.isCancelled) {
                CFRelease(destination);
                return;
            }
            
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
