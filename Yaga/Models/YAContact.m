//
//  YAContact.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAContact.h"
#import "YAUtils.h"

@implementation YAContact

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

- (NSString *)readableNumber {
    return [YAUtils readableNumberFromString:self.number];
}

@end
