//
//  YAServerTransactionQueue.m
//  Yaga
//
//  Created by valentinkovalski on 12/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAServerTransactionQueue.h"
#import "YAServer.h"

@implementation YAServerTransactionQueue

+ (instancetype)sharedServer {
    static YAServerTransactionQueue *sManager = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sManager = [[self alloc] init];
    });
    return sManager;
}

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)addRenameTransactionForGroup:(YAGroup*)group {
    
}

- (void)addMembersAddTransactionForGroup:(YAGroup*)group {
    
}

- (void)addMembersTransactionForGroup:(YAGroup*)group {
    
}
- (void)removeMemberTransactionForGroup:(YAGroup*)group {
    
}


- (void)synchronize {
    
}

@end
