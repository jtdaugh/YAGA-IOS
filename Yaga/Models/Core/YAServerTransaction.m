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
    else if([type isEqualToString:YA_TRANSACTION_TYPE_UPDATE_GROUP_MEMBERS]) {
        [self updateGroupMembersWithCompletion:completion];
    }
    else if([type isEqualToString:YA_TRANSACTION_TYPE_LEAVE]) {
        [self leaveGroupWithCompletion:completion];
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
    
    [[YAServer sharedServer] renameGroup:group newName:group.name withCompletion:^(id response, NSError *error) {
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

- (void)updateGroupMembersWithCompletion:(responseBlock)completion {
#warning TODO: updateGroupMembersWithCompletion
}

- (void)leaveGroupWithCompletion:(responseBlock)completion {
#warning TODO: leaveGroupWithCompletion
}


@end
