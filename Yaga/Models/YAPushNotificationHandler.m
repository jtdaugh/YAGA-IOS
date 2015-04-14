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

@interface YAPushNotificationHandler ()
@property (nonatomic, strong) NSDictionary *meta;
@property (nonatomic, strong) NSString *postIdToOpen;
@end

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
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleLeave {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleJoin {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
}

- (void)handleRegistration {
    NSString *groupId = self.meta[@"group_id"];
    [self openGroupWithId:groupId refresh:YES];
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

#pragma mark - Utils

- (void)openGroupWithId:(NSString*)groupId refresh:(BOOL)refresh {
    RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", groupId]];
    
    //no local group? load groups list from server
    if(groups.count != 1) {
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
            if(!error) {
                RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", groupId]];
                
                //still no group after update? show error message
                if(groups.count != 1) {
                    YANotificationView *errorView = [YANotificationView new];
                    [errorView showMessage:NSLocalizedString(@"CANT_OPEN_GROUP_MESSAGE", @"") viewType:YANotificationTypeError actionHandler:nil];
                    return;
                }
                
                //group found after refreshing list of groups
                [self setCurrentGroup:groups[0] refresh:refresh];
            }
            else {
                //can't update from server by some reason
                [YANotificationView showMessage:NSLocalizedString(@"CANT_FETCH_GROUPS_ON_PUSH", @"") viewType:YANotificationTypeError];
            }
        }];
    }
    else {
        //group exists? update current group and refresh if needed
        [self setCurrentGroup:groups[0] refresh:refresh];
    }
}

- (void)setCurrentGroup:(YAGroup*)newGroup refresh:(BOOL)refresh {
    
    if(![[YAUser currentUser].currentGroup isEqual:newGroup]) {
        [YAUser currentUser].currentGroup = newGroup;
    }
    
    if(refresh) {
        [newGroup refresh:YES];
    }
}

- (void)groupDidRefresh:(NSNotification*)notification {
    if(!self.postIdToOpen.length)
        return;
    
    //group didn't change?
    if([notification.object isEqual:[YAUser currentUser].currentGroup]) {
        RLMResults *videos = [YAVideo objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", self.postIdToOpen]];
        if(videos.count != 1) {
            DLog(@"unable to find video with id %@", self.postIdToOpen);
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:OPEN_VIDEO_NOTIFICATION object:nil userInfo:@{@"video":videos[0]}];
        self.postIdToOpen = nil;
    }
}
@end
