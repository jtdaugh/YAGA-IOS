//
//  YAAuthManager.m
//  Yaga
//
//  Created by Iegor on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//
#import "NSData+Hex.h"
#import "NSString+Hash.h"
#import "YAServer.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NSDictionary+ResponseObject.h"
#import "YAUser.h"
#import "YAUtils.h"
#import "YAServerTransactionQueue.h"

#define HOST @"https://yaga-dev.herokuapp.com"
#define PORT @"443"
#define API_ENDPOINT @"/yaga/api/v1"

#define API_USER_PROFILE_TEMPLATE           @"%@/user/profile/"
#define API_AUTH_TOKEN_TEMPLATE             @"%@/auth/token/"
#define API_AUTH_BY_SMS_TEMPLATE            @"%@/auth/request/"

#define API_GROUPS_TEMPLATE                 @"%@/groups/"
#define API_RENAME_GROUP_TEMPLATE           @"%@/groups/%@/"
#define API_MUTE_GROUP_TEMPLATE             @"%@/groups/%@/mute/"

#define API_ADD_GROUP_MEMBERS_TEMPLATE      @"%@/groups/%@/add_member/"
#define API_REMOVE_GROUP_MEMBER_TEMPLATE    @"%@/groups/%@/remove_member/"

#define API_GROUP_POST_TEMPLATE             @"%@/groups/%@/add_post/"


#define USER_PHONE @"phone"
#define ERROR_DATA @"com.alamofire.serialization.response.error.data"

@interface YAServer ()
@property (nonatomic, strong) NSString *base_api;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) NSString *token;
@end

@implementation YAServer
@synthesize token = _token;

+ (instancetype)sharedServer {
    static YAServer *sManager = nil;
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
    NSString *tokenString = [NSString stringWithFormat:@"Token %@", self.token];
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    
    [requestSerializer setValue:tokenString forHTTPHeaderField:@"Authorization"];
    
    self.manager.requestSerializer = requestSerializer;
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:YA_RESPONSE_TOKEN];
}

- (NSString*)token {
    NSString *newToken = [[NSUserDefaults standardUserDefaults] objectForKey:YA_RESPONSE_TOKEN];
    if (![_token isEqualToString:newToken]) {
        _token = newToken;
        NSString *tokenString = [NSString stringWithFormat:@"Token %@", _token];
        
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        
        [requestSerializer setValue:tokenString forHTTPHeaderField:@"Authorization"];
        self.manager.requestSerializer = requestSerializer;
    }
    return _token;
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:phoneNumber forKey:USER_PHONE];
}

- (NSString*)phoneNumber
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_PHONE];
}

- (void)getInfoForCurrentUserWithCompletion:(responseBlock)completion {
    NSAssert(self.token, @"token not set");
    
    NSString *api = [NSString stringWithFormat:API_USER_PROFILE_TEMPLATE, self.base_api];
    
    [self.manager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil] ;
        id name = [dict objectForKey:YA_RESPONSE_NAME];
        
        if ([name isKindOfClass:[NSNull class]]) {
            completion(nil, nil);
        } else {
            completion(name, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)registerUsername:(NSString*)name withCompletion:(responseBlock)completion
{
    NSAssert(self.token, @"token not set");
    
    NSString *api = [NSString stringWithFormat:API_USER_PROFILE_TEMPLATE, self.base_api];
    
    NSDictionary *parameters = @{
                                 @"name": name
                                 };
    
    [self.manager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
    
}

- (void)requestAuthTokenWithCompletion:(responseBlock)completion
{
    NSString *authCode = [[YAUser currentUser] authCode];
    NSDictionary *parameters = @{
                                 @"phone": self.phoneNumber,
                                 @"code" : authCode
                                 };
    
    NSString *api = [NSString stringWithFormat:API_AUTH_TOKEN_TEMPLATE, self.base_api];
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil] ;
        self.token = [dict objectForKey:YA_RESPONSE_TOKEN];
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self printErrorData:error];
        completion(nil, error);
    }];
}

- (void)authentificatePhoneNumberBySMS:(NSString*)number withCompletion:(responseBlock)completion
{
    NSAssert(number, @"token not set");
    
    self.phoneNumber = number;
    NSDictionary *parameters = @{ @"phone" : self.phoneNumber };
    
    NSString *api = [NSString stringWithFormat:API_AUTH_BY_SMS_TEMPLATE, self.base_api];
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSInteger code = operation.response.statusCode;
        NSString *hex = [error.userInfo[ERROR_DATA] hexRepresentationWithSpaces_AS:NO];
        
        if (code == 400){
            completion([NSString stringWithFormat:@"%@\n%@", [NSString stringFromHex:hex], @"Wait for 5 minutes."], error);
        } else {
            completion(nil, error);
        }
    }];
}

#pragma mark - Groups
- (void)createGroupWithName:(NSString*)groupName withCompletion:(responseBlock)completion
{
    NSAssert(self.token, @"token not set");
    
    NSString *api = [NSString stringWithFormat:API_GROUPS_TEMPLATE, self.base_api];
    
    NSDictionary *parameters = @{
                                 @"name": groupName
                                 };
    
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
        
        completion(dict, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)addGroupMembersByPhones:(NSArray*)phones toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.token, @"token not set");
    NSAssert(serverGroupId, @"group not synchronized with server yet");
    
    NSDictionary *parameters = @{
                                 @"phones": phones
                                 };
    
    id json = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *api = [NSString stringWithFormat:API_ADD_GROUP_MEMBERS_TEMPLATE, self.base_api, serverGroupId];
    
    NSURL *url = [NSURL URLWithString:api];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"PUT"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"Token %@", self.token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:json];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               //                               NSString *str = [data hexRepresentationWithSpaces_AS:NO];
                               //                               NSLog(@"%@", [NSString stringFromHex:str]);
                               completion(nil, connectionError);
                           }];
}

- (void)removeGroupMemberByPhone:(NSString*)phone fromGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.token, @"token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSDictionary *parameters = @{
                                 @"phone": phone
                                 };
    
    id json = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *api = [NSString stringWithFormat:API_REMOVE_GROUP_MEMBER_TEMPLATE, self.base_api, serverGroupId];
    
    NSURL *url = [NSURL URLWithString:api];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"PUT"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"Token %@", self.token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:json];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               //                               NSString *str = [data hexRepresentationWithSpaces_AS:NO];
                               //                               NSLog(@"%@", [NSString stringFromHex:str]);
                               completion(nil, connectionError);
                           }];
}


- (void)renameGroupWithId:(NSString*)serverGroupId newName:(NSString*)newName withCompletion:(responseBlock)completion {
    NSAssert(self.token, @"token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_RENAME_GROUP_TEMPLATE, self.base_api, serverGroupId];
    
    NSDictionary *parameters = @{
                                 @"name": newName
                                 };
    
    [self.manager PATCH:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)muteGroupWithId:(NSString*)serverGroupId mute:(BOOL)mute withCompletion:(responseBlock)completion  {
    NSAssert(self.token, @"token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_MUTE_GROUP_TEMPLATE, self.base_api, serverGroupId];
    
    NSDictionary *parameters = @{
                                 @"mute": [NSNumber numberWithBool:mute]
                                 };
    
    [self.manager PATCH:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)getGroupsWithCompletion:(responseBlock)completion
{
    NSAssert(self.token, @"token not set");
    
    NSString *api = [NSString stringWithFormat:API_GROUPS_TEMPLATE, self.base_api];
    
    [self.manager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

#pragma mark - Posts
- (void)uploadPost:(YAVideo*)post toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.token, @"token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");

    NSData *video = [[NSFileManager defaultManager] contentsAtPath:[YAUtils urlFromFileName:post.movFilename].path];
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_TEMPLATE, self.base_api, serverGroupId];
    
    [self.manager POST:api
            parameters:nil
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   NSDictionary *d = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
                   NSDictionary *dict = d[@"meta"];
                   NSString *endpoint = dict[@"endpoint"];
                   [self multipartUpload:endpoint withParameters:dict[@"fields"] withFile:video];
               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   NSLog(@"%@", error);
               }];
}

- (void)multipartUpload:(NSString*)endpoint withParameters:(NSDictionary*)dict withFile:(NSData*)file
{
    AFHTTPRequestOperationManager *newManager = [AFHTTPRequestOperationManager manager];
    AFXMLParserResponseSerializer *responseSerializer = [AFXMLParserResponseSerializer serializer];
    newManager.responseSerializer = responseSerializer;
    [newManager POST:endpoint
          parameters:dict
constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    [formData appendPartWithFormData:file name:@"file"];
    
} success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSLog(@"%@", operation);
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    [self printErrorData:error];
    
}];
}

#pragma mark - Utitlities
- (void)printErrorData:(NSError*)error
{
    NSString *hex = [error.userInfo[ERROR_DATA] hexRepresentationWithSpaces_AS:NO];
    NSLog(@"%@", [NSString stringFromHex:hex]);
}

#pragma mark - Synchronization
- (void)synchronizeLocalAndRemoteChanges {
    //monitor internet connection
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if([[YAUser currentUser] loggedIn] && [[AFNetworkReachabilityManager sharedManager] isReachable]) {
            
            //read updates from server
            [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
                if(!error) {
                    NSLog(@"groups updated from server successfully");
                    
                    //send local changes to the server
                    [[YAServerTransactionQueue sharedQueue] processPendingTransactions];
                }
                else {
                    NSLog(@"unable to read groups from server");
                }
            }];
            
        }
    }];
}

@end
