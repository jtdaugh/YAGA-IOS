//
//  YAGIFOperation.h
//  Yaga
//
//  Created by valentinkovalski on 1/2/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAVideo.h"

@interface YAGIFCreator : NSObject

+ (instancetype)sharedCreator;
- (void)createJPGAndGIFForVideo:(YAVideo*)video;

@end
