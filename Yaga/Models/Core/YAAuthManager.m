//
//  YAAuthManager.m
//  Yaga
//
//  Created by Iegor on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAAuthManager.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NSDictionary+ResponseObject.h"
#define HOST @"https://yaga-dev.herokuapp.com"
#define API_ENDPOINT @"/api/v1"

#define RESULT @"result"
#define USER   @"user"

@interface YAAuthManager ()
@property (nonatomic, strong) NSString *base_api;
@end

@implementation YAAuthManager
+ (instancetype)sharedManager {
    static YAAuthManager *sManager = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sManager = [[self alloc] init];
    });
    return sManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _base_api = [NSString stringWithFormat:@"%@%@", HOST, API_ENDPOINT];
    }
    return self;
}

- (void)isPhoneNumberRegistered:(NSString *)phoneNumber completion:(responseBlock)completion {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSDictionary *parameters = @{ @"phone" : @"+380938542758" };

    NSString *api = [NSString stringWithFormat:@"%@/auth/info", self.base_api];
    [manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [[NSDictionary dictionaryFromResponseObject:responseObject withError:nil] objectForKey:RESULT];
        NSNumber *result = [NSNumber numberWithInt:(int)dict[USER]];
        completion(result.boolValue, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(false, error.localizedDescription);
    }];
}
@end
