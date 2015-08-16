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
typedef void(^completionBlockWithResult)(NSError *error, id result);
typedef void(^updateVideosCompletionBlock)(NSError *error, NSArray *newVideos);

@interface YAGroup : RLMObject
@property NSString *name;
@property NSString *localId;
@property NSString *serverId;
@property NSDate *updatedAt;
@property NSDate *refreshedAt;
@property BOOL hasUnviewedVideos;
@property BOOL muted;

@property BOOL publicGroup;

@property BOOL amFollowing;
@property BOOL amMember;
@property NSInteger followerCount;

@property BOOL streamGroup;

@property RLMArray<YAContact> *members;
@property RLMArray<YAContact> *pending_members;
@property RLMArray<YAVideo> *videos;

//server side paging, we can not use self.videos.count for offset param because of deleted videos which are returned too, keeping nextPageIndex for that
@property long totalPages;
@property int  nextPageIndex;

- (NSString*)membersString;
- (NSSet*)phonesSet;

+ (void)updateGroupsFromServerWithCompletion:(completionBlock)block;

//
+ (void)groupWithName:(NSString*)name isPrivate:(BOOL)isPrivate withCompletion:(completionBlockWithResult)completion;
- (void)rename:(NSString*)newName withCompletion:(completionBlock)completion;
- (void)addMembers:(NSArray*)contacts withCompletion:(completionBlock)completion;
- (void)removeMember:(YAContact*)contact withCompletion:(completionBlock)completion;
- (void)leaveWithCompletion:(completionBlock)completion;
- (void)muteUnmuteWithCompletion:(completionBlock)completion;
- (void)refresh;
- (void)refresh:(BOOL)showPullDownToRefresh;
+ (YAGroup*)group;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAGroup>
RLM_ARRAY_TYPE(YAGroup)



