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

- (void)handlePushWithUserInfo:(NSDictionary*)userInfo {
    NSDictionary *meta = userInfo[@"meta"];
    
    if(!meta.allKeys.count)
        return;
    
    self.meta = meta;
    
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
    
    //        if([groupId isEqualToString:[YAUser currentUser].currentGroup.serverId]) {
    //            [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_GROUP_NOTIFICATION object:[YAUser currentUser].currentGroup];
    //        }
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
    [self openGroupWithId:groupId refresh:YES refreshCompletionHandler:^{
#warning open video from push not implemented
    }];
}

#pragma mark - Utils
- (void)openGroupWithId:(NSString*)groupId refresh:(BOOL)refresh {
    [self openGroupWithId:groupId refresh:refresh refreshCompletionHandler:nil];
}

- (void)openGroupWithId:(NSString*)groupId refresh:(BOOL)refresh refreshCompletionHandler:(void(^)(void))refreshCompletion {
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
                [self setCurrentGroup:groups[0] refresh:refresh refreshCompletionHandler:refreshCompletion];
            }
            else {
                //can't update from server by some reason
                [YANotificationView showMessage:NSLocalizedString(@"CANT_FETCH_GROUPS_ON_PUSH", @"") viewType:YANotificationTypeError];
            }
        }];
    }
    else {
        //group exists? update current group and refresh if needed
        [self setCurrentGroup:groups[0] refresh:refresh refreshCompletionHandler:refreshCompletion];
    }
}

- (void)setCurrentGroup:(YAGroup*)newGroup refresh:(BOOL)refresh refreshCompletionHandler:(void(^)(void))refreshCompletion {
    
    if(![[YAUser currentUser].currentGroup isEqual:newGroup]) {
        [YAUser currentUser].currentGroup = newGroup;
        [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_GROUP_NOTIFICATION object:[YAUser currentUser].currentGroup];
    }
    
    if(refresh) {
        [newGroup refreshWithCompletion:^(NSError *error, NSArray *newVideos) {
            if(error) {
                [YANotificationView showMessage:NSLocalizedString(@"CANT_FETCH_GROUP_VIDEOS_ON_PUSH", @"") viewType:YANotificationTypeError];
            }
        }];
    }
}
@end
