//
//  YAAuthManager.m
//  Yaga
//
//  Created by Iegor on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//
#import "NSData+Hex.h"  
#import "NSString+Hash.h"
#import "YAAuthManager.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NSDictionary+ResponseObject.h"
#import "YAUser.h"
#import "YAGroupCreator.h"

#define HOST @"https://yaga-dev.herokuapp.com"
#define PORT @"443"
#define API_ENDPOINT @"/yaga/api/v1"

#define RESULT @"result"
#define USER   @"user"
#define NAME   @"name"
#define TOKEN  @"token"
#define ID     @"id"

#define USER_PHONE @"phone"

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
        _base_api = [NSString stringWithFormat:@"%@:%@%@", HOST, PORT, API_ENDPOINT];
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

- (void)getInfoForCurrentUserWithCompletion:(responseBlock)completion {
    if (!self.token) {
        completion(NO, @"Token not set!");
    }
    
    NSString *api = [NSString stringWithFormat:@"%@/user/info/", self.base_api];
    NSString *tokenString = [NSString stringWithFormat:@"Token %@", self.token];
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    
    [requestSerializer setValue:tokenString forHTTPHeaderField:@"Authorization"];
    self.manager.requestSerializer = requestSerializer;

    [self.manager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil] ;
        id name = [dict objectForKey:NAME];
        if ([name isKindOfClass:[NSNull class]]) {
            completion(NO, @"");
        } else {
            completion(YES, @"");
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
}



- (void)sendUserNameRegistration:(NSString*)name withCompletion:(responseBlock)completion
{
    if (!self.token) {
        completion(NO, @"Token not set!");
    }
    
    NSString *api = [NSString stringWithFormat:@"%@/user/profile/", self.base_api];
    
    NSDictionary *parameters = @{
                                 @"name": name
                                 };
    
    [self.manager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        completion(YES, @"");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(NO, @"Name already exists");
    }];

}

- (void)sendTokenRequestWithCompletion:(responseBlock)completion
{
    NSString *authCode = [[YAUser currentUser] authCode];
    NSDictionary *parameters = @{
                                 @"phone": self.phoneNumber,
                                 @"code" : authCode
                                 };
    
    NSString *api = [NSString stringWithFormat:@"%@/auth/token/", self.base_api];
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil] ;
        self.token = [dict objectForKey:TOKEN];
        completion(true, @"");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(false, operation.description);
    }];
}

- (void)sendGroupsRequestWithCompletion:(responseBlock)completion
{
    NSString *authCode = [[YAUser currentUser] authCode];
    NSDictionary *parameters = @{
                                 @"phone": self.phoneNumber,
                                 @"code" : authCode
                                 };
    
    NSString *api = [NSString stringWithFormat:@"%@/auth/token/", self.base_api];
    [self.manager GET:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil] ;
        self.token = [dict objectForKey:TOKEN];
        completion(true, @"");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(false, operation.description);
    }];
}

- (void)sendSMSAuthRequestForNumber:(NSString*)number withCompletion:(responseBlock)completion
{
    if (!number) return;
    
    self.phoneNumber = number;
    NSDictionary *parameters = @{ @"phone" : self.phoneNumber };
    
    NSString *api = [NSString stringWithFormat:@"%@/auth/request/", self.base_api];
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        completion(YES, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        NSInteger code = operation.response.statusCode;
        NSString *hex = [error.userInfo[@"com.alamofire.serialization.response.error.data"] hexRepresentationWithSpaces_AS:NO];

        if (code == 400){
            static int indexMessage = 0;
            NSArray *messages = @[@"Just wait!", @"Wait 5 minutes.\nGod damnit!"];
            completion(NO, [NSString stringWithFormat:@"%@\n%@", [NSString stringFromHex:hex], messages[indexMessage++ == 0 ? 0 : 1]]);
        } else {
            completion(NO, [NSString stringFromHex:hex]);
        }
    }];
}

#pragma mark - Group Creating 
- (void)sendGroupCreationWithName:(NSString*)groupName withCompletion:(responseBlock)completion
{
    if (!self.token) {
        completion(NO, @"Token not set!");
    }
    
    NSString *api = [NSString stringWithFormat:@"%@/group/", self.base_api];
    
    NSDictionary *parameters = @{
                                 @"name": groupName
                                 };
    
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
        NSNumber *groupId = [dict objectForKey:ID];
        
        [[YAGroupCreator sharedCreator] setGroupId:groupId];
        completion(YES, @"");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(NO, error.description);
    }];
    
}

- (void)addCascadingUsers:(NSArray*)users toGroup:(NSNumber*)groupId withCompletion:(responseBlock)completion
{
    NSLog(@"%@", users);
    for (NSDictionary *user in users) {
        NSString *phone = user[USER_PHONE];
        [self addUser:phone toGroup:groupId];
    }
    
    completion(YES, @"TESTING");
}

- (void)addUser:(NSString*)userPhone toGroup:(NSNumber *)groupId
{
    if (!self.token) {
        return;
    }
    
    NSString *api = [NSString stringWithFormat:@"%@/group/%@/add/", self.base_api, groupId];
    
    NSDictionary *parameters = @{
                                 @"phone": userPhone
                                 };
    
    [self.manager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];

}

- (void)sendGroupRenamingWithName:(NSString*)newName forGroupId:(NSNumber*)groupId withCompletion:(responseBlock)completion
{
    if (!self.token) {
        return;
    }
    
    NSString *api = [NSString stringWithFormat:@"%@/group/%@/", self.base_api, groupId];
    
    NSDictionary *parameters = @{
                                 @"name": newName
                                 };
    
    [self.manager PATCH:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        completion(YES, @"");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        completion(NO, @"");
    }];
}
@end
