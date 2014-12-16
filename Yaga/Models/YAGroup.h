//
//  YAGroup.h
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Realm/Realm.h>

@interface YAGroup : RLMObject
@property NSString *name;
@property NSString *groupId;
@property NSMutableArray *members;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAGroup>
RLM_ARRAY_TYPE(YAGroup)
