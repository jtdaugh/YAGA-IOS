//
//  YAServerTransactionQueue.h
//  Yaga
//
//  Created by valentinkovalski on 12/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAGroup.h"

@interface YAServerTransactionQueue : NSObject

+ (instancetype)sharedQueue;

- (void)addCreateTransactionForGroup:(YAGroup*)group;
- (void)addRenameTransactionForGroup:(YAGroup*)group;
- (void)addAddMembersTransactionForGroup:(YAGroup*)group memberPhonesToAdd:(NSArray*)phones;
- (void)addRemoveMemberTransactionForGroup:(YAGroup*)group memberPhoneToRemove:(NSString*)memberPhone;
- (void)addLeaveGroupTransactionForGroupId:(NSString*)groupId;
- (void)addMuteUnmuteTransactionForGroup:(YAGroup*)group;

//will pause automatically when no internet connection
- (void)processPendingTransactions;
@end
