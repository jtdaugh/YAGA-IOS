//
//  YAAuthManager.h
//  Yaga
//
//  Created by Iegor on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAVideo.h"

#define YA_RESPONSE_ID                  @"id"
#define YA_RESPONSE_NAME                @"name"
#define YA_RESPONSE_MEMBERS             @"members"
#define YA_RESPONSE_MEMBER_PHONE        @"phone"
#define YA_RESPONSE_MEMBER_JOINED_AT    @"joined_at"
#define YA_RESPONSE_RESULT              @"result"
#define YA_RESPONSE_USER                @"user"
#define YA_RESPONSE_TOKEN               @"token"

#define YA_VIDEO_POST           @"post"
#define YA_VIDEO_POSTS          @"posts"
#define YA_VIDEO_ATTACHMENT     @"attachment"
#define YA_VIDEO_READY_AT       @"ready_at"

@interface YAServer : NSObject
typedef void(^responseBlock)(id response, NSError* error);

+ (instancetype)sharedServer;

//onboarding & token
- (void)authentificatePhoneNumberBySMS:(NSString*)number withCompletion:(responseBlock)completion;
- (void)requestAuthTokenWithCompletion:(responseBlock)completion;
- (void)getInfoForCurrentUserWithCompletion:(responseBlock)completion;
- (void)registerUsername:(NSString*)name withCompletion:(responseBlock)completion;

//groups and memebers
- (void)createGroupWithName:(NSString*)groupName withCompletion:(responseBlock)completion;
- (void)getGroupsWithCompletion:(responseBlock)completion;

- (void)addGroupMembersByPhones:(NSArray*)phones toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion;
- (void)removeGroupMemberByPhone:(NSString*)phone fromGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion;

- (void)groupInfoWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion;
- (void)renameGroupWithId:(NSString*)serverGroupId newName:(NSString*)newName withCompletion:(responseBlock)completion;
- (void)muteGroupWithId:(NSString*)serverGroupId mute:(BOOL)mute withCompletion:(responseBlock)completion;

//posts
- (void)uploadVideo:(YAVideo*)video toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion;
- (void)deleteVideoWithId:(NSString*)serverVideoId fromGroup:(NSString*)serverGroupId withCompletion:(responseBlock)completion;

- (void)startMonitoringInternetConnection:(BOOL)start;

//
@property (readonly) BOOL serverUp;
- (void)sync;
@property (nonatomic, strong) NSDate *lastUpdateTime;
@end