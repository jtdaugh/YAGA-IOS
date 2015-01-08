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
#include <sys/socket.h>
#include <netinet/in.h>
#import "YAServer+HostManagment.h"
#define HOST @"https://yaga-dev.herokuapp.com"

#define YAGA_HOST_IP_ADDRESS @"23.21.52.195"

#define PORT @"443"
#define PORTNUM 443
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
#define API_GROUP_POST_DELETE               @"%@/groups/%@/posts/%@/"


#define USER_PHONE @"phone"
#define ERROR_DATA @"com.alamofire.serialization.response.error.data"

@interface YAServer ()

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *base_api;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachability;

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
       
        unsigned int hostIpAddress = [YAServer sockAddrFromHost:HOST];
        if (hostIpAddress != 0)
        {
            struct sockaddr_in address;
            bzero(&address, sizeof(address));
            address.sin_len = sizeof(address);
            address.sin_family = AF_INET;
            address.sin_addr.s_addr = htonl(hostIpAddress);
            address.sin_port = htons(PORTNUM);
            
            self.reachability = [AFNetworkReachabilityManager managerForAddress:&address];
        }
        else
        {
            self.reachability = [AFNetworkReachabilityManager managerForDomain:HOST];
        }
        [self.reachability startMonitoring];
        
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
                               
                               if([(NSHTTPURLResponse*)response statusCode] == 200)
                                   completion(nil, nil);
                               else {
                                   NSString *str = [data hexRepresentationWithSpaces_AS:NO];
                                   completion([NSString stringFromHex:str], [NSError errorWithDomain:@"YADomain" code:[(NSHTTPURLResponse*)response statusCode] userInfo:@{@"response":response}]);
                               }
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
    
    [self.manager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)groupInfoWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.token, @"token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_RENAME_GROUP_TEMPLATE, self.base_api, serverGroupId];
    
    [self.manager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
        completion(dict, nil);
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
    
    [self.manager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
- (void)uploadVideo:(YAVideo*)video toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.token, @"token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_TEMPLATE, self.base_api, serverGroupId];
    
    [self.manager POST:api
            parameters:nil
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if ([video isInvalidated]) {
                       YARealmObjectUnavailable *yaError = [YARealmObjectUnavailable new];
                       completion(nil, yaError);
                       return;
                   }
                   
                   NSLog(@"uploadVideoData, recieved params for S3 upload. Making multipart upload...");
                   
                   NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
                   
                   [video.realm beginWriteTransaction];
                   video.serverId = dict[YA_RESPONSE_ID];
                   [video.realm commitWriteTransaction];
                   
                   NSDictionary *meta = dict[@"meta"];
                   NSString *endpoint = meta[@"endpoint"];
                   
                   NSData *videoData = [[NSFileManager defaultManager] contentsAtPath:[YAUtils urlFromFileName:video.movFilename].path];
                   [self multipartUpload:endpoint withParameters:meta[@"fields"] withFile:videoData completion:completion];
                   
               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   completion(nil, error);
               }];
}

- (void)multipartUpload:(NSString*)endpoint withParameters:(NSDictionary*)dict withFile:(NSData*)file completion:(responseBlock)completion {
    AFHTTPRequestOperationManager *newManager = [AFHTTPRequestOperationManager manager];
    AFXMLParserResponseSerializer *responseSerializer = [AFXMLParserResponseSerializer serializer];
    newManager.responseSerializer = responseSerializer;
    [newManager POST:endpoint
          parameters:dict constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
              if (file == nil)
                  NSLog(@"Hello");
              [formData appendPartWithFormData:file name:@"file"];
              
          } success:^(AFHTTPRequestOperation *operation, id responseObject) {
              completion(operation.response, nil);
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              completion(nil, error);
          }];
}

- (void)deleteVideoWithId:(NSString*)serverVideoId fromGroup:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.token, @"token not set");
    NSAssert(serverVideoId, @"videoId is a required parameter");
    NSAssert(serverGroupId, @"videoId is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_DELETE, self.base_api, serverGroupId, serverVideoId];
    
    [self.manager DELETE:api
              parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  completion(responseObject, nil);
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  completion(nil, error);
              }];
}

#pragma mark - Utitlities
//- (void)printErrorData:(NSError*)error
//{
//    NSString *hex = [error.userInfo[ERROR_DATA] hexRepresentationWithSpaces_AS:NO];
//    NSLog(@"%@", [NSString stringFromHex:hex]);
//}

#pragma mark - Synchronization
- (void)startMonitoringInternetConnection:(BOOL)start {
    if(start) {
        self.reachability = [AFNetworkReachabilityManager managerForDomain:@"heroku.com"];
        [self.reachability startMonitoring];
        
        __weak typeof(self) weakSelf = self;
        [self.reachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [weakSelf sync];
        }];
    }
    else {
        [self.reachability stopMonitoring];
        self.reachability = nil;
    }
}

- (BOOL)serverUp {
    return [self.reachability isReachable];
}

- (void)sync {
    NSLog(@"YAServer:sync, serverUp: %@", self.serverUp ? @"Yes" : @"No");
    
    if([[YAUser currentUser] loggedIn] && self.token.length && self.serverUp) {
        
        //read updates from server
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
            if(!error) {
                self.lastUpdateTime = [NSDate date];
                NSLog(@"groups updated from server successfully");
                
                //send local changes to the server
                [[YAServerTransactionQueue sharedQueue] processPendingTransactions];
                
                //and update videos at the same time
                [[YAUser currentUser].currentGroup updateVideos];
            }
            else {
                NSLog(@"unable to read groups from server");
            }
        }];
        
    }
    
}

@end
