//
//  YAAuthManager.h
//  Yaga
//
//  Created by Iegor on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import "YAVideo.h"
#import "YARealmObjectUnavailableError.h"
#import "YANoServerIdError.h"

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
- (void)getGroupsWithCompletion:(responseBlock)completion publicGroups:(BOOL)publicGroups;
- (void)searchGroupsWithCompletion:(responseBlock)completion;
- (void)joinGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion;

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
- (void)copyVideo:(YAVideo*)video toGroupsWithIds:(NSArray*)groupIds withCompletion:(responseBlock)completion;

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

- (void)registerDeviceTokenIfNeeded;
@end
