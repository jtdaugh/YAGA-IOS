//
//  YAGroup.h
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAContact.h"
#import "YAVideo.h"

typedef void(^completionBlock)(NSError *error);

@interface YAGroup : RLMObject
@property NSString *name;
@property NSString *localId;
@property NSString *serverId;
@property BOOL muted;

@property RLMArray<YAContact> *members;
@property RLMArray<YAVideo> *videos;

- (NSString*)membersString;
- (NSSet*)phonesSet;

+ (void)updateGroupsFromServerWithCompletion:(completionBlock)block;

//
+ (YAGroup*)groupWithName:(NSString*)name;
- (void)rename:(NSString*)newName;
- (void)addMembers:(NSArray*)membersArray;
- (void)removeMember:(YAContact*)contact;
- (void)leave;
- (void)muteUnmute;
- (void)updateVideos;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAGroup>
RLM_ARRAY_TYPE(YAGroup)



