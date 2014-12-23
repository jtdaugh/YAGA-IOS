//
//  YAImageListGenerator.m
//  CreatingSnapshots
//
//  Created by Iegor on 12/23/14.
//  Copyright (c) 2014 Iegor. All rights reserved.
//
#import "YAGifGenerator.h"
#import "UIImage+Resize.h"
///
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface YAGifGenerator ()
@property (atomic, strong) NSMutableArray *array;
@end

@implementation YAGifGenerator

- (void)crateGifFromAsset:(AVURLAsset*)asset completionHandler:(generatorCompletionHandler)handler {
    
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

                    Float64 movieDuration = CMTimeGetSeconds([asset duration]);
                    NSUInteger framesCount = movieDuration * 10;
                    NSLog(@"movie duration: %f", movieDuration);
                    
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
                            
                            UIImage *newImage = [[UIImage alloc] initWithCGImage:image];
                            CGSize size = CGSizeMake([[UIScreen mainScreen] applicationFrame].size.width/2,
                                                     [[UIScreen mainScreen] applicationFrame].size.height/4);
                            
                            //UIImage *loverQualityImage = [newImage resizedImage:size interpolationQuality:kCGInterpolationMedium];
                            
                            newImage = [self imageWithImage:newImage scaledToSize:size];
                            
                            [self.array addObject:newImage];
                            
                            if (self.array.count == framesCount) {
                                [self makeAnimatedGifFromArray:self.array completionHandler:handler];
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

- (void)makeAnimatedGifFromArray:(NSArray*)images completionHandler:(generatorCompletionHandler)handler {
    
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
    
    NSURL *cachesDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    
    NSURL *fileURL = [cachesDirectoryURL URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    

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



//- (void)createGifAtlasForURLAsset:(AVURLAsset*)asset ofSize:(NSUInteger)arraySize completionHandler:(void (^)(UIImage *img))handler {
//    [self crateArrayForURLAsset:asset ofSize:arraySize completionHandler:^(NSArray *resultArray) {
//        handler([self mergeImages:resultArray]);
//    }];
//}

//- (UIImage *)mergeImages:(NSArray*)images
//{
//    UIImage *newImage = images[0];
//    NSUInteger length = [images count];
//    CGFloat width = newImage.size.width;
//    CGFloat height = newImage.size.height;
//    NSUInteger closestSquare = [self getTheClosestSquare:length];
//
//    CGRect bigRect = CGRectMake(0, 0, width*closestSquare, height*(closestSquare+1));
//
//
//    UIGraphicsBeginImageContextWithOptions(bigRect.size, NO, 0);
//    for (int i = 0; i < length; i++) {
//        int row = i / closestSquare;
//        CGRect rect = CGRectMake(width*(i%closestSquare), row*height, width, height);
//        UIImage *image = images[i];
//        [image drawInRect:rect];
//    }
//
//    newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    return newImage;
//}
//
//- (NSUInteger)getTheClosestSquare:(NSUInteger)entry
//{
//    float x = sqrtf((float)entry);
//    return (NSUInteger)x;
//}
//

//+ (NSURL*)saveImage:(UIImage *)image toFolder:(NSString*)folderName withName:(NSString *)name {
//
//    NSFileManager *fm = [[NSFileManager alloc] init];
//
//    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//
//    NSString *path = [docDir stringByAppendingPathComponent:folderName];
//
//    BOOL isDir;
//    BOOL fileExists = [fm fileExistsAtPath:path isDirectory:&isDir];
//
//    if (!fileExists || !isDir)
//    {
//        [self createDirectory:folderName atFilePath:docDir];
//    }
//
//
//    NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@.png",path, name];
//    NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(image)];
//    [data1 writeToFile:pngFilePath atomically:YES];
//
//    return [NSURL URLWithString:pngFilePath];
//}

//+ (void)createDirectory:(NSString *)directoryName atFilePath:(NSString *)filePath
//{
//    NSString *filePathAndDirectory = [filePath stringByAppendingPathComponent:directoryName];
//    NSError *error;
//
//    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
//                                   withIntermediateDirectories:NO
//                                                    attributes:nil
//                                                         error:&error])
//    {
//        NSLog(@"Create directory error: %@", error);
//    }
//}

@end


