//
//  CNetworking.m
//  Pic6
//
//  Created by Raj Vir on 7/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CNetworking.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <PromiseKit.h>

@implementation CNetworking

+ (id)currentUser {
    static CNetworking *sharedCNetworking = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCNetworking = [[self alloc] init];
    });
    return sharedCNetworking;
}

- (id)init {
    if (self = [super init]) {
        [self loadUserData];
        
        if(!self.messages){
            self.messages = [[NSMutableDictionary alloc] init];
        }
        
        self.firebase = [[[Firebase alloc] initWithUrl:@"https://pic6.firebaseIO.com"] childByAppendingPath:NODE_NAME];
        NSLog(@"just inited firebase");
    }
    
    return self;
}

/**
    AFNetworking Code is here
 **/

- (void)registerUserWithCompletionBlock:(void (^)())block {
    NSLog(@"signing up");
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString *username = (NSString *)[self userDataForKey:nUsername];
    NSString *phone = (NSString *)[self userDataForKey:nPhone];
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    
    NSDictionary *params = @{
                             @"phone":phone,
                             @"name": username,
                             @"password":@"test",
                             @"country":countryCode
                             };
    
    [manager POST:[NSString stringWithFormat:@"%@/token", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *token = [responseObject objectForKey:@"token"];
        NSString *userId = [responseObject objectForKey:@"user_id"];
        [self saveUserData:token forKey:@"token"];
        [self saveUserData:userId forKey:nUserId];
        NSLog(@"%@", responseObject);

//        NSString *crewId = @"077481791fd3431782279d23f8fae199";
        NSString *crewId = @"bb72f20e-0051-4e85-8e12-e7a37cf77f37";

        __block CNetworking *blockSelf = self;
        
        [self addToCrew:crewId withCompletionBlock:^(){
            NSLog(@"wat");
            [blockSelf myCrewsWithCompletion:block];
        }];        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        block();
    }];
}

- (void)createCrew {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    NSDictionary *params = @{
                             @"name":@"my first crew",
                             @"initial_members":@[@"d55c4b053509d7a2bc4ffb34d3bb9db6"]
                             };
    
    [manager POST:[NSString stringWithFormat:@"%@/crew/create", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
        
        //        NSLog(@"%@", [responseObject objectForKey:@"crew_id"]);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)meInfo {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    
    [manager GET:[NSString stringWithFormat:@"%@/me", BASE_API_URL] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}

- (void)myCrews {
    [self myCrewsWithCompletion:nil];
}

- (void)myCrewsWithCompletion:(void (^)())block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    [manager GET:[NSString stringWithFormat:@"%@/me/crews", BASE_API_URL] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *items = [responseObject objectForKey:@"items"];
       [self saveUserData:[@[] mutableCopy] forKey:nGroupInfo];
        for(id item in items){
            GroupInfo *groupInfo = [[GroupInfo alloc] init];
            groupInfo.groupId = [item objectForKey:@"crew_id"];
            groupInfo.name = [item objectForKey:@"name"];
            
//            [self.groupInfo addObject:groupInfo];
        }
        
//        [self saveUserData:self.groupInfo forKey:nGroupInfo];
        
        block();
        
        NSLog(@"%@", [responseObject objectForKey:@"items"]);
        NSLog(@"groupinfo count: %lu", [self.groupInfo count]);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
        block();
    }];
}

- (void)addToCrew:(NSString *)crewId withCompletionBlock:(void (^)())block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    NSString *userId = (NSString *) [self userDataForKey:nUserId];
    // bb72f20e-0051-4e85-8e12-e7a37cf77f37
    
    [manager POST:[NSString stringWithFormat:@"%@/crew/%@/member/%@", BASE_API_URL, crewId, userId] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        NSLog(@"added to crew! %@", responseObject);
        block();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        NSLog(@"here it is: %@", error);
    }];
    
}

- (BOOL)loggedIn {
    if([self userDataForKey:@"username"]){
        return YES;
    } else {
        return NO;
    }
}

- (void)logout {
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
    [self.userData removeAllObjects];
}



//- (void)

/**
 END AFNetworking Code
 **/

- (void)trySomething {
    [self.delegate test];
}

- (void)saveUserData:(NSObject *)value forKey:(NSString *)key {
    [self.userData setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSObject *)userDataForKey:(NSString *)key {
    return [self.userData objectForKey:key];
}

- (void)loadUserData {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    self.userData = [[defaults dictionaryRepresentation] mutableCopy];
}

- (NSString *)humanName {
    
    NSString *deviceName = [[UIDevice currentDevice].name lowercaseString];
    for (NSString *string in @[@"’s iphone", @"’s ipad", @"’s ipod touch", @"’s ipod",
                               @"'s iphone", @"'s ipad", @"'s ipod touch", @"'s ipod",
                               @"s iphone", @"s ipad", @"s ipod touch", @"s ipod", @"iphone"]) {
        NSRange ownershipRange = [deviceName rangeOfString:string];
        
        if (ownershipRange.location != NSNotFound) {
            return [[[deviceName substringToIndex:ownershipRange.location] componentsSeparatedByString:@" "][0]
                    stringByReplacingCharactersInRange:NSMakeRange(0,1)
                    withString:[[deviceName substringToIndex:1] capitalizedString]];
        }
    }
    
    return [UIDevice currentDevice].name;
}

- (NSMutableArray *)gridDataForGroupId:(NSString *)groupId {
    if(!groupId){
        return [@[] mutableCopy];
    }
    if(!self.messages[groupId]){
        self.messages[groupId] = [@[] mutableCopy];
    }
    return (NSMutableArray *) self.messages[groupId];
}

- (NSUInteger) groupIndexForGroupId:(NSString *)groupId {
    NSUInteger index = 0;
    for(GroupInfo *groupInfo in self.groupInfo){
        if([groupInfo.groupId isEqualToString: groupId]){
            return index;
        }
        index++;
    }
    return -1;
}

- (NSMutableArray *)groupInfo {
    if(![self userDataForKey:nGroupInfo]){
        [self saveUserData:[@[] mutableCopy] forKey:nGroupInfo];
    }
    GroupInfo *groupInfo = [[GroupInfo alloc] init];
    groupInfo.name = @"LindenFest 2014";
    groupInfo.groupId = @"yolo";
    return [@[ groupInfo ] mutableCopy];
    
    return (NSMutableArray *)[self userDataForKey:nGroupInfo];
}

@end
