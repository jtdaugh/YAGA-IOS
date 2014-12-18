//
//  YAGroup.h
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Realm/Realm.h>
#import "YAContact.h"
#import "YAVideo.h"

@interface YAGroup : RLMObject
@property NSString *name;
@property NSString *groupId;

@property RLMArray<YAContact> *members;
@property RLMArray<YAVideo> *videos;

- (NSString*)membersString;
+ (NSString*)generateGroupId;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAGroup>
RLM_ARRAY_TYPE(YAGroup)



