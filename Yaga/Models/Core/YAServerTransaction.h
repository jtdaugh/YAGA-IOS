//
//  YAServerTransaction.h
//  Yaga
//
//  Created by valentinkovalski on 12/31/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

#define YA_TRANSACTION_TYPE     @"type"

#define YA_TRANSACTION_TYPE_CREATE_GROUP            @"createGroup"
#define YA_TRANSACTION_TYPE_RENAME_GROUP            @"renameGroup"
#define YA_TRANSACTION_TYPE_UPDATE_GROUP_MEMBERS    @"updateGroupMembers"
#define YA_TRANSACTION_TYPE_LEAVE                   @"leaveGroup"

#define YA_GROUP_ID                 @"groupId"
#define YA_GROUP_NEW_NAME           @"newName"
#define YA_GROUP_UPDATE_MEMBERS     @"updateGroupMembers"
#define YA_GROUP_DELETE_MEMBERS     @"membersToDelete"
#define YA_GROUP_ADD_MEMBERS        @"membersToAdd"

typedef void(^responseBlock)(id response, NSError* error);

@interface YAServerTransaction : NSObject

- (id)initWithDictionary:(NSDictionary*)dic;
- (void)performWithCompletion:(responseBlock)completion;

@end
