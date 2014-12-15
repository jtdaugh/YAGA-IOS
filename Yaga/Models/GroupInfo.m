//
//  GroupInfo.m
//  Pic6
//
//  Created by Raj Vir on 8/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupInfo.h"

@implementation GroupInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    return @{
             @"name": @"name",
             @"groupId": @"groupId",
             @"members": @"members"
             };
}

@end
