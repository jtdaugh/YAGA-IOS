//
//  YAContact.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAContact.h"
#import "YAUtils.h"
#import "YAUser.h"
#import "NameGenerator.h"

@implementation YAContact

+ (NSDictionary *)defaultPropertyValues{
    return @{@"name":@"", @"firstName":@"", @"lastName":@""};
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
    contact.username = contact.name;
    contact.registered = [dictionary objectForKey:@"joined_at"] != nil;

    return contact;
}

+ (YAContact*)contactFromPhoneNumber:(NSString*)phoneNumber andUsername:(NSString*)username {
    YAContact *contact = [YAContact new];
    NSDictionary *existingUserData = [YAUser currentUser].phonebook[phoneNumber];
    if(![username isKindOfClass:[NSNull class]]) {
        contact.username = username;
    }
    else {
        contact.username = [[NameGenerator sharedGeneratror] nameForPhoneNumber:phoneNumber];
    }
    if(existingUserData) {
        contact.name = existingUserData[nCompositeName];
        contact.firstName = existingUserData[nFirstname];
        contact.lastName  = existingUserData[nLastname];
    }
    
    contact.number = phoneNumber;
    
    return contact;
}

- (NSDictionary*)dictionaryRepresentation {
    NSDictionary *result = @{nCompositeName:self.name, nFirstname:self.firstName, nLastname:self.lastName, nPhone:self.number, nRegistered:[NSNumber numberWithBool:self.registered]};
    return result;
}
@end
