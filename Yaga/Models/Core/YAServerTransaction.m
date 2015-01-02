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
}

- (YAGroup*)groupFromData {
    NSString *groupId = self.data[YA_GROUP_ID];
    YAGroup *group = [YAGroup objectInRealm:[RLMRealm defaultRealm] forPrimaryKey:groupId];
   
    return group;
}

- (void)createGroupWithCompletion:(responseBlock)completion {
    __block YAGroup *group = [self groupFromData];
    
    [[YAServer sharedServer] createGroupWithName:group.name withCompletion:^(NSDictionary *responseDictionary, NSError *error) {
        if(error) {
            NSLog(@"can't create remote group with name %@, error %@", group.name, error.localizedDescription);
            completion(nil, error);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [group.realm beginWriteTransaction];
                group.serverId = [responseDictionary objectForKey:YA_RESPONSE_ID];
                [group.realm commitWriteTransaction];
            });
            
            NSLog(@"remote group: %@ created on server with id: %@", group.name, group.serverId);
            completion(group.serverId, nil);
        }
    }];
}

- (void)renameGroupWithCompletion:(responseBlock)completion {
    __block YAGroup *group = [self groupFromData];
    
    [[YAServer sharedServer] renameGroupWithId:group.serverId newName:group.name withCompletion:^(id response, NSError *error) {
        if(error) {
            NSLog(@"can't rename remote group with name %@, error %@", group.name, error.localizedDescription);
            completion(nil, error);
        }
        else {
            NSLog(@"remote group: %@ renamed", group.name);
            completion(nil, nil);
        }
    }];
}

- (void)addGroupMembersWithCompletion:(responseBlock)completion {
    NSArray *phones = self.data[YA_GROUP_ADD_MEMBERS];
    YAGroup *group = [self groupFromData];
    
    [[YAServer sharedServer] addGroupMembersByPhones:phones toGroupWithId:group.serverId withCompletion:^(id response, NSError *error) {
        if(error) {
            NSLog(@"can't add members to the group with name %@, error %@", group.name, error.localizedDescription);
            completion(nil, error);
        }
        else {
            NSLog(@"members %@ added to the group: %@", phones, group.name);
            completion(nil, nil);
        }
    }];

}

- (void)deleteGroupMemberWithCompletion:(responseBlock)completion {
    YAGroup *group = [self groupFromData];
    NSString *phone = self.data[YA_GROUP_DELETE_MEMBER];
    
    [[YAServer sharedServer] removeGroupMemberByPhone:phone fromGroupWithId:group.serverId withCompletion:^(id response, NSError *error) {
        if(error) {
            NSLog(@"can't remove member from the group with name %@, error %@", group.name, error.localizedDescription);
            completion(nil, error);
        }
        else {
            NSLog(@"member %@ removed from the group: %@", phone, group.name);
            completion(nil, nil);
        }
    }];
}

- (void)leaveGroupWithCompletion:(responseBlock)completion {
    NSString *groupId = self.data[YA_GROUP_ID];
    NSString *phone = [YAUser currentUser].phoneNumber;

    [[YAServer sharedServer] removeGroupMemberByPhone:phone fromGroupWithId:groupId withCompletion:^(id response, NSError *error) {
        if(error) {
            NSLog(@"can't leave group with id: %@, error %@", groupId, error.localizedDescription);
            completion(nil, error);
        }
        else {
            NSLog(@"successfully left group with id: %@", groupId);
            completion(nil, nil);
        }
    }];
}

- (void)muteUnmuteGroupWithCompletion:(responseBlock)completion {
    YAGroup *group = [self groupFromData];
    [[YAServer sharedServer] muteGroupWithId:group.serverId mute:group.muted withCompletion:^(id response, NSError *error) {
        if(error) {
            NSLog(@"mute/unmute group with name %@, error %@", group.name, error.localizedDescription);
            completion(nil, error);
        }
        else {
            NSLog(@"%@ group %@", group.name, group.muted ? @"muted" : @"unmuted");
            completion(nil, nil);
        }
    }];
}
@end
