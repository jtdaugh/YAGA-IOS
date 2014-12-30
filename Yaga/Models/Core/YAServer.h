//
//  YAAuthManager.h
//  Yaga
//
//  Created by Iegor on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAGroup.h"

#define YA_RESPONSE_ID                  @"id"
#define YA_RESPONSE_NAME                @"name"
#define YA_RESPONSE_MEMBERS             @"members"
#define YA_RESPONSE_MEMBER_PHONE        @"phone"
#define YA_RESPONSE_MEMBER_JOINED_AT    @"joined_at"
#define YA_RESPONSE_RESULT              @"result"
#define YA_RESPONSE_USER                @"user"
#define YA_RESPONSE_TOKEN               @"token"

@interface YAServer : NSObject
typedef void(^responseBlock)(id response, NSError* error);
+ (instancetype)sharedServer;

//onboarding & token
- (void)authentificatePhoneNumberBySMS:(NSString*)number withCompletion:(responseBlock)completion;
- (void)sendTokenRequestWithCompletion:(responseBlock)completion;
- (void)getInfoForCurrentUserWithCompletion:(responseBlock)completion;
- (void)registerUsername:(NSString*)name withCompletion:(responseBlock)completion;

//groups and memebers
- (void)createGroupWithName:(NSString*)groupName withCompletion:(responseBlock)completion;
- (void)getGroupsWithCompletion:(responseBlock)completion;
- (void)updateGroupMembersForGroup:(YAGroup*)group withCompletion:(responseBlock)completion;
- (void)renameGroup:(YAGroup*)group newName:(NSString*)newName withCompletion:(responseBlock)completion;
- (void)removeGroup:(YAGroup*)group withCompletion:(responseBlock)completion;

@end
