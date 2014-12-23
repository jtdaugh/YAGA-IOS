//
//  YAImageListGenerator.h
//  CreatingSnapshots
//
//  Created by Iegor on 12/23/14.
//  Copyright (c) 2014 Iegor. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

typedef void (^generatorCompletionHandler)(NSError *error,  NSURL *gifPath);

@interface YAGifGenerator : NSObject
//- (void)createGifAtlasForURLAsset:(AVURLAsset*)asset ofSize:(NSUInteger)arraySize completionHandler:(void (^)(UIImage *img))handler;

//+ (NSURL*)saveImage:(UIImage *)image toFolder:(NSString*)folderName withName:(NSString *)name;

- (void)crateGifFromAsset:(AVURLAsset*)asset completionHandler:(generatorCompletionHandler)handler;
@end
