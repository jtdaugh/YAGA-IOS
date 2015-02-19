//
//  YAGifCreationOperation.h
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAVideo.h"
#import <Foundation/Foundation.h>

@interface YAGifCreationOperation : NSOperation {
    BOOL _executing;
    BOOL _finished;
}
- (instancetype)initWithVideo:(YAVideo*)video quality:(YAGifCreationQuality)quality;

@property (nonatomic, readonly) YAVideo *video;

@end
