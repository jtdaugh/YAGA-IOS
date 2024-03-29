//
//  YAPushNotificationHandler.m
//  Yaga
//
//  Created by valentinkovalski on 2/27/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAPushNotificationHandler.h"
#import "YANotificationView.h"

#import "YAGroup.h"
#import "YAUser.h"
#import "YAServer.h"

@interface YAPushNotificationHandler ()
@property (nonatomic, strong) NSDictionary *meta;
@property (nonatomic, strong) NSString *postIdToOpen;
@property (nonatomic, strong) YAGroup *groupToOpen;
@end

typedef void (^groupChangedCompletionBlock)(void);

@implementation YAPushNotificationHandler

+ (instancetype)sharedHandler {
    static YAPushNotificationHandler *s = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        s = [[self alloc] init];
    });
    return s;
}

- (id)init {
    self = [super init];
    if(self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_DID_REFRESH_NOTIFICATION object:nil];
}

- (void)handlePushWithUserInfo:(NSDictionary*)userInfo {
    if(![[YAServer sharedServer] hasAuthToken])
        return;
    
    NSDictionary *meta = userInfo[@"meta"];
    
    if(!meta.allKeys.count)
        return;
    
    self.meta = meta;
    
    self.postIdToOpen = nil;
    
    NSString *eventName = meta[@"event"];
    
    if([eventName isEqualToString:@"post"]) {
        [self handlePostEvent];
    }
    else if([eventName isEqualToString:@"invite"]) {
        [self handleInvite];
    }
    else if([eventName isEqualToString:@"members"]) {
        [self handleMembers];
    }
    else if([eventName isEqualToString:@"kick"]) {
        [self handleKick];
    }
    else if([eventName isEqualToString:@"leave"]) {
        [self handleLeave];
    }
    else if([eventName isEqualToString:@"join"]) {
        [self handleJoin];
    }
    else if([eventName isEqualToString:@"registration"]) {
        [self handleRegistration];
    }
    else if([eventName isEqualToString:@"like"]) {
        [self handleLike];
    }
    else if([eventName isEqualToString:@"caption"]) {
        [self handleCaption];
    }
    else if([eventName isEqualToString:@"comment"]) {
        [self handleComment];
    }
    else if([eventName isEqualToString:@"rename"]) {
        [self handleGroupRename];
    }
    else if([eventName isEqualToString:@"request"]) {
        [self handleGroupJoinRequest];
    }
    else if([eventName isEqualToString:@"approve"]) {
        [self handleApprovePublic];
    }
    else if([eventName isEqualToString:@"reject"]) {
        [self handleReject];
    }
    else if([eventName isEqualToString:@"pending"]) {
        [self handleNewPendingVideos];
    }
}

- (void)handlePostEvent {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleInvite {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleMembers {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleKick {
    [[YAServer sharedServer] sync];
}

- (void)handleLeave {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleJoin {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleNewPendingVideos {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId toPending:YES refresh:YES completion:nil];
}

- (void)handleRegistration {
    //don't do anything on registration event, there will be no group id
}

- (void)handleLike {
    NSString *groupId = self.meta[@"group_id"];
    NSString *postId = self.meta[@"post_id"];
    
    self.postIdToOpen = postId;
    
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleCaption {
    [self handleLike];
}

- (void)handleComment {
    [self handleLike];
}

- (void)handleGroupRename {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleGroupJoinRequest {
    NSString *groupId = self.meta[@"group_id"];

    [self openGroupWithId:groupId toPending:NO refresh:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:OPEN_GROUP_OPTIONS_NOTIFICATION object:self.groupToOpen];
        });
    }];
}

- (void)handleApprovePublic {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId toPending:NO refresh:YES completion:nil];
}

- (void)handleReject {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

#pragma mark - Utils
- (void)openGroupWithId:(NSString*)groupId toPending:(BOOL)toPending refresh:(BOOL)refresh completion:(groupChangedCompletionBlock)completion {
    RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", groupId]];
    
    //no local group? load groups list from server
    if(groups.count != 1) {
        __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Please wait...", @"")];
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
            [hud hide:YES];
            
            if(!error) {
                RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", groupId]];
                
                //still no group after update? show error message
                if(groups.count != 1) {
                    YANotificationView *errorView = [YANotificationView new];
                    [errorView showMessage:NSLocalizedString(@"CANT_OPEN_GROUP_MESSAGE", @"") viewType:YANotificationTypeError actionHandler:nil];
                    return;
                }
                
                //group found after refreshing list of groups
                [self sendNotificationToOpenGroup:groups[0] toPending:toPending refresh:refresh];
                if(completion)
                    completion();
            }
            else {
                //can't update from server by some reason
                [YANotificationView showMessage:NSLocalizedString(@"CANT_FETCH_GROUPS_ON_PUSH", @"") viewType:YANotificationTypeError];
            }
        }];
    }
    else {
        //group exists? update current group and refresh if needed
        [self sendNotificationToOpenGroup:groups[0] toPending:toPending refresh:refresh];
        if(completion)
            completion();
    }
}

- (void)openGroupWithId:(NSString*)groupId refresh:(BOOL)refresh {
    [self openGroupWithId:groupId toPending:NO refresh:refresh completion:nil];
}

- (void)sendNotificationToOpenGroup:(YAGroup*)newGroup toPending:(BOOL)toPending refresh:(BOOL)refresh {

    self.groupToOpen = newGroup;
    
    if(refresh) {
        if (toPending)
            [newGroup refreshPendingVideos];
        else
            [newGroup refresh:YES];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OPEN_GROUP_GRID_NOTIFICATION object:newGroup userInfo:@{kOpenToPendingVideos : @(toPending)}];
}

- (void)groupDidRefresh:(NSNotification*)notification {
    if(!self.postIdToOpen.length)
        return;
    
    //group didn't change?
    if([notification.object isEqual:self.groupToOpen]) {
        RLMResults *videos = [YAVideo objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", self.postIdToOpen]];
        if(videos.count != 1) {
            DLog(@"unable to find video with id %@", self.postIdToOpen);
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:OPEN_VIDEO_NOTIFICATION object:nil userInfo:@{@"video":videos[0]}];
        self.postIdToOpen = nil;
    }
}

- (BOOL)shouldHandlePushEventWithoutUserIteraction:(NSDictionary*)userInfo {
    NSDictionary *meta = userInfo[@"meta"];
    
    if(!meta.allKeys.count)
        return NO;
    
    NSString *eventName = meta[@"event"];
    
    if([eventName isEqualToString:@"kick"]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)shouldHandlePushEvent:(NSDictionary*)userInfo {
    NSDictionary *meta = userInfo[@"meta"];
    
    if(!meta.allKeys.count)
        return NO;
    
    NSString *eventName = meta[@"event"];
    if(eventName.length == 0)
        return NO;
    
    if([eventName isEqualToString:@"registration"]) {
        return NO;
    }
    
    if([eventName isEqualToString:@"reject"]) {
        NSString *userId = self.meta[@"user_id"];
        if ([[YAUser currentUser].serverId isEqualToString:userId]) {
            return NO;
        }
    }
    
    return YES;
}

@end
