//
//  CNetworking.m
//  Pic6
//
//  Created by Raj Vir on 7/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CNetworking.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

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
        
        if(!self.groupInfo){
            self.groupInfo = [[NSMutableArray alloc] init];
        }
        
        self.firebase = [[[Firebase alloc] initWithUrl:@"https://pic6.firebaseIO.com"] childByAppendingPath:NODE_NAME];
        NSLog(@"just inited firebase");
//        [self saveUserData:[self humanName] forKey:@"username"];
    }
    
    return self;
}

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
- (void)registerUser {
    
    NSLog(@"signing up");
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSDictionary *params = @{
                             @"phone":@"13107753248",
                             @"name": @"raj vir",
                             @"password":@"test",
                             @"country":@"US"
                             };
    
    [manager POST:[NSString stringWithFormat:@"%@/token", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *token = [responseObject objectForKey:@"token"];
        [self saveUserData:token forKey:@"token"];
        NSLog(@"%@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)createCrew {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    NSDictionary *params = @{
                             @"name":@"my first crew",
                             @"initial_members":@[@"b2f0e9d44bcbca686b50ec249f841d48"]
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
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    
    [manager POST:[NSString stringWithFormat:@"%@/me/crews", BASE_API_URL] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}

@end
