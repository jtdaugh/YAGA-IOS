//
//  YANoServerIdError.m
//  Yaga
//
//  Created by valentinkovalski on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YANoServerIdError.h"

@implementation YANoServerIdError

- (NSString*)localizedDescription {
    return @"YAError: no server id, sync first";
}

@end
