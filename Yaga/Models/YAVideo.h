//
//  YAVideo.h
//  Yaga
//
//  Created by valentinkovalski on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Realm/Realm.h>

@interface YAVideo : RLMObject
@property NSString *movFilename;
@property NSString *gifFilename;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAVideo>
RLM_ARRAY_TYPE(YAVideo)
