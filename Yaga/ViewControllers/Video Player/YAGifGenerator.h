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

@interface YAGifGenerator : NSObject {
    UIDeviceOrientation currentOrientation;
}
- (void)crateGifAtUrl:(NSURL*)gifURL fromAsset:(AVURLAsset*)asset completionHandler:(generatorCompletionHandler)handler;
@end
