//
//  YAVideoDownloadOperation.h
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YAVideo.h"
#import <Foundation/Foundation.h>

@interface YAVideoDownloadOperation : NSOperation
- (instancetype)initWithVideo:(YAVideo*)video;
@end
