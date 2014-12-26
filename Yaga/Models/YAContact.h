//
//  YAContact.h
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Realm/Realm.h>

@interface YAContact : RLMObject
@property NSString *name;
@property NSString *firstName;
@property NSString *lastName;
@property NSString *number;
@property BOOL registered;
- (NSString *) readableNumber;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAContact>
RLM_ARRAY_TYPE(YAContact)
