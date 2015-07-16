//
//  YAShareServer.m
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>

#import "YAShareServer.h"
#import "Constants.h"

@interface YAShareServer ()

@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSString *base_api;

@property (nonatomic, strong) AFHTTPRequestOperationManager *jsonOperationsManager;

@end

@implementation YAShareServer

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _base_api = [NSString stringWithFormat:@"%@:%@%@", HOST, PORT, API_ENDPOINT];
        _jsonOperationsManager = [AFHTTPRequestOperationManager manager];
        _jsonOperationsManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        _authToken = [[NSUserDefaults standardUserDefaults] objectForKey:YA_RESPONSE_TOKEN];
        
        if(self.authToken.length) {
            NSString *tokenString = [NSString stringWithFormat:@"Token %@", self.authToken];
            AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
            [requestSerializer setValue:tokenString forHTTPHeaderField:@"Authorization"];
            self.jsonOperationsManager.requestSerializer = requestSerializer;
        }
    }
    
    return self;
}

@end
