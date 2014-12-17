//
//  YAGroup.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroup.h"

@implementation YAGroup

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

- (NSString*)membersString {
    NSString *results = @"";
    for(int i = 0; i < self.members.count; i++) {
        YAContact *contact = (YAContact*)[self.members objectAtIndex:i];
        results = [results stringByAppendingFormat:@"%@%@", contact.name, (i < self.members.count - 1 ? @", " : @"")];
    }
    
    return results;
}
@end
