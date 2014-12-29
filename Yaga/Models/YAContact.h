//
//  YAContact.h
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Realm/Realm.h>

#define nUsername @"username"
#define nPhone @"phone"
#define nCountry @"country"
#define nToken @"token"
#define nUserId @"user_id"
#define nCompositeName @"composite_name"
#define nFirstname @"firstname"
#define nLastname @"lastname"
#define nRegistered @"registered"

#define nCurrentGroupId @"current_group_id"

#define DIAL_CODE @"dial_code"
#define COUNTRY_CODE @"code"

@interface YAContact : RLMObject
@property NSString *name;
@property NSString *firstName;
@property NSString *lastName;
@property NSString *number;
@property BOOL registered;
- (NSString *) readableNumber;

+ (YAContact*)contactFromDictionary:(NSDictionary*)dictionary;
- (NSDictionary*)dictionaryRepresentation;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAContact>
RLM_ARRAY_TYPE(YAContact)
