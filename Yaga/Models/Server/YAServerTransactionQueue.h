//
//  YAServerTransactionQueue.h
//  Yaga
//
//  Created by valentinkovalski on 12/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAGroup.h"
#import "YARealmObjectUnavailable.h"

@interface YAServerTransactionQueue : NSObject

+ (instancetype)sharedQueue;

- (void)addCreateTransactionForGroup:(YAGroup*)group;
- (void)addRenameTransactionForGroup:(YAGroup*)group;
- (void)addAddMembersTransactionForGroup:(YAGroup*)group phones:(NSArray*)phones usernames:(NSArray*)usernames;
- (void)addRemoveMemberTransactionForGroup:(YAGroup*)group memberPhoneToRemove:(NSString*)memberPhone;
- (void)addLeaveGroupTransactionForGroupId:(NSString*)groupId;
- (void)addMuteUnmuteTransactionForGroup:(YAGroup*)group;
- (void)addUploadVideoTransaction:(YAVideo*)video;
- (void)addDeleteVideoTransaction:(NSString*)videoId forGroupId:(NSString*)groupId;
- (void)addUpdateVideoCaptionTransaction:(YAVideo*)video;

//will pause automatically when no internet connection
- (void)processPendingTransactions;

//Debug
- (void)clearTransactionQueue;

- (BOOL)hasPendingAddTransactionForContact:(YAContact*)contact;
- (BOOL)hasPendingAddTransactionForGroup:(YAGroup*)group;

- (void)waitForAllTransactionsToFinish;
@end
