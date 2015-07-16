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

static YAShareServer *_sharedServer = nil;

@implementation YAShareServer

#pragma mark - Singleton

+ (YAShareServer *)sharedServer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedServer = [[YAShareServer alloc] init];
    });
    
    return _sharedServer;
}

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _base_api = [NSString stringWithFormat:@"%@:%@%@", HOST, PORT, API_ENDPOINT];
        _jsonOperationsManager = [AFHTTPRequestOperationManager manager];
        _jsonOperationsManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        _authToken = [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] objectForKey:YA_RESPONSE_TOKEN];
        
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
