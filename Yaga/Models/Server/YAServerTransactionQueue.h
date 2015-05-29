//
//  YAServerTransactionQueue.h
//  Yaga
//
//  Created by valentinkovalski on 12/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAGroup.h"
#import "YARealmObjectUnavailableError.h"

@interface YAServerTransactionQueue : NSObject

+ (instancetype)sharedQueue;

//- (void)addCreateTransactionForGroup:(YAGroup*)group;
//- (void)addRenameTransactionForGroup:(YAGroup*)group;

//- (void)addAddMembersTransactionForGroup:(YAGroup*)group phones:(NSArray*)phones usernames:(NSArray*)usernames;
//- (void)addRemoveMemberTransactionForGroup:(YAGroup*)group memberPhoneToRemove:(NSString*)memberPhone;

//- (void)addLeaveGroupTransactionForGroupId:(NSString*)groupId;
//- (void)addMuteUnmuteTransactionForGroup:(YAGroup*)group;
//- (void)addDeleteVideoTransaction:(NSString*)videoId forGroupId:(NSString*)groupId;

- (void)addUploadVideoTransaction:(YAVideo*)video toGroup:(YAGroup*)group;

- (void)addUpdateVideoCaptionTransaction:(YAVideo*)video;

//will pause automatically when no internet connection
- (void)processPendingTransactions;

//Debug
- (void)clearTransactionQueue;

//pending transactions
- (BOOL)hasPendingAddTransactionForContact:(YAContact*)contact;
- (BOOL)hasPendingAddTransactionForGroup:(YAGroup*)group;
- (BOOL)hasPendingUploadTransactionForVideo:(YAVideo *)video;

- (void)waitForAllTransactionsToFinish;
@end
