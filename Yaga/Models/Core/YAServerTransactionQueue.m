//
//  YAServerTransactionQueue.m
//  Yaga
//
//  Created by valentinkovalski on 12/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAServerTransactionQueue.h"
#import "YAServer.h"
#import "YAServerTransaction.h"

@interface YAServerTransactionQueue ()
@property (nonatomic, strong) NSMutableArray *transactionsData;
@end

#define YA_TRANSACTIONS_FILENAME    @"pending_transactions.plist"

@implementation YAServerTransactionQueue

+ (instancetype)sharedQueue {
    static YAServerTransactionQueue *sManager = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sManager = [[self alloc] init];
    });
    return sManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.transactionsData = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filepath]];
    }
    return self;
}

- (void)addCreateTransactionForGroup:(YAGroup*)group {
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_CREATE_GROUP, YA_GROUP_ID:group.localId}];
    [self saveTransactions];
}

- (void)addRenameTransactionForGroup:(YAGroup*)group {
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_RENAME_GROUP, YA_GROUP_ID:group.localId, YA_GROUP_NEW_NAME:group.name}];
    [self saveTransactions];
}

- (void)addUpdateMembersTransactionForGroup:(YAGroup*)group membersToDelete:(NSSet*)deleteSet membersToAdd:(NSSet*)addSet {
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_GROUP_UPDATE_MEMBERS, YA_GROUP_ID:group.localId, YA_GROUP_DELETE_MEMBERS:deleteSet, YA_GROUP_ADD_MEMBERS:addSet}];
    [self saveTransactions];
}

- (void)addLeaveGroupTransactionForGrouo:(YAGroup*)group {
    //put 'leave' transactions at the beginning of the queue
    [self.transactionsData insertObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_LEAVE, YA_GROUP_ID:group.localId} atIndex:0];
    
    //and remove all the other transactions for that group
    for(NSDictionary *transactionData in [self.transactionsData copy]) {
        if([transactionData[YA_GROUP_ID] isEqualToString:group.localId])
            [self.transactionsData removeObject:transactionData];
    }
    
    [self saveTransactions];
}

- (NSString*)filepath {
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:YA_TRANSACTIONS_FILENAME];
    
    return path;
}

- (void)resume {
    self.transactionsData = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filepath]];
    
    if(self.transactionsData.count)
        [self processNextTransaction];
}

- (void)saveTransactions {
    [NSKeyedArchiver archiveRootObject:self.transactionsData toFile:[self filepath]];
}

- (void)processNextTransaction {
    if(!self.transactionsData.count)
        return;
    
    NSDictionary *transactionData = self.transactionsData[0];
    
    YAServerTransaction *transaction = [[YAServerTransaction alloc] initWithDictionary:transactionData];
    
    __weak typeof(self) weakSelf = self;
    [transaction performWithCompletion:^(id response, NSError *error) {
        if(error) {
            #warning TODO: think of what we can do here...
            NSLog(@"Error: %@", error);
        }
        else {
            [weakSelf.transactionsData removeObject:transactionData];
            [weakSelf processNextTransaction];
        }
    }];
}

@end
