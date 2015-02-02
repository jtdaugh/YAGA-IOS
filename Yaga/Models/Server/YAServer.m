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
#define API_USER_DEVICE_TEMPLATE            @"%@/user/device/"

#define API_USER_SEARCH_TEMPLATE            @"%@/user/search/"

#define API_AUTH_TOKEN_TEMPLATE             @"%@/auth/obtain/"
#define API_AUTH_BY_SMS_TEMPLATE            @"%@/auth/request/"

#define API_GROUPS_TEMPLATE                 @"%@/groups/"
#define API_GROUP_TEMPLATE                  @"%@/groups/%@/"
#define API_MUTE_GROUP_TEMPLATE             @"%@/groups/%@/members/mute/"

#define API_ADD_GROUP_MEMBERS_TEMPLATE      @"%@/groups/%@/members/add/"
#define API_REMOVE_GROUP_MEMBER_TEMPLATE    @"%@/groups/%@/members/remove/"

#define API_GROUP_POSTS_TEMPLATE            @"%@/groups/%@/posts/"
#define API_GROUP_POST_TEMPLATE             @"%@/groups/%@/posts/%@/"

#define API_GROUP_POST_LIKE                 @"%@/groups/%@/posts/%@/like/"
#define API_GROUP_POST_LIKERS               @"%@/groups/%@/posts/%@/likers/"

#define USER_PHONE  @"phone"
#define ERROR_DATA  @"com.alamofire.serialization.response.error.data"

@interface YAServer ()

@property (nonatomic, strong) NSString *base_api;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (atomic, strong) AFNetworkReachabilityManager *reachability;
@property (atomic, readonly) NSString *authToken;
@end

@implementation YAServer

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
    
        [self applySavedAuthToken];
    }
    
    return self;
}

- (void)applySavedAuthToken {

    _authToken = [[NSUserDefaults standardUserDefaults] objectForKey:YA_RESPONSE_TOKEN];
    
    if(self.authToken.length) {
        NSString *tokenString = [NSString stringWithFormat:@"Token %@", self.authToken];
        AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
        [requestSerializer setValue:tokenString forHTTPHeaderField:@"Authorization"];
        self.manager.requestSerializer = requestSerializer;
    }
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
    NSAssert(self.authToken.length, @"auth token not set");
    
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
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *api = [NSString stringWithFormat:API_USER_PROFILE_TEMPLATE, self.base_api];
    
    NSDictionary *parameters = @{
                                 @"name": name
                                 };
    
    [self.manager PUT:api
           parameters:parameters
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *hex = [error.userInfo[ERROR_DATA] hexRepresentationWithSpaces_AS:NO];
        completion([NSString stringFromHex:hex], error);
    }];
    
}

- (void)requestAuthTokenWithAuthCode:(NSString*)authCode withCompletion:(responseBlock)completion {
    NSDictionary *parameters = @{
                                 @"phone": self.phoneNumber,
                                 @"code" : authCode
                                 };
    
    NSString *api = [NSString stringWithFormat:API_AUTH_TOKEN_TEMPLATE, self.base_api];
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil] ;
        NSString *token = [dict objectForKey:YA_RESPONSE_TOKEN];
        
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:YA_RESPONSE_TOKEN];
        [self applySavedAuthToken];
        
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)authentificatePhoneNumberBySMS:(NSString*)number withCompletion:(responseBlock)completion
{
    NSAssert(number, @"number isn't specified");
    
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
            completion(NSLocalizedString(@"Application error", nil), error);
        }
    }];
}

#pragma mark - Groups
- (void)createGroupWithName:(NSString*)groupName withCompletion:(responseBlock)completion
{
    NSAssert(self.authToken.length, @"auth token not set");
    
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

- (void)addGroupMembersByPhones:(NSArray*)phones andUsernames:(NSArray*)usernames toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"group not synchronized with server yet");
    
    NSDictionary *parameters = @{
                                 @"phones": phones,
                                 @"names": usernames
                                 };
    
    id json = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *api = [NSString stringWithFormat:API_ADD_GROUP_MEMBERS_TEMPLATE, self.base_api, serverGroupId];
    
    NSURL *url = [NSURL URLWithString:api];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"PUT"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"Token %@", self.authToken] forHTTPHeaderField:@"Authorization"];
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
    NSAssert(self.authToken.length, @"auth token not set");
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
    
    [request setValue:[NSString stringWithFormat:@"Token %@", self.authToken] forHTTPHeaderField:@"Authorization"];
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
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_GROUP_TEMPLATE, self.base_api, serverGroupId];
    
    NSDictionary *parameters = @{
                                 @"name": newName
                                 };
    
    [self.manager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)groupInfoWithId:(NSString*)serverGroupId since:(NSDate*)since withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_GROUP_TEMPLATE, self.base_api, serverGroupId];
    
    if(since) {
        NSString *sinceString = [NSString stringWithFormat:@"?since=%lu", (unsigned long)[since timeIntervalSince1970]];
        api = [api stringByAppendingString:sinceString];
    }
    
    [self.manager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
        completion(dict, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)muteGroupWithId:(NSString*)serverGroupId mute:(BOOL)mute withCompletion:(responseBlock)completion  {
    NSAssert(self.authToken.length, @"auth token not set");
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
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *api = [NSString stringWithFormat:API_GROUPS_TEMPLATE, self.base_api];
    
    [self.manager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

#pragma mark - Posts
- (void)uploadVideo:(YAVideo*)video toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_GROUP_POSTS_TEMPLATE, self.base_api, serverGroupId];
    NSString *videoLocalId = [video.localId copy];
    [self.manager POST:api
            parameters:nil
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if ([video isInvalidated]) {
                       YARealmObjectUnavailable *yaError = [YARealmObjectUnavailable new];
                       completion(videoLocalId, yaError);
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
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSAssert(serverVideoId, @"videoId is a required parameter");
    NSAssert(serverGroupId, @"groupId is a required parameter");
    
    if (!serverVideoId || !serverVideoId)
        return completion(nil, nil);
    
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_TEMPLATE, self.base_api, serverGroupId, serverVideoId];
    
    [self.manager DELETE:api
              parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  completion(responseObject, nil);
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  completion(nil, error);
              }];
}

- (void)uploadVideoCaptionWithId:(NSString*)serverVideoId withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSAssert(serverVideoId, @"videoId is a required parameter");
    
    RLMResults *videos = [YAVideo objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", serverVideoId]];
    if(videos.count != 1) {
        completion(nil, [NSError errorWithDomain:@"Can't upload new video caption, video doesn't exist anymore" code:0 userInfo:nil]);
        return;
    }
    YAVideo *video = [videos firstObject];
    
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_TEMPLATE, self.base_api, video.group.serverId, serverVideoId];


    NSDictionary *parameters = @{
                                 @"name": video.caption
                                 };
    id json = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSURL *url = [NSURL URLWithString:api];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"PUT"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"Token %@", self.authToken] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:json];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                                              NSString *str = [data hexRepresentationWithSpaces_AS:NO];
                                                              NSLog(@"%@", [NSString stringFromHex:str]);
                               completion(nil, connectionError);
                           }];
}

- (void)likeVideo:(YAVideo*)video withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *serverGroupId = [YAUser currentUser].currentGroup.serverId;
    NSString *serverVideoId = video.serverId;
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_LIKE, self.base_api, serverGroupId, serverVideoId];
    [self.manager POST:api
            parameters:nil
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   NSDictionary *responseDict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
                   NSArray *likers = responseDict[YA_RESPONSE_LIKERS];

                   
                   dispatch_async(dispatch_get_main_queue(), ^{
                       [video.realm beginWriteTransaction];
                       [video updateLikersWithArray:likers];
                       [video.realm commitWriteTransaction];
                   });
                   
                   completion([NSNumber numberWithUnsignedInteger:[likers count]], nil);
               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   NSString *hex = [error.userInfo[ERROR_DATA] hexRepresentationWithSpaces_AS:NO];
                   NSLog(@"%@", [NSString stringFromHex:hex]);
                   completion(nil, nil);
               }];
}

- (void)unLikeVideo:(YAVideo*)video withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *serverGroupId = [YAUser currentUser].currentGroup.serverId;
    NSString *serverVideoId = video.serverId;
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_LIKE, self.base_api, serverGroupId, serverVideoId];
    [self.manager   DELETE:api
                parameters:nil
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NSDictionary *responseDict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
                       NSArray *likers = responseDict[YA_RESPONSE_LIKERS];
                       
                       if ([likers count]) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [video.realm beginWriteTransaction];
                               [video updateLikersWithArray:likers];
                               [video.realm commitWriteTransaction];
                           });
                       }
                       
                       completion([NSNumber numberWithUnsignedInteger:[likers count]], nil);
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       completion(nil, nil);
                   }];
}

#pragma mark - Device token

- (void)registerDeviceTokenWithCompletion:(responseBlock)completion {
    NSAssert(self.authToken, @"token not set");
    NSAssert([YAUser currentUser].deviceToken.length, @"device token not set");
    
    NSString *api = [NSString stringWithFormat:API_USER_DEVICE_TEMPLATE, self.base_api];
    
    NSDictionary *parameters = @{
                                 @"vendor": @"IOS",
                                 @"token": [YAUser currentUser].deviceToken,
                                 @"locale": [[NSLocale preferredLanguages] objectAtIndex:0]
                                 };
    
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:YA_LAST_DEVICE_TOKEN_SYNC_DATE];
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
            
            __weak typeof(self) weakSelf = self;
            [self.reachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf sync];
                });
            }];
        });
    }  
    else {
        [self.reachability stopMonitoring];
        self.reachability = nil;
    }
}

- (BOOL)serverUp {
    @synchronized(self) {
        return [self.reachability isReachable];
    }
}

- (void)registerDeviceTokenIfNeeded {
    if(![YAUser currentUser].deviceToken.length)
        return;
    //every day? maybe every month?
    NSTimeInterval lastRegistrationDate = [[[NSUserDefaults standardUserDefaults] objectForKey:YA_LAST_DEVICE_TOKEN_SYNC_DATE] timeIntervalSinceNow];
    if(!lastRegistrationDate || fabs(lastRegistrationDate) > 24 * 60 * 60) {
        [self registerDeviceTokenWithCompletion:^(id response, NSError *error) {
            if(error) {
                [YAUtils showNotification:[NSString stringWithFormat:@"Can't register device token. %@", error.localizedDescription] type:AZNotificationTypeError];
            }
        }];
    }
}
- (void)sync {
    NSLog(@"YAServer:sync, serverUp: %@", self.serverUp ? @"Yes" : @"No");
    
    if([[YAUser currentUser] loggedIn] && self.authToken.length && self.serverUp) {
        
        [self registerDeviceTokenIfNeeded];
        
        //read updates from server
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
            if(!error) {
                self.lastUpdateTime = [NSDate date];
                NSLog(@"groups updated from server successfully");
                
                [[YAUser currentUser].currentGroup updateVideosWithCompletion:^(NSError *error, NSArray *newVideos) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEOS_ADDED_NOTIFICATION object:newVideos];
                    
                }];
                
                //send local changes to the server
                [[YAServerTransactionQueue sharedQueue] processPendingTransactions];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_GROUP_NOTIFICATION object:[YAUser currentUser].currentGroup];
            }
            else {
                NSLog(@"unable to read groups from server");
            }
        }];
        
    }
    
    [[YAUser currentUser] purgeOldVideos];
}

- (void)getYagaUsersFromPhonesArray:(NSArray*)phones withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"token not set");
    
    NSMutableArray *correctPhones = [NSMutableArray arrayWithArray:[[NSSet setWithArray:phones] allObjects]];
    for(NSString *phone in [correctPhones copy]) {
        if(![YAUtils validatePhoneNumber:phone error:nil]) {
            [correctPhones removeObject:phone];
        }
    }
    
    NSString *api = [NSString stringWithFormat:API_USER_SEARCH_TEMPLATE, self.base_api];
    
    NSDictionary *parameters = @{
                                 @"phones": correctPhones
                                 };
    
    [self.manager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];

}

@end
