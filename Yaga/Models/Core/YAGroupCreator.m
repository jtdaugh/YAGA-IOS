//
//  YAGroupCreator.m
//  Yaga
//
//  Created by Iegor on 12/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupCreator.h"

@implementation YAGroupCreator
+ (instancetype)sharedCreator {
    static YAGroupCreator *sCreator = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sCreator = [[self alloc] init];
    });
    return sCreator;
}
@end
