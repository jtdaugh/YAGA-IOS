//
//  YAServerTransaction.m
//  Yaga
//
//  Created by valentinkovalski on 12/31/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAServerTransaction.h"
#import "YAServer.h"
#import "YAGroup.h"
#import "YAUser.h"
#import "YAUtils.h"
#import "AFNetworking.h"

@interface YAServerTransaction ()

@end

@implementation YAServerTransaction

- (id)initWithDictionary:(NSDictionary*)dic {
    self = [super init];
    
    if(self) {
        _data = dic;
    }
    
    return self;
}

- (void)performWithCompletion:(responseBlock)completion {
    NSString *type = self.data[YA_TRANSACTION_TYPE];
    
    if([type isEqualToString:YA_TRANSACTION_TYPE_CREATE_GROUP]) {
        [self createGroupWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_RENAME_GROUP]) {
        [self renameGroupWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_ADD_GROUP_MEMBERS]) {
        [self addGroupMembersWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_DELETE_GROUP_MEMBER]) {
        [self deleteGroupMemberWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_LEAVE_GROUP]) {
        [self leaveGroupWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_MUTE_UNMUTE_GROUP]) {
        [self muteUnmuteGroupWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_UPLOAD_VIDEO]) {
        [self uploadVideoWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_DELETE_VIDEO]) {
        [self deleteVideoWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_UPDATE_CAPTION]) {
        [self uploadVideoCaptionWithCompletion:completion];
    }
}

- (YAGroup*)groupFromData {
    NSString *groupId = self.data[YA_GROUP_ID];
    YAGroup *group = [YAGroup objectInRealm:[RLMRealm defaultRealm] forPrimaryKey:groupId];
    
    return group;
}

- (YAVideo*)videoFromData {
    NSString *videoId = self.data[YA_VIDEO_ID];
    YAVideo *video = [YAVideo objectInRealm:[RLMRealm defaultRealm] forPrimaryKey:videoId];
    
    return video;
}

- (void)createGroupWithCompletion:(responseBlock)completion {
    completion(nil, nil); //old transaction should return ok
    return;
    
    YAGroup *group = [self groupFromData];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailableError new]);
        return;
    }
    
    [[YAServer sharedServer] createGroupWithName:group.name withCompletion:^(NSDictionary *responseDictionary, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't create remote group with name %@, error %@", group.name, error.localizedDescription] type:YANotificationTypeError];
            
            completion(nil, error);
        }
        else {
            if(!group || [group isInvalidated]) {
                completion(nil, [YARealmObjectUnavailableError new]);
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [group.realm beginWriteTransaction];
                group.serverId = [responseDictionary objectForKey:YA_RESPONSE_ID];
                [group.realm commitWriteTransaction];
                
                [self logEvent:[NSString stringWithFormat:@"remote group: %@ created on server with id: %@", group.name, group.serverId] type:YANotificationTypeSuccess];
                
                completion(group.serverId, nil);
            });
        }
    }];
}

- (void)renameGroupWithCompletion:(responseBlock)completion {
    completion(nil, nil); //old transaction should return ok
    return;
    
    YAGroup *group = [self groupFromData];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailableError new]);
        return;
    }
    
    [[YAServer sharedServer] renameGroupWithId:group.serverId newName:group.name withCompletion:^(id response, NSError *error) {
        
        if(!group || [group isInvalidated]) {
            completion(nil, [YARealmObjectUnavailableError new]);
            return;
        }
        
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't rename remote group with name %@, error %@", group.name, error.localizedDescription] type:YANotificationTypeError];
            completion(nil, error);
        }
        else {
            
            [self logEvent:[NSString stringWithFormat:@"remote group: %@ renamed", group.name] type:YANotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}

- (void)addGroupMembersWithCompletion:(responseBlock)completion {
    completion(nil, nil); //old transaction should return ok
    return;
    
    NSArray *phones = self.data[YA_GROUP_ADD_MEMBER_PHONES];
    NSArray *usernames = self.data[YA_GROUP_ADD_MEMBER_NAMES];
    
    YAGroup *group = [self groupFromData];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailableError new]);
        return;
    }
    
    [[YAServer sharedServer] addGroupMembersByPhones:phones andUsernames:usernames toGroupWithId:group.serverId withCompletion:^(id response, NSError *error) {
        if(!group || [group isInvalidated]) {
            completion(nil, [YARealmObjectUnavailableError new]);
            return;
        }
        
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't add members to the group with name %@, error %@", group.name, response] type:YANotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"members %@ added to the group: %@", phones, group.name] type:YANotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
    
}

- (void)deleteGroupMemberWithCompletion:(responseBlock)completion {
    completion(nil, nil); //old transaction should return ok
    return;
    
    YAGroup *group = [self groupFromData];
    NSString *phone = self.data[YA_GROUP_DELETE_MEMBER];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailableError new]);
        return;
    }
    
    [[YAServer sharedServer] removeGroupMemberByPhone:phone fromGroupWithId:group.serverId withCompletion:^(id response, NSError *error) {
        
        if(!group || [group isInvalidated]) {
            completion(nil, [YARealmObjectUnavailableError new]);
            return;
        }
        
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't remove member from the group with name %@, error %@", group.name, error.localizedDescription] type:YANotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"member %@ removed from the group: %@", phone, group.name] type:YANotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}

- (void)leaveGroupWithCompletion:(responseBlock)completion {
    completion(nil, nil); //old transaction should return ok
    return;
    
    NSString *groupId = self.data[YA_GROUP_ID];
    NSString *phone = [YAUser currentUser].phoneNumber;
    
    [[YAServer sharedServer] removeGroupMemberByPhone:phone fromGroupWithId:groupId withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't leave group with id: %@, error %@", groupId, error.localizedDescription] type:YANotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"successfully left group with id: %@", groupId] type:YANotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}

- (void)muteUnmuteGroupWithCompletion:(responseBlock)completion {
    completion(nil, nil); //old transaction should return ok
    return;
    
    YAGroup *group = [self groupFromData];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailableError new]);
        return;
    }
    
    [[YAServer sharedServer] muteGroupWithId:group.serverId mute:group.muted withCompletion:^(id response, NSError *error) {
        if(!group || [group isInvalidated]) {
            completion(nil, [YARealmObjectUnavailableError new]);
            return;
        }

        if(error) {
            [self logEvent:[NSString stringWithFormat:@"mute/unmute group with name %@, error %@", group.name, error.localizedDescription] type:YANotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"%@ group %@", group.name, group.muted ? @"muted" : @"unmuted"] type:YANotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}

- (void)deleteVideoWithCompletion:(responseBlock)completion {
    completion(nil, nil); //old transaction should return ok
    return;
    
    YAVideo *video = [self videoFromData];
    NSString *groupId = self.data[YA_GROUP_ID];
    
    if(!video || [video isInvalidated]) {
        completion(nil, [YARealmObjectUnavailableError new]);
        return;
    }
    NSString *videoServerId = video.serverId;
    [[YAServer sharedServer] deleteVideoWithId:videoServerId fromGroup:groupId withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"unable to delete video with id:%@, error %@", videoServerId, error.localizedDescription] type:YANotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"video with id:%@ deleted successfully", videoServerId] type:YANotificationTypeSuccess];
            completion(nil, nil);
        }
        
    }];
}

- (void)uploadVideoWithCompletion:(responseBlock)completion {
    YAVideo *video = [self videoFromData];
    YAGroup *group = [self groupFromData];
    
    if(!video || [video isInvalidated] || !group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailableError new]);
        return;
    }
    
    NSString *videoLocalId = video.localId;
    NSString *groupName = group.name;
    
    if(!group.serverId.length) {
        completion(nil, [YANoServerIdError new]);
        return;
    }
    
    [[YAServer sharedServer] uploadVideo:video
                           toGroupWithId:group.serverId
                          withCompletion:^(NSHTTPURLResponse *response, NSError *error) {
                              if(error) {
                                  DLog(@"can't upload video, reason: %@", error.localizedDescription);
                                  completion(nil, error);
                              }
                              else {
                                  if (!video || [video isInvalidated]) {
                                      completion(nil, [YARealmObjectUnavailableError new]);
                                      return;
                                  }
                                  [video.realm beginWriteTransaction];
                                  NSString *location = [response allHeaderFields][@"Location"];
                                  video.url = location;
                                  [video.realm commitWriteTransaction];
                                  
                                  [self logEvent:[NSString stringWithFormat:@"video with id:%@ successfully uploaded to %@", videoLocalId, groupName] type:YANotificationTypeSuccess];
                                  
                                  completion(nil, nil);
                                  
                                  [[Mixpanel sharedInstance] track:@"Video posted"];
                              }
                          }];
}

- (void)uploadVideoCaptionWithCompletion:(responseBlock)completion {
    YAVideo *video = [self videoFromData];
    
    if(!video || [video isInvalidated]) {
        completion(nil, [YARealmObjectUnavailableError new]);
        return;
    }
    
    NSString *videoServerId = video.serverId;
    
    if(!videoServerId.length) {
        completion(nil, [YANoServerIdError new]);
        return;
    }
    
    [[YAServer sharedServer] uploadVideoCaptionWithId:videoServerId withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"unable to update video caption with id:%@, error %@", videoServerId, error.localizedDescription] type:YANotificationTypeError];
            completion(nil, error);
        }
        else {
            [[Mixpanel sharedInstance] track:@"Video captioned"];
            [self logEvent:[NSString stringWithFormat:@"video with id:%@ caption updated successfully", videoServerId] type:YANotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}

- (void)logEvent:(NSString*)message type:(YANotificationType)type {
    DLog(@"%@", message);
}

@end
