//
//  CNetworking.m
//  Pic6
//
//  Created by Raj Vir on 7/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CNetworking.h"
#import "CContact.h"
#import "NSString+Hash.h"
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
        
        if(!self.contacts){
            self.contacts = [[NSMutableArray alloc] init];
        }
        
        if(!self.groupInfo){
            self.groupInfo = [[NSMutableArray alloc] init];
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
    
    
    NSLog(@"params: %@", params);
    
    NSLog(@"phone: %@", phone);
    
    NSLog(@"phone hash: %@", [phone md5]);
    
    [manager POST:[NSString stringWithFormat:@"%@/token", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *token = [responseObject objectForKey:@"token"];
        NSString *userId = [responseObject objectForKey:@"user_id"];
        [self saveUserData:token forKey:@"token"];
        [self saveUserData:userId forKey:nUserId];
        NSLog(@"/token response: %@", responseObject);

        block();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"register user Error: %@", error);
    }];
}

- (void)createCrew:(NSString *)name withMembers:(NSArray *)hashes withCompletionBlock:(void (^)())block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{
                             @"name":name,
                             @"initial_members":hashes
                             };
    
//    NSLog(@"params: %@", params);
    
    [manager POST:[NSString stringWithFormat:@"%@/crew/create", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
        block();
        //        NSLog(@"%@", [responseObject objectForKey:@"crew_id"]);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"create crew Error: %@", error);
        
    }];
}

- (void)meInfo {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    
    [manager GET:[NSString stringWithFormat:@"%@/me", BASE_API_URL] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"meInfo: %@", responseObject);
        
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
        
        self.groupInfo = [[NSMutableArray alloc] init];
        
        NSArray *items = [responseObject objectForKey:@"items"];
        for(id item in items){
            GroupInfo *groupInfo = [[GroupInfo alloc] init];
            groupInfo.groupId = [item objectForKey:@"crew_id"];
            groupInfo.name = [item objectForKey:@"name"];
            
            [self.groupInfo addObject:groupInfo];
        }
        
        NSData *groupData = [NSKeyedArchiver archivedDataWithRootObject:self.groupInfo];
        [self saveObject:groupData forKey:nGroupInfo];
//        [self saveUserData:self.groupInfo forKey:nGroupInfo];
        
        NSLog(@"groups: %@", responseObject);
        NSLog(@"groupinfo count: %lu", [self.groupInfo count]);
        block();
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"my crews Error: %@", error);
        
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
        block();
    }];
    
}

- (void)findFriends:(NSArray *)numbers withCompletionBlock:(void (^)())block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{
                             @"hashes":numbers
                             };
    
    NSLog(@"hashes params: %@", params);
    
    [manager POST:[NSString stringWithFormat:@"%@/match", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        NSLog(@"matches: %@", responseObject);
        block();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        NSLog(@"here's the damn error: %@", error);
        block();
    }];
}



- (BOOL)loggedIn {
    if([self userDataForKey:nUsername]){
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
    [self saveObject:value forKey:key];
}

- (void)saveObject:(NSObject *)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSObject *)userDataForKey:(NSString *)key {
    return [self.userData objectForKey:key];
}

- (void)loadUserData {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    self.userData = [[defaults dictionaryRepresentation] mutableCopy];
        
    if([defaults objectForKey:nGroupInfo]){
        NSLog(@"groupInfo");
        NSData *data = [defaults objectForKey:nGroupInfo];
        self.groupInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
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

//- (NSMutableArray *)groupInfo {
//    if(![self userDataForKey:nGroupInfo]){
//        [self saveUserData:[@[] mutableCopy] forKey:nGroupInfo];
//    }
//    GroupInfo *groupInfo = [[GroupInfo alloc] init];
//    groupInfo.name = @"LindenFest 2014";
//    groupInfo.groupId = @"yolo";
//    return [@[ groupInfo ] mutableCopy];
//    
//    return (NSMutableArray *)[self userDataForKey:nGroupInfo];
//}

@end
