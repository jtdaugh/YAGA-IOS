//
//  YAImageListGenerator.m
//  CreatingSnapshots
//
//  Created by Iegor on 12/23/14.
//  Copyright (c) 2014 Iegor. All rights reserved.
//
#import "UIImage+Resize.h"
#import "YAImageAtlasGenerator.h"

@implementation YAImageAtlasGenerator
- (void)createGifAtlasForURLAsset:(AVURLAsset*)asset ofSize:(NSUInteger)arraySize completionHandler:(void (^)(UIImage *img))handler {
    NSArray *keys = [NSArray arrayWithObject:@"duration"];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
        NSError *error = nil;
        AVKeyValueStatus valueStatus = [asset statusOfValueForKey:@"duration" error:&error];
        switch (valueStatus) {
            case AVKeyValueStatusLoaded:
                if ([asset tracksWithMediaCharacteristic:AVMediaTypeVideo]) {
                    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                    Float64 movieDuration = CMTimeGetSeconds([asset duration]);
                    
                    NSMutableArray *times = [NSMutableArray arrayWithCapacity:arraySize];
                    for (int i = 0; i < arraySize; i++) {
                        CGFloat frac = (CGFloat)i/(CGFloat)arraySize;
                        [times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(movieDuration*frac, 600)]];
                    }
                    
                    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:arraySize];
                    [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime,
                                                                                                     CGImageRef image,
                                                                                                     CMTime actualTime,
                                                                                                     AVAssetImageGeneratorResult result,
                                                                                                     NSError *error) {
                        
                        if (result == AVAssetImageGeneratorSucceeded) {
                            static int inc = 0;
                            UIImage *newImage = [[UIImage alloc] initWithCGImage:image];
                            CGSize size = CGSizeMake([[UIScreen mainScreen] applicationFrame].size.width/2,
                                                     [[UIScreen mainScreen] applicationFrame].size.height/4);
                            
                            UIImage *loverQualityImage = [newImage resizedImage:size interpolationQuality:kCGInterpolationMedium];

                            [resultArray addObject:loverQualityImage];
                            if (inc == arraySize-1)
                            {
                                
                                handler([self mergeImages:resultArray]);
                            }
                            else
                            {
                                inc++;
                            }
                        }
                        
                        if (result == AVAssetImageGeneratorFailed) {
                            NSLog(@"Failed with error: %@", [error localizedDescription]);
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

- (UIImage *)mergeImages:(NSArray*)images
{
    UIImage *newImage = images[0];
    NSUInteger length = [images count];
    CGFloat width = newImage.size.width;
    CGFloat height = newImage.size.height;
    NSUInteger closestSquare = [self getTheClosestSquare:length];
    
    CGRect bigRect = CGRectMake(0, 0, width*closestSquare, height*(closestSquare+1));

    
    UIGraphicsBeginImageContextWithOptions(bigRect.size, NO, 0);
    for (int i = 0; i < length; i++) {
        int row = i / closestSquare;
        CGRect rect = CGRectMake(width*(i%closestSquare), row*height, width, height);
        UIImage *image = images[i];
        [image drawInRect:rect];
    }
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (NSUInteger)getTheClosestSquare:(NSUInteger)entry
{
    float x = sqrtf((float)entry);
    return (NSUInteger)x;
}

+ (NSURL*)saveImage:(UIImage *)image toFolder:(NSString*)folderName withName:(NSString *)name {
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *path = [docDir stringByAppendingPathComponent:folderName];
    
    BOOL isDir;
    BOOL fileExists = [fm fileExistsAtPath:path isDirectory:&isDir];
    
    if (!fileExists || !isDir)
    {
        [self createDirectory:folderName atFilePath:docDir];
    }
    
    
    NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@.png",path, name];
    NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(image)];
    [data1 writeToFile:pngFilePath atomically:YES];
    
    return [NSURL URLWithString:pngFilePath];
}

+ (void)createDirectory:(NSString *)directoryName atFilePath:(NSString *)filePath
{
    NSString *filePathAndDirectory = [filePath stringByAppendingPathComponent:directoryName];
    NSError *error;
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                   withIntermediateDirectories:NO
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"Create directory error: %@", error);
    }
}
@end
