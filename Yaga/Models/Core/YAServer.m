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

#define HOST @"https://yaga-dev.herokuapp.com"
#define PORT @"443"
#define API_ENDPOINT @"/yaga/api/v1"

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
    
    NSString *api = [NSString stringWithFormat:@"%@/user/info/", self.base_api];

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
    
    NSString *api = [NSString stringWithFormat:@"%@/user/profile/", self.base_api];
    
    NSDictionary *parameters = @{
                                 @"name": name
                                 };
    
    [self.manager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
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
    
    NSString *api = [NSString stringWithFormat:@"%@/auth/request/", self.base_api];
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
    
    NSString *api = [NSString stringWithFormat:@"%@/group/", self.base_api];
    
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

- (void)updateGroupMembersForGroup:(YAGroup*)group withCompletion:(responseBlock)completion {
#warning TODO: add/delete group members
//    NSAssert(self.token, @"token not set");
//    
//    [self createGroupWithName:@"Default" withCompletion:^(bool response, NSString *error) {
//        if (response) {
//            NSNumber *i = groupId ? groupId : [YAGroupCreator sharedCreator].groupId;
//            NSString *api = [NSString stringWithFormat:@"%@/group/%@/add/", self.base_api, i];
//            
////            NSMutableString *userPhones = [NSMutableString new];
////            [userPhones appendString:@"phones=["];
////            for (NSDictionary *user in users) {
////                NSString *str = user[@"phone"];
////                [userPhones appendString:str];
////                if (![user isEqual:[users lastObject]]) {
////                    [userPhones appendString:@","];
////                }
////            }
////            [userPhones appendString:@"]"];
//
//            NSMutableArray *array = [NSMutableArray new];
//            for (NSDictionary *d in members) {
//                [array addObject:d[@"phone"]];
//            }
//            
//            NSDictionary *parameters = @{
//                                         @"phones": array
//                                         };
//            
//            id json = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
//            
//            NSURL *url=[NSURL URLWithString:api];
//            
//            NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
//            [request setHTTPMethod:@"PUT"];
//            
//            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//            
//            [request setValue:[NSString stringWithFormat:@"Token %@", self.token] forHTTPHeaderField:@"Authorization"];
//            [request setHTTPBody:json];
//
//            [NSURLConnection sendAsynchronousRequest:request
//                                               queue:[NSOperationQueue mainQueue]
//                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//                                       NSString *str = [data hexRepresentationWithSpaces_AS:NO];
//                                                       NSLog(@"%@", [NSString stringFromHex:str]);
//                                                       completion(YES, @"TESTING");
//                                   }];
////            [self.manager PUT:api parameters:json success:^(AFHTTPRequestOperation *operation, id responseObject) {
////                NSString *str = [operation.request.HTTPBody hexRepresentationWithSpaces_AS:NO];
////                NSLog(@"%@", [NSString stringFromHex:str]);
////                completion(YES, @"TESTING");
////            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
////                [self printErrorData:error];
////                NSLog(@"%@", error);
////            }];
//        }
//        else
//        {
//            
//        }
//    }];
}

- (void)addUserByPhone:(NSString*)userPhone toGroup:(NSNumber *)groupId
{
    NSAssert(self.token, @"token not set");
    
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

- (void)renameGroup:(YAGroup*)group newName:(NSString*)newName withCompletion:(responseBlock)completion
{
    NSAssert(self.token, @"token not set");
    NSAssert(group.serverId, @"group doesn't exist on server yet");
    
    NSString *api = [NSString stringWithFormat:@"%@/group/%@/", self.base_api, group.serverId];
    
    NSDictionary *parameters = @{
                                 @"name": newName
                                 };
    
    [self.manager PATCH:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        completion(nil, error);
    }];
}

- (void)removeGroup:(YAGroup*)group withCompletion:(responseBlock)completion
{
    NSAssert(self.token, @"token not set");
    NSAssert(group.serverId, @"group doesn't exist on server yet");
    
    NSString *api = [NSString stringWithFormat:@"%@/group/%@/remove/", self.base_api, group.serverId];
    
    NSDictionary *parameters = @{
                                 @"phone": self.phoneNumber
                                 };
    
    [self.manager PUT:api parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        completion(nil, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        completion(nil, nil);
    }];
}

- (void)getGroupsWithCompletion:(responseBlock)completion
{
    NSAssert(self.token, @"token not set");
    
    NSString *api = [NSString stringWithFormat:@"%@/group/", self.base_api];
    
    [self.manager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(error, nil);
    }];
}

#pragma mark - Utitlities
- (void)printErrorData:(NSError*)error
{
    NSString *hex = [error.userInfo[ERROR_DATA] hexRepresentationWithSpaces_AS:NO];
    NSLog(@"%@", [NSString stringFromHex:hex]);
}
@end
