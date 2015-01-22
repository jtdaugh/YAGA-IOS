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
#import "YARealmObjectUnavailable.h"

@interface YAServerTransaction ()
@property (nonatomic, strong) NSDictionary *data;
@end

@implementation YAServerTransaction

- (id)initWithDictionary:(NSDictionary*)dic {
    self = [super init];
    
    if(self) {
        self.data = dic;
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
        [self uploadeVideoCaptionWithCompletion:completion];
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
    YAGroup *group = [self groupFromData];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailable new]);
        return;
    }
    
    [[YAServer sharedServer] createGroupWithName:group.name withCompletion:^(NSDictionary *responseDictionary, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't create remote group with name %@, error %@", group.name, error.localizedDescription] type:AZNotificationTypeError];
            
            completion(nil, error);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [group.realm beginWriteTransaction];
                group.serverId = [responseDictionary objectForKey:YA_RESPONSE_ID];
                [group.realm commitWriteTransaction];
                
                [self logEvent:[NSString stringWithFormat:@"remote group: %@ created on server with id: %@", group.name, group.serverId] type:AZNotificationTypeSuccess];
                
                completion(group.serverId, nil);
            });
        }
    }];
}

- (void)renameGroupWithCompletion:(responseBlock)completion {
    YAGroup *group = [self groupFromData];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailable new]);
        return;
    }
    
    [[YAServer sharedServer] renameGroupWithId:group.serverId newName:group.name withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't rename remote group with name %@, error %@", group.name, error.localizedDescription] type:AZNotificationTypeError];
            completion(nil, error);
        }
        else {
            
            [self logEvent:[NSString stringWithFormat:@"remote group: %@ renamed", group.name] type:AZNotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}

- (void)addGroupMembersWithCompletion:(responseBlock)completion {
    NSArray *phones = self.data[YA_GROUP_ADD_MEMBERS];
    YAGroup *group = [self groupFromData];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailable new]);
        return;
    }
    
    [[YAServer sharedServer] addGroupMembersByPhones:phones toGroupWithId:group.serverId withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't add members to the group with name %@, error %@", group.name, response] type:AZNotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"members %@ added to the group: %@", phones, group.name] type:AZNotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
    
}

- (void)deleteGroupMemberWithCompletion:(responseBlock)completion {
    YAGroup *group = [self groupFromData];
    NSString *phone = self.data[YA_GROUP_DELETE_MEMBER];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailable new]);
        return;
    }
    
    [[YAServer sharedServer] removeGroupMemberByPhone:phone fromGroupWithId:group.serverId withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't remove member from the group with name %@, error %@", group.name, error.localizedDescription] type:AZNotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"member %@ removed from the group: %@", phone, group.name] type:AZNotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}

- (void)leaveGroupWithCompletion:(responseBlock)completion {
    NSString *groupId = self.data[YA_GROUP_ID];
    NSString *phone = [YAUser currentUser].phoneNumber;
    
    [[YAServer sharedServer] removeGroupMemberByPhone:phone fromGroupWithId:groupId withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"can't leave group with id: %@, error %@", groupId, error.localizedDescription] type:AZNotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"successfully left group with id: %@", groupId] type:AZNotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}

- (void)muteUnmuteGroupWithCompletion:(responseBlock)completion {
    YAGroup *group = [self groupFromData];
    
    if(!group || [group isInvalidated]) {
        completion(nil, [YARealmObjectUnavailable new]);
        return;
    }
    
    [[YAServer sharedServer] muteGroupWithId:group.serverId mute:group.muted withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"mute/unmute group with name %@, error %@", group.name, error.localizedDescription] type:AZNotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"%@ group %@", group.name, group.muted ? @"muted" : @"unmuted"] type:AZNotificationTypeSuccess];
            completion(nil, nil);
        }
    }];
}
- (void)uploadVideoWithCompletion:(responseBlock)completion {
    YAVideo *video = [self videoFromData];
    
    if(!video || [video isInvalidated]) {
        completion(nil, [YARealmObjectUnavailable new]);
        return;
    }
    
    [[YAServer sharedServer] uploadVideo:video toGroupWithId:[YAUser currentUser].currentGroup.serverId withCompletion:^(NSHTTPURLResponse *response, NSError *error) {
        if(error) {
            NSString *localId = [response isKindOfClass:[NSString class]] ? (NSString*)response : @"None";
            [self logEvent:[NSString stringWithFormat:@"unable to upload video with id:%@, error %@", localId, error.localizedDescription] type:AZNotificationTypeError];
            completion(nil, error);
        }
        else {
            if (!video || [video isInvalidated]) {
                completion(nil, [YARealmObjectUnavailable new]);
                return;
            }
            [video.realm beginWriteTransaction];
            NSString *location = [response allHeaderFields][@"Location"];
            video.url = location;
            [video.realm commitWriteTransaction];
            
            [self logEvent:[NSString stringWithFormat:@"video with id:%@ successfully uploaded to %@, serverUrl: %@", video.localId, [YAUser currentUser].currentGroup.name, video.url] type:AZNotificationTypeSuccess];
            
            completion(nil, nil);
        }
    }];
}

- (void)deleteVideoWithCompletion:(responseBlock)completion {
    NSString *videoId = self.data[YA_VIDEO_ID];
    NSString *groupId = self.data[YA_GROUP_ID];
    
    [[YAServer sharedServer] deleteVideoWithId:videoId fromGroup:groupId withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"unable to delete video with id:%@, error %@", videoId, error.localizedDescription] type:AZNotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"video with id:%@ deleted successfully", videoId] type:AZNotificationTypeSuccess];
            completion(nil, nil);
        }
        
    }];
}

- (void)uploadeVideoCaptionWithCompletion:(responseBlock)completion {
    NSString *videoId = self.data[YA_VIDEO_ID];
    
    [[YAServer sharedServer] uploadVideoCaptionWithId:videoId withCompletion:^(id response, NSError *error) {
        if(error) {
            [self logEvent:[NSString stringWithFormat:@"unable to update video caption with id:%@, error %@", videoId, error.localizedDescription] type:AZNotificationTypeError];
            completion(nil, error);
        }
        else {
            [self logEvent:[NSString stringWithFormat:@"video with id:%@ caption updated successfully", videoId] type:AZNotificationTypeSuccess];
            completion(nil, nil);
        }
        
    }];
}

- (void)logEvent:(NSString*)message type:(AZNotificationType)type {
#ifdef DEBUG
    [YAUtils showNotification:message type:type];
#else
    NSLog(@"%@", message);
#endif
}

@end
