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


+ (NSDictionary *)defaultPropertyValues{
    return @{@"lastName":@""};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

- (NSString *)readableNumber {
    return [YAUtils readableNumberFromString:self.number];
}

+ (YAContact*)contactFromDictionary:(NSDictionary*)dictionary {
    YAContact *contact = [YAContact new];
    contact.name = dictionary[nCompositeName];
    contact.firstName = dictionary[nFirstname];
    contact.lastName  = dictionary[nLastname];
    contact.number = dictionary[nPhone];
    contact.registered = [dictionary objectForKey:@"joined_at"] != nil;

    return contact;
}

- (NSDictionary*)dictionaryRepresentation {
    NSDictionary *result = @{nCompositeName:self.name, nFirstname:self.firstName, nLastname:self.lastName, nPhone:self.number, nRegistered:[NSNumber numberWithBool:self.registered]};
    return result;
}
@end
