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
#import "YAUser.h"
#define HOST @"https://yaga-dev.herokuapp.com"
#define API_ENDPOINT @"/api/v1"

#define RESULT @"result"
#define USER   @"user"
#define TOKEN  @"token"

@interface YAAuthManager ()
@property (nonatomic, strong) NSString *base_api;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) NSString *token;
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
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    return self;
}

- (void)setToken:(NSString *)token
{
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:TOKEN];
}

- (NSString*)token {
    return [[NSUserDefaults standardUserDefaults] objectForKey:TOKEN];
}

- (void)logout {
    
}

- (void)sendAboutRequestWithCompletion:(responseBlock)completion
{
    if (!self.token) return;
    
    NSDictionary *params = @{ @"Auth" : self.token };
    
    NSString *api = [NSString stringWithFormat:@"%@/auth/about", self.base_api];
    [self.manager GET:api parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)loginWithCompletion:(responseBlock)completion {
    NSString *authCode = [[YAUser currentUser] authCode];
    NSDictionary *parameters = @{@"phone": self.phoneNumber,
                                 @"code" : authCode,
                                 @"name" : @"Vasilij" };
    
    NSString *api = [NSString stringWithFormat:@"%@/auth/login", self.base_api];
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [[NSDictionary dictionaryFromResponseObject:responseObject withError:nil] objectForKey:RESULT];
        self.token = [dict objectForKey:TOKEN];
        completion(true, @"");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(false, operation.description);
    }];
}

- (void)registerWithCompletion:(responseBlock)completion {
    NSString *authCode = [[YAUser currentUser] authCode];
    NSDictionary *parameters = @{@"phone": self.phoneNumber,
                                 @"code" : authCode,
                                 @"name" : @"Vasilij" };
    
    NSString *api = [NSString stringWithFormat:@"%@/auth/register", self.base_api];
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [[NSDictionary dictionaryFromResponseObject:responseObject withError:nil] objectForKey:RESULT];
        self.token = [dict objectForKey:TOKEN];
        completion(true, @"");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(false, operation.description);
    }];
}

- (void)isPhoneNumberRegistered:(NSString *)aPhoneNumber completion:(responseBlock)completion {
    
    self.phoneNumber = aPhoneNumber;
    
    NSDictionary *parameters = @{ @"phone" : self.phoneNumber };

    NSString *api = [NSString stringWithFormat:@"%@/auth/info", self.base_api];
    [self.manager GET:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [[NSDictionary dictionaryFromResponseObject:responseObject withError:nil] objectForKey:RESULT];
        NSNumber *result = [dict objectForKey:USER];
        completion([result boolValue], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(false, error.localizedDescription);
    }];
}

- (void)sendSMSAuthRequestWithCompletion:(responseBlock)completion
{
    if (!self.phoneNumber) return;
    
    NSDictionary *parameters = @{ @"phone" : self.phoneNumber };
    
    NSString *api = [NSString stringWithFormat:@"%@/auth/request", self.base_api];
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [[NSDictionary dictionaryFromResponseObject:responseObject withError:nil] objectForKey:RESULT];
        NSNumber *result = [dict objectForKey:USER];
        completion([result boolValue], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(false, error.localizedDescription);
    }];
}
@end
