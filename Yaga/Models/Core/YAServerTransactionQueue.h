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
- (void)addUpdateMembersTransactionForGroup:(YAGroup*)group membersToDelete:(NSSet*)deleteSet membersToAdd:(NSSet*)addSet;
- (void)addLeaveGroupTransactionForGrouo:(YAGroup*)group;
@end
