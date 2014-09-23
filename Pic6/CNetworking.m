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
                             @"name": @"raj",
                             @"phone":@"13107753248",
                             @"country":@"1",
                             @"password":@"test"
                             };
    
    [manager POST:[NSString stringWithFormat:@"%@/token", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", [responseObject objectForKey:@"token"]);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
