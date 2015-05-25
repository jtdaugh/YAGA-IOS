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
#define YA_RESPONSE_NAMER               @"namer"
#define YA_RESPONSE_FONT                @"font"
#define YA_RESPONSE_LIKES               @"likes"
#define YA_RESPONSE_LIKERS              @"likers"
#define YA_RESPONSE_MEMBERS             @"members"
#define YA_RESPONSE_MEMBER_PHONE        @"phone"
#define YA_RESPONSE_MEMBER_JOINED_AT    @"joined_at"
#define YA_RESPONSE_RESULT              @"result"
#define YA_RESPONSE_USER                @"user"
#define YA_RESPONSE_TOKEN               @"token"

#define YA_VIDEO_POST                   @"post"
#define YA_VIDEO_POSTS                  @"posts"
#define YA_VIDEO_ATTACHMENT             @"attachment"
#define YA_VIDEO_ATTACHMENT_PREVIEW     @"attachment_preview"
#define YA_VIDEO_READY_AT               @"ready_at"
#define YA_VIDEO_DELETED                @"deleted"
#define YA_GROUP_UPDATED_AT             @"updated_at"

#define YA_LAST_DEVICE_TOKEN_SYNC_DATE @"lastTokenSyncDate"

@interface YAServer : NSObject
typedef void(^responseBlock)(id response, NSError* error);

+ (instancetype)sharedServer;

//onboarding & token
- (void)authentificatePhoneNumberBySMS:(NSString*)number withCompletion:(responseBlock)completion;
- (void)requestAuthTokenWithAuthCode:(NSString*)authCode withCompletion:(responseBlock)completion;
- (void)getInfoForCurrentUserWithCompletion:(responseBlock)completion;
- (void)registerUsername:(NSString*)name withCompletion:(responseBlock)completion;

//groups and memebers
- (void)createGroupWithName:(NSString*)groupName withCompletion:(responseBlock)completion;
- (void)getGroupsWithCompletion:(responseBlock)completion;

- (void)addGroupMembersByPhones:(NSArray*)phones andUsernames:(NSArray*)usernames toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion;
- (void)removeGroupMemberByPhone:(NSString*)phone fromGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion;
- (void)leaveGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion; //same as removeGroupMemberByPhone but show other localised messages
- (void)groupInfoWithId:(NSString*)serverGroupId since:(NSDate*)since withCompletion:(responseBlock)completion;
- (void)renameGroupWithId:(NSString*)serverGroupId newName:(NSString*)newName withCompletion:(responseBlock)completion;
- (void)muteGroupWithId:(NSString*)serverGroupId mute:(BOOL)mute withCompletion:(responseBlock)completion;

//posts
- (void)uploadVideo:(YAVideo*)video toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion;
- (void)deleteVideoWithId:(NSString*)serverVideoId fromGroup:(NSString*)serverGroupId withCompletion:(responseBlock)completion;
- (void)uploadVideoCaptionWithId:(NSString*)serverVideoId withCompletion:(responseBlock)completion;
- (void)likeVideo:(YAVideo*)video withCompletion:(responseBlock)completion;
- (void)unLikeVideo:(YAVideo*)video withCompletion:(responseBlock)completion;

- (void)registerDeviceTokenWithCompletion:(responseBlock)completion;

- (void)startMonitoringInternetConnection:(BOOL)start;

- (void)getYagaUsersFromPhonesArray:(NSArray*)phones withCompletion:(responseBlock)completion;
//
@property (readonly) BOOL serverUp;
- (void)sync;
@property (nonatomic, strong) NSDate *lastUpdateTime;

////execute when after recording, when gif is generated
//- (void)uploadGIFForVideoWithServerId:(NSString*)videoServerId;

- (BOOL)hasAuthToken;
@end
