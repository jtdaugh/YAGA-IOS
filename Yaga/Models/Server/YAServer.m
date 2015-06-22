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
#import "MBProgressHUD.h"

//uncomment for debug server
#define DEBUG_SERVER 1

#if (DEBUG && DEBUG_SERVER)
#define HOST @"https://api-dev.yagaprivate.com"
#else
#define HOST @"https://api.yagaprivate.com"
#endif

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
#define API_GROUP_JOIN_TEMPLATE            @"%@/groups/%@/join/"

#define API_MUTE_GROUP_TEMPLATE             @"%@/groups/%@/mute/"

#define API_GROUPS_SEARCH_TEMPLATE          @"%@/groups/discover/"

#define API_GROUP_MEMBERS_TEMPLATE          @"%@/groups/%@/members/"

#define API_GROUP_POSTS_TEMPLATE            @"%@/groups/%@/posts/"
#define API_GROUP_POST_TEMPLATE             @"%@/groups/%@/posts/%@/"

#define API_GROUP_POST_LIKE                 @"%@/groups/%@/posts/%@/like/"
#define API_GROUP_POST_LIKERS               @"%@/groups/%@/posts/%@/likers/"

#define API_GROUP_POST_COPY                 @"%@/groups/%@/posts/%@/copy/"

#define USER_PHONE  @"phone"
#define ERROR_DATA  @"com.alamofire.serialization.response.error.data"


#define kCrosspostData @"kCrosspostData"

@interface YAServer ()

@property (nonatomic, strong) NSString *base_api;
@property (nonatomic, strong) NSString *phoneNumber;

@property (nonatomic, strong) AFHTTPRequestOperationManager *jsonOperationsManager;
@property (nonatomic, strong) AFHTTPRequestOperationManager *xmlOperationsManager;

@property (atomic, strong) AFNetworkReachabilityManager *reachability;
@property (atomic, readonly) NSString *authToken;
@property (atomic, strong) NSMutableDictionary *multipartUploadsInProgress;
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
        _jsonOperationsManager = [AFHTTPRequestOperationManager manager];
        _jsonOperationsManager.requestSerializer = [AFJSONRequestSerializer serializer];

        _xmlOperationsManager = [AFHTTPRequestOperationManager manager];
        _xmlOperationsManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
        _xmlOperationsManager.operationQueue.maxConcurrentOperationCount = 1;
        _xmlOperationsManager.requestSerializer.timeoutInterval = 60;
        
        self.multipartUploadsInProgress = [NSMutableDictionary new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willDeleteVideo:)  name:VIDEO_WILL_DELETE_NOTIFICATION  object:nil];
        
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
        self.jsonOperationsManager.requestSerializer = requestSerializer;
    }
}

- (BOOL)hasAuthToken {
    return self.authToken.length;
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
    
    [self.jsonOperationsManager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
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
    
    [self.jsonOperationsManager PUT:api
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
    [self.jsonOperationsManager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    [self.jsonOperationsManager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

#pragma mark - Groups
- (void)createGroupWithName:(NSString*)groupName withCompletion:(responseBlock)completion {
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *api = [NSString stringWithFormat:API_GROUPS_TEMPLATE, self.base_api];
    
    NSDictionary *parameters = @{
                                 @"name": groupName
                                 };
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Creating group", @"")];
    [self.jsonOperationsManager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
        [hud hide:NO];
        completion(dict, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [hud hide:NO];
        [YAUtils showHudWithText:NSLocalizedString(@"Can not create group", @"")];
        completion(nil, error);
    }];
}

- (void)addGroupMembersByPhones:(NSArray*)phones andUsernames:(NSArray*)usernames toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"group not synchronized with server yet");
    
    NSMutableDictionary *parameters = @{
                                        @"phones": phones,
                                        @"names": usernames
                                        }.mutableCopy;
    
    if (![usernames count]) { [parameters removeObjectForKey:@"names"]; };
    
    id json = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *api = [NSString stringWithFormat:API_GROUP_MEMBERS_TEMPLATE, self.base_api, serverGroupId];
    
    NSURL *url = [NSURL URLWithString:api];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"PUT"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"Token %@", self.authToken] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:json];
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Adding members", @"")];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               [hud hide:NO];
                               
                               if([(NSHTTPURLResponse*)response statusCode] == 200) {
                                   [YAUtils showHudWithText:NSLocalizedString(@"Members added", @"")];
                                   completion(nil, nil);
                               }
                               else {
                                   [YAUtils showHudWithText:NSLocalizedString(@"Can not add members", @"")];
                                   NSString *str = [data hexRepresentationWithSpaces_AS:NO];
                                   
                                   if(response)
                                       completion([NSString stringFromHex:str], [NSError errorWithDomain:@"YADomain" code:[(NSHTTPURLResponse*)response statusCode] userInfo:@{@"response":response}]);
                                   else
                                       completion(nil, [NSError errorWithDomain:@"YADomain" code:0 userInfo:nil]);
                               }
                           }];
}

- (void)removeGroupMemberByPhone:(NSString*)phone fromGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSDictionary *parameters = @{
                                 @"phone": phone
                                 };
    
    id json = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *api = [NSString stringWithFormat:API_GROUP_MEMBERS_TEMPLATE, self.base_api, serverGroupId];
    
    NSURL *url = [NSURL URLWithString:api];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"DELETE"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"Token %@", self.authToken] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:json];
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Removing members", @"")];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               [hud hide:NO];
                               
                               if([(NSHTTPURLResponse*)response statusCode] == 200) {
                                   [YAUtils showHudWithText:NSLocalizedString(@"Member removed", @"")];
                                   completion(nil, nil);
                               }
                               else {
                                   [YAUtils showHudWithText:NSLocalizedString(@"Can not remove member", @"")];
                                   NSString *str = [data hexRepresentationWithSpaces_AS:NO];
                                   if(response)
                                       completion([NSString stringFromHex:str], [NSError errorWithDomain:@"YADomain" code:[(NSHTTPURLResponse*)response statusCode] userInfo:@{@"response":response}]);
                                   else
                                       completion(nil, [NSError errorWithDomain:@"YADomain" code:0 userInfo:nil]);
                               }

                           }];
}


- (void)leaveGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSDictionary *parameters = @{
                                 @"phone": [YAUser currentUser].phoneNumber
                                 };
    
    id json = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *api = [NSString stringWithFormat:API_GROUP_MEMBERS_TEMPLATE, self.base_api, serverGroupId];
    
    NSURL *url = [NSURL URLWithString:api];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"DELETE"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"Token %@", self.authToken] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:json];
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Leaving group", @"")];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               [hud hide:NO];
                               
                               if([(NSHTTPURLResponse*)response statusCode] == 200) {
                                   [YAUtils showHudWithText:NSLocalizedString(@"Group left", @"")];
                                   completion(nil, nil);
                               }
                               else {
                                   [YAUtils showHudWithText:NSLocalizedString(@"Can not leave group", @"")];
                                   NSString *str = [data hexRepresentationWithSpaces_AS:NO];
                                   if(response)
                                       completion([NSString stringFromHex:str], [NSError errorWithDomain:@"YADomain" code:[(NSHTTPURLResponse*)response statusCode] userInfo:@{@"response":response}]);
                                   else
                                       completion(nil, [NSError errorWithDomain:@"YADomain" code:0 userInfo:nil]);
                               }
                               
                           }];
}

- (void)renameGroupWithId:(NSString*)serverGroupId newName:(NSString*)newName withCompletion:(responseBlock)completion {
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_GROUP_TEMPLATE, self.base_api, serverGroupId];
    
    NSDictionary *parameters = @{
                                 @"name": newName
                                 };
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Renaming group", @"")];
    [self.jsonOperationsManager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [hud hide:NO];
        [YAUtils showHudWithText:NSLocalizedString(@"Group renamed", @"")];
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [hud hide:NO];
        [YAUtils showHudWithText:NSLocalizedString(@"Can not rename group", @"")];
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
    
    [self.jsonOperationsManager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
        completion(dict, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)muteGroupWithId:(NSString*)serverGroupId mute:(BOOL)mute withCompletion:(responseBlock)completion  {
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_MUTE_GROUP_TEMPLATE, self.base_api, serverGroupId];
    
    NSDictionary *parameters = @{
                                 @"mute": mute ? @"true" : @"false"
                                 };
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:mute ? NSLocalizedString(@"Muting group", @"") : NSLocalizedString(@"Unmuting group", @"")];
    [self.jsonOperationsManager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [hud hide:NO];
        [YAUtils showHudWithText:mute ? NSLocalizedString(@"Group muted", @"") : NSLocalizedString(@"Group unmuted", @"")];
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [hud hide:NO];
        [YAUtils showHudWithText:mute ? NSLocalizedString(@"Can not mute group", @"") : NSLocalizedString(@"Can not unmute group", @"")];
        completion(nil, error);
    }];
}

- (void)getGroupsWithCompletion:(responseBlock)completion
{
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *api = [NSString stringWithFormat:API_GROUPS_TEMPLATE, self.base_api];
    
    [self.jsonOperationsManager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)searchGroupsWithCompletion:(responseBlock)completion
{
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *api = [NSString stringWithFormat:API_GROUPS_SEARCH_TEMPLATE, self.base_api];
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Searching groups", @"")];
    [self.jsonOperationsManager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [hud hide:NO];
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [hud hide:NO];
        [YAUtils showHudWithText:NSLocalizedString(@"Failed to search groups", @"")];
        completion(nil, error);
    }];
}

- (void)joinGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion
{
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *api = [NSString stringWithFormat:API_GROUP_JOIN_TEMPLATE, self.base_api, serverGroupId];
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Requesting to join to group", @"")];
    [self.jsonOperationsManager PUT:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [hud hide:NO];
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [hud hide:NO];
        [YAUtils showHudWithText:NSLocalizedString(@"Failed to join group", @"")];
        completion(nil, error);
    }];
}

#pragma mark - Posts
- (void)uploadVideo:(YAVideo*)video toGroupWithId:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    NSAssert(serverGroupId, @"serverGroup is a required parameter");

    NSString *api = [NSString stringWithFormat:API_GROUP_POSTS_TEMPLATE, self.base_api, serverGroupId];
    NSString *videoLocalId = [video.localId copy];
    
    [self.jsonOperationsManager POST:api
            parameters:nil
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if ([video isInvalidated]) {
                       YARealmObjectUnavailableError *yaError = [YARealmObjectUnavailableError new];
                       completion(videoLocalId, yaError);
                       return;
                   }
                   
                   DLog(@"uploadVideoData, recieved params for S3 upload. Making multipart upload...");
                   
                   NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
                   dispatch_async(dispatch_get_main_queue(), ^{
                       
                       [video.realm beginWriteTransaction];
                       video.serverId = dict[YA_RESPONSE_ID];
                       [video.realm commitWriteTransaction];
                       
                       NSDictionary *meta = dict[@"meta"];
                       NSString *videoEndpoint = meta[@"attachment"][@"endpoint"];
                       NSDictionary *videoFields =  meta[@"attachment"][@"fields"];
                       
                       //save gif upload credentials for later use
                       NSMutableDictionary *gifsUploadCredentials = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kGIFUploadCredentials]];
                       [gifsUploadCredentials setObject:meta[@"attachment_preview"] forKey:video.serverId];
                       [[NSUserDefaults standardUserDefaults] setObject:gifsUploadCredentials forKey:kGIFUploadCredentials];
                       
                       NSData *videoData = [[NSFileManager defaultManager] contentsAtPath:[YAUtils urlFromFileName:video.mp4Filename].path];
                       
                       [[Mixpanel sharedInstance] timeEvent:@"Upload Video"];
                       
                       //gif might not be there yet, it's in progress, so uploading video at once and saving credentials for uploading gif, it will be uploaded when gif operation is done
                       [self multipartUpload:videoEndpoint withParameters:videoFields withFile:videoData videoServerId:video.serverId completion:^(id response, NSError *error) {
                           [[Mixpanel sharedInstance] track:@"Upload Video"];
                           
                           if ([video isInvalidated]) {
                               YARealmObjectUnavailableError *yaError = [YARealmObjectUnavailableError new];
                               completion(videoLocalId, yaError);
                               return;
                           }

                           //empty server id in case of an error, transaction will be executed again
                           if(error) {
                               [video.realm beginWriteTransaction];
                               video.serverId = @"";
                               video.uploadedToAmazon = NO;
                               [video.realm commitWriteTransaction];
                               
                               //show local notification if app is in background
                               if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                                   UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                                   localNotification.fireDate = [NSDate date];
                                   localNotification.alertBody = NSLocalizedString(@"Video failed to upload", @"");
                                   localNotification.alertAction = NSLocalizedString(@"Retry", @"");
                                   localNotification.applicationIconBadgeNumber = 1;
                                   [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                               }
                              
                           }
                           else {
                               [video.realm beginWriteTransaction];
                               video.uploadedToAmazon = YES;
                               [video.realm commitWriteTransaction];
                               [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:video];
                               [self executePendingCopyForVideo:video];
                           }

                           //call completion block when video is posted
                           completion(response, error);
                       }];
                   });
                   
               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   completion(nil, error);
               }];
}

- (void)uploadGIFForVideoWithServerId:(NSString*)videoServerId {
    NSMutableDictionary *gifsUploadCredentials = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kGIFUploadCredentials]];
    NSDictionary *credentials = [gifsUploadCredentials objectForKey:videoServerId];
    
    if(credentials.allKeys.count) {
        RLMResults *results = [YAVideo objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", videoServerId]];
        if(results.count != 1)
            return;
        
        YAVideo *video = results[0];
        if(video.isInvalidated) {
            return;
        }
        
        if(video.gifUrl.length) {
            DLog(@"Gif already uploaded for video : %@", videoServerId);
            return;
        }
        
        NSData *gifData = [[NSFileManager defaultManager] contentsAtPath:[YAUtils urlFromFileName:video.gifFilename].path];
        
        NSString *gifEndpoint = credentials[@"endpoint"];
        NSDictionary *gifFields = credentials[@"fields"];
        
        [[Mixpanel sharedInstance] timeEvent:@"GIF Posted"];
        
        [self multipartUpload:gifEndpoint withParameters:gifFields withFile:gifData videoServerId:video.serverId completion:^(id response, NSError *error) {
            if(error) {
                DLog(@"an error occured during gif upload: %@", error.localizedDescription);
            }
            else {
                [[Mixpanel sharedInstance] track:@"GIF posted"];
                if (!video.isInvalidated) {
                    DLog(@"for video: %@", video.serverId);
                }
            }
        }];
        
        [gifsUploadCredentials removeObjectForKey:videoServerId];
        [[NSUserDefaults standardUserDefaults] setObject:gifsUploadCredentials forKey:kGIFUploadCredentials];
    }
}

- (void)multipartUpload:(NSString*)endpoint withParameters:(NSDictionary*)dict withFile:(NSData*)file videoServerId:(NSString*)serverId completion:(responseBlock)completion {
    
    if(!file.length) {
        DLog(@"File is 0 bytes, can't upload");
        completion(nil, [NSError errorWithDomain:@"YADomain" code:0 userInfo:@{@"response":@"File is 0 bytes, can't upload"}]);
        return;
    }
    
    AFHTTPRequestOperation *postOperation = [self.xmlOperationsManager POST:endpoint
                                                                 parameters:dict constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                     
                                                                     [formData appendPartWithFormData:file name:@"file"];
                                                                     
                                                                 } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                     completion(operation.response, nil);
                                                                     [self.multipartUploadsInProgress removeObjectForKey:serverId];
                                                                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                     completion(nil, error);
                                                                     [self.multipartUploadsInProgress removeObjectForKey:serverId];
                                                                 }];
    [postOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        DLog(@"uploaded %lld out of %lld", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    [self.multipartUploadsInProgress setObject:postOperation forKey:serverId];
}

- (void)deleteVideoWithId:(NSString*)serverVideoId fromGroup:(NSString*)serverGroupId withCompletion:(responseBlock)completion {
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        completion(nil, [NSError errorWithDomain:@"YANoConnection" code:0 userInfo:nil]);
        return;
    }
    
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSAssert(serverVideoId, @"videoId is a required parameter");
    NSAssert(serverGroupId, @"groupId is a required parameter");
    
    if (!serverVideoId.length) {
        completion(nil, nil);
        return;
    }
    
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_TEMPLATE, self.base_api, serverGroupId, serverVideoId];
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Deleting video", @"")];
    [self.jsonOperationsManager DELETE:api
              parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  [hud hide:NO];
                  [YAUtils showHudWithText:NSLocalizedString(@"Video deleted", @"")];

                  completion(responseObject, nil);
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [hud hide:NO];
                  [YAUtils showHudWithText:NSLocalizedString(@"Can't delete video", @"")];
                   
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
    
    // match yavideo variables with server fields.
    NSDictionary *parameters = @{
                                 @"name": video.caption,
                                 @"name_x": [NSNumber numberWithFloat:video.caption_x],
                                 @"name_y": [NSNumber numberWithFloat:video.caption_y],
                                 @"rotation": [NSNumber numberWithFloat:video.caption_rotation],
                                 @"scale": [NSNumber numberWithFloat:video.caption_scale],
                                 @"font": [NSNumber numberWithInteger:video.font]
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
                               if([(NSHTTPURLResponse*)response statusCode] == 200)
                                   completion(nil, nil);
                               else {
                                   NSString *str = [data hexRepresentationWithSpaces_AS:NO];
                                   if(response)
                                       completion([NSString stringFromHex:str], [NSError errorWithDomain:@"YADomain" code:[(NSHTTPURLResponse*)response statusCode] userInfo:@{@"response":response}]);
                                   else
                                       completion(nil, [NSError errorWithDomain:@"YADomain" code:0 userInfo:nil]);
                               }

                           }];
}

- (void)likeVideo:(YAVideo*)video withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *serverGroupId = [YAUser currentUser].currentGroup.serverId;
    NSString *serverVideoId = video.serverId;
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_LIKE, self.base_api, serverGroupId, serverVideoId];
    [self.jsonOperationsManager POST:api
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
                   DLog(@"%@", [NSString stringFromHex:hex]);
                   completion(nil, nil);
               }];
}

- (void)unLikeVideo:(YAVideo*)video withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    
    NSString *serverGroupId = [YAUser currentUser].currentGroup.serverId;
    NSString *serverVideoId = video.serverId;
    NSString *api = [NSString stringWithFormat:API_GROUP_POST_LIKE, self.base_api, serverGroupId, serverVideoId];
    [self.jsonOperationsManager   DELETE:api
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
                       completion(nil, nil);
                   }];
}

- (void)copyVideo:(YAVideo*)video toGroupsWithIds:(NSArray*)groupIdsToCopyTo withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"auth token not set");
    
    //execute copy video
    if(video.uploadedToAmazon) {
        NSString *api = [NSString stringWithFormat:API_GROUP_POST_COPY, self.base_api, video.group.serverId, video.serverId];
        NSDictionary *parameters = @{
                                     @"groups": groupIdsToCopyTo
                                    };
        
        [self.jsonOperationsManager POST:api
                             parameters:parameters
                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    completion(nil, nil);
                                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                    NSString *hex = [error.userInfo[ERROR_DATA] hexRepresentationWithSpaces_AS:NO];
                                    completion([NSString stringFromHex:hex], error);
                                }];
    }
    //otherwise save copy data for later execution when video is uploaded
    else {
        NSMutableDictionary *crosspostData = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kCrosspostData]];
        NSMutableSet *groupIds = [NSMutableSet setWithSet:crosspostData[video.localId]];
        [groupIds addObjectsFromArray:groupIdsToCopyTo];
        
        [crosspostData setObject:groupIds.allObjects forKey:video.localId];
        [[NSUserDefaults standardUserDefaults] setObject:crosspostData forKey:kCrosspostData];
        
        completion(nil, nil);
    }
}

- (void)executePendingCopyForVideo:(YAVideo*)video {
    NSMutableDictionary *crosspostData = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kCrosspostData]];
    NSArray *groupIds = [crosspostData[video.localId] allObjects];
    
    if(groupIds.count) {
        [self copyVideo:video toGroupsWithIds:groupIds withCompletion:^(id response, NSError *error) {
            if(!error) {
                [crosspostData removeObjectForKey:video.localId];
                [[NSUserDefaults standardUserDefaults] setObject:crosspostData forKey:kCrosspostData];
            }
        }];
    }
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
    
    [self.jsonOperationsManager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
//    DLog(@"%@", [NSString stringFromHex:hex]);
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
                
                //kill all multipart uploads when reachability changes
                for (AFHTTPRequestOperation *postOperation in weakSelf.multipartUploadsInProgress.allValues) {
                    DLog(@"connection type changed, cancelling multipart upload to prevent callback not being called");
                    [postOperation cancel];

                }
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
                DLog(@"registerDeviceTokenIfNeeded error: %@", [NSString stringWithFormat:@"Can't register device token. %@", error.localizedDescription]);
            }
        }];
    }
}
- (void)sync {
    DLog(@"YAServer:sync, serverUp: %@", self.serverUp ? @"Yes" : @"No");
    
    if([[YAUser currentUser] loggedIn] && self.authToken.length && self.serverUp) {
        
        [self registerDeviceTokenIfNeeded];
        
        //read updates from server
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
            if(!error) {
                self.lastUpdateTime = [NSDate date];
                DLog(@"groups updated from server successfully");
                
                //send local changes to the server
                [[YAServerTransactionQueue sharedQueue] processPendingTransactions];
                
                //current group never updated or updatedAt is older than local?
                NSDictionary *groupsUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT];
                NSDate *localGroupUpdateDate = [groupsUpdatedAt objectForKey:[YAUser currentUser].currentGroup.localId];
                if(!localGroupUpdateDate || [[YAUser currentUser].currentGroup.updatedAt compare:localGroupUpdateDate] == NSOrderedDescending) {
                    [[[YAUser currentUser] currentGroup] refresh];
                }

            }
            else {
                DLog(@"unable to read groups from server");
            }
        }];
        
    }
    
    [[YAUser currentUser] purgeOldVideos];
}

- (void)getYagaUsersFromPhonesArray:(NSArray*)phones withCompletion:(responseBlock)completion {
    NSAssert(self.authToken.length, @"token not set");
    
    NSMutableArray *correctPhones = [NSMutableArray arrayWithArray:[[NSSet setWithArray:phones] allObjects]];
    for(NSString *phone in [correctPhones copy]) {
        if(![YAUtils validatePhoneNumber:phone]) {
            [correctPhones removeObject:phone];
        }
    }
    
    NSString *api = [NSString stringWithFormat:API_USER_SEARCH_TEMPLATE, self.base_api];
    
    NSDictionary *parameters = @{
                                 @"phones": correctPhones
                                 };
    
    [self.jsonOperationsManager POST:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

#pragma mark Notifications
- (void)willDeleteVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    if(!video.serverId)
        return;
    
    AFHTTPRequestOperation *postOperation = [self.multipartUploadsInProgress objectForKey:video.serverId];
    if(postOperation) {
        [postOperation cancel];
        [self.multipartUploadsInProgress removeObjectForKey:video.serverId];
    }
}

@end
