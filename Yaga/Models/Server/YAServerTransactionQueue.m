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
@property (atomic, strong) NSMutableArray *transactionsData;
@property (atomic, assign) BOOL transactionInProgress;
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
        self.transactionsData = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:[self filepath]]];
    }
    return self;
}

- (void)addCreateTransactionForGroup:(YAGroup*)group {
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_CREATE_GROUP, YA_GROUP_ID:group.localId}];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (void)addRenameTransactionForGroup:(YAGroup*)group {
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_RENAME_GROUP, YA_GROUP_ID:group.localId, YA_GROUP_NEW_NAME:group.name}];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (void)addAddMembersTransactionForGroup:(YAGroup*)group phones:(NSArray*)phones usernames:(NSArray*)usernames {
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_ADD_GROUP_MEMBERS, YA_GROUP_ID:group.localId, YA_GROUP_ADD_MEMBER_PHONES:phones, YA_GROUP_ADD_MEMBER_NAMES:usernames}];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (void)addRemoveMemberTransactionForGroup:(YAGroup*)group memberPhoneToRemove:(NSString*)memberPhone {
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_DELETE_GROUP_MEMBER, YA_GROUP_ID:group.localId, YA_GROUP_DELETE_MEMBER:memberPhone}];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (void)addLeaveGroupTransactionForGroupId:(NSString*)groupId {
    //put 'leave' transactions at the beginning of the queue
    //remove all the other transactions for that group first
    for(NSDictionary *transactionData in [self.transactionsData copy]) {
        if([transactionData[YA_GROUP_ID] isEqualToString:groupId])
            [self.transactionsData removeObject:transactionData];
    }
    
    //add leave transaction
    [self.transactionsData insertObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_LEAVE_GROUP, YA_GROUP_ID:groupId} atIndex:0];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (void)addMuteUnmuteTransactionForGroup:(YAGroup*)group {
    //remove all the old mute/unmute transcations for that group
    for(NSDictionary *transactionData in [self.transactionsData copy]) {
        if([transactionData[YA_GROUP_ID] isEqualToString:group.localId] &&
           [transactionData[YA_TRANSACTION_TYPE] isEqualToString:YA_TRANSACTION_TYPE_MUTE_UNMUTE_GROUP]
           ) {
            [self.transactionsData removeObject:transactionData];
        }
    }
    
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_MUTE_UNMUTE_GROUP, YA_GROUP_ID:group.localId}];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (void)addUploadVideoTransaction:(YAVideo*)video {
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_UPLOAD_VIDEO, YA_VIDEO_ID:video.localId}];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (void)addDeleteVideoTransaction:(NSString*)videoId forGroupId:(NSString*)groupId{
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_DELETE_VIDEO, YA_VIDEO_ID:videoId, YA_GROUP_ID:groupId}];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (void)addUpdateVideoCaptionTransaction:(YAVideo*)video {
    //remove all transactions for that video
    for(NSDictionary *transactionData in [self.transactionsData copy]) {
        if([transactionData[YA_VIDEO_ID] isEqualToString:video.serverId] &&
           [transactionData[YA_TRANSACTION_TYPE] isEqualToString:YA_TRANSACTION_TYPE_UPDATE_CAPTION]
           ) {
            [self.transactionsData removeObject:transactionData];
        }
    }
    
    [self.transactionsData addObject:@{YA_TRANSACTION_TYPE:YA_TRANSACTION_TYPE_UPDATE_CAPTION, YA_VIDEO_ID:video.serverId}];
    
    [self saveTransactionsData];
    [self processPendingTransactions];
}

- (NSString*)filepath {
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:YA_TRANSACTIONS_FILENAME];
    
    return path;
}

- (void)processPendingTransactions {
    self.transactionsData = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:[self filepath]]];
    
    if(self.transactionsData.count && !self.transactionInProgress)
        [self processNextTransaction];
}

- (void)clearTransactionQueue
{
    [[NSFileManager defaultManager] removeItemAtPath:[self filepath] error:nil];
}

- (void)saveTransactionsData {
    [NSKeyedArchiver archiveRootObject:self.transactionsData toFile:[self filepath]];
}

- (void)processNextTransaction {
    if(![YAServer sharedServer].serverUp) {
        DLog(@"Connection to the server is not available. All transactions will be restored when it's up again.");
        return;
    }
    
    if(!self.transactionsData.count) {
        return;
    }
    
    if (self.transactionInProgress) {
        return;
    }
    
    
    NSDictionary *transactionData = self.transactionsData[0];
    
    YAServerTransaction *transaction = [[YAServerTransaction alloc] initWithDictionary:transactionData];
    
    __weak typeof(self) weakSelf = self;
    
    DLog(@"performing transaction with data: %@", transactionData);
    
    self.transactionInProgress = YES;

    [transaction performWithCompletion:^(id response, NSError *error) {
        
        self.transactionInProgress = NO;
        if(![[YAServer sharedServer] serverUp]) {
            DLog(@"Server is down or there is no internet connection.. Pausing transaction queue till it's up again.");
            return;
        }
        if ([error isKindOfClass:[YARealmObjectUnavailable class]])
        {
            DLog(@"Transaction impossible, video invalidated");
        }
        else if(error) {
            //DLog(@"Error performing transaction %@\n Error: %@\n", transactionData, error);
        }
        else {
            DLog(@"Transaction successfull!");
        }
        
        [weakSelf.transactionsData removeObject:transactionData];
        [weakSelf saveTransactionsData];
        [weakSelf processNextTransaction];
    }];
}

- (BOOL)hasPendingAddTransactionForContact:(YAContact*)contact {
    NSArray *pendingTransactions = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filepath]];
    
    for(NSDictionary *transactionData in pendingTransactions) {
        YAServerTransaction *transaction = [[YAServerTransaction alloc] initWithDictionary:transactionData];
        
        NSString *type = transaction.data[YA_TRANSACTION_TYPE];
        
        if(![type isEqualToString:YA_TRANSACTION_TYPE_ADD_GROUP_MEMBERS])
            continue;

        NSArray *phones = transaction.data[YA_GROUP_ADD_MEMBER_PHONES];
        NSArray *usernames = transaction.data[YA_GROUP_ADD_MEMBER_NAMES];
        
        for (NSString *phone in phones) {
            if([contact.number isEqualToString:phone])
                return YES;
        }
        
        for (NSString *username in usernames) {
            if([contact.username isEqualToString:username])
                return YES;
        }

    }
    return NO;
}

- (BOOL)hasPendingAddTransactionForGroup:(YAGroup*)group {
    NSArray *pendingTransactions = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filepath]];
    
    for(NSDictionary *transactionData in pendingTransactions) {
        YAServerTransaction *transaction = [[YAServerTransaction alloc] initWithDictionary:transactionData];
        
        NSString *type = transaction.data[YA_TRANSACTION_TYPE];
        
        if(![type isEqualToString:YA_TRANSACTION_TYPE_CREATE_GROUP])
            continue;
        
        NSString *localGroupId = transaction.data[YA_GROUP_ID];
        if([localGroupId isEqualToString:group.localId])
            return YES;
        
    }
    return NO;
}

- (void)waitForAllTransactionsToFinish {
    while (self.transactionsData.count) {
        [NSThread sleepForTimeInterval:1.0];
    }
    DLog(@"waitForAllTransactionsToFinish: all done.");
    return;
}

@end
