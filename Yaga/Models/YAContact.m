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
#import "YAServer.h"

@implementation YAContact

+ (NSDictionary *)defaultPropertyValues{
    return @{@"name":@"", @"firstName":@"", @"lastName":@"", @"serverId":@"", @"username":@""};
}

// Specify properties to ignore (Realm won't persist these)
+ (NSArray *)ignoredProperties
{
    return @[];
}

- (NSString *)readableNumber {
    return [YAUtils readableNumberFromString:self.number];
}

+ (YAContact*)contactFromDictionary:(NSDictionary*)dictionary {
    NSString *phoneNumber = dictionary[nPhone];
    NSString *predicate = [NSString stringWithFormat:@"number = '%@'", phoneNumber];
    RLMResults *existingContacts = [YAContact objectsWhere:predicate];
    
    YAContact *contact;
    if(existingContacts.count) {
        contact = existingContacts[0];
    }
    else {
        contact = [YAContact new];
    }

    NSString *name = dictionary[nCompositeName];
    if (name) {
        contact.name = dictionary[nCompositeName];
    } else {
        contact.name = dictionary[nName];
    }

    contact.firstName = dictionary[nFirstname]  ? dictionary[nFirstname] : @"";
    contact.lastName  = dictionary[nLastname]   ? dictionary[nLastname]  : @"";
    contact.number = dictionary[nPhone];
    contact.registered = NO;
    if([dictionary[nUsername] length])
        contact.username = dictionary[nUsername];

    return contact;
}

- (void)updateFromDictionary:(NSDictionary*)dictionary {
    NSString *serverId = dictionary[YA_RESPONSE_USER][YA_RESPONSE_ID];
    NSString *phoneNumber = dictionary[YA_RESPONSE_USER][YA_RESPONSE_MEMBER_PHONE];
    NSString *username = dictionary[YA_RESPONSE_USER][YA_RESPONSE_NAME];
    
    NSDictionary *existingUserData = [YAUser currentUser].phonebook[phoneNumber];
    if(![username isKindOfClass:[NSNull class]]) {
        self.username = username;
    }
    else {
        self.username = @"";//[[NameGenerator sharedGeneratror] nameForPhoneNumber:phoneNumber];
    }
    
    if(existingUserData) {
        self.name = existingUserData[nCompositeName];
        self.firstName = existingUserData[nFirstname];
        self.lastName  = existingUserData[nLastname];
        if(!self.username.length)
            self.username = existingUserData[nCompositeName];
    }
    
    self.serverId = serverId;
    self.number = phoneNumber;
    self.registered = YES;
}

- (NSDictionary*)dictionaryRepresentation {
    NSDictionary *result = @{nCompositeName:self.name, nFirstname:self.firstName, nLastname:self.lastName, nPhone:self.number, nRegistered:[NSNumber numberWithBool:self.registered], nUsername:self.username};
    return result;
}

- (NSString*)displayName {
    NSString *name = self.username;
    if(!name.length) {
        if([[YAUser currentUser].phonebook objectForKey:self.number]) {
            name = self[nCompositeName];
        }
        else {
            name = defaultUsername;
        }
    }
    return name;
}
@end
