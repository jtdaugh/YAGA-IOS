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
#define YA_TRANSACTION_TYPE_ADD_GROUP_MEMBERS       @"addGroupMembers"
#define YA_TRANSACTION_TYPE_DELETE_GROUP_MEMBER     @"deleteGroupMember"
#define YA_TRANSACTION_TYPE_LEAVE_GROUP             @"leaveGroup"
#define YA_TRANSACTION_TYPE_MUTE_UNMUTE_GROUP       @"muteUnmuteGroup"

#define YA_TRANSACTION_TYPE_UPLOAD_VIDEO            @"uploadVideo"
#define YA_TRANSACTION_TYPE_DELETE_VIDEO            @"deleteVideo"
#define YA_TRANSACTION_TYPE_UPDATE_CAPTION          @"updateCaption"

#define YA_GROUP_ID                 @"groupId"
#define YA_VIDEO_ID                 @"videoId"
#define YA_GROUP_NEW_NAME           @"newName"
#define YA_GROUP_ADD_MEMBERS        @"membersToAdd"
#define YA_GROUP_DELETE_MEMBER      @"memberToDelete"


typedef void(^responseBlock)(id response, NSError* error);

@interface YAServerTransaction : NSObject

- (id)initWithDictionary:(NSDictionary*)dic;
- (void)performWithCompletion:(responseBlock)completion;

@end
