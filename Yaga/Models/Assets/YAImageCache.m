//
//  YAImageCache.m
//  Yaga
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAImageCache.h"

@implementation YAImageCache

+ (YAImageCache*)sharedCache {
    static YAImageCache *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

@end
