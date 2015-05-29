//
//  YAUnavailableVideoError.m
//  Yaga
//
//  Created by Iegor on 1/6/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YARealmObjectUnavailableError.h"

@implementation YARealmObjectUnavailableError

- (NSString*)localizedDescription {
    return @"YAError: object already deleted";
}

@end
