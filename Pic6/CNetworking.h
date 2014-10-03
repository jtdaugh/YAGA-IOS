//
//  CNetworking.h
//  Pic6
//
//  Created by Raj Vir on 7/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import "GroupInfo.h"

@class CNetworking;

@protocol CNetworkingDelegate <NSObject>
@optional
- (void)test;
@end

#define nUsername @"username"
#define nPhone @"phone"
#define nCountry @"country"
#define nToken @"token"
#define nUserId @"user_id"
#define nGroupInfo @"group_info"

@interface CNetworking : NSObject
@property (nonatomic,assign)id delegate;
@property (strong, nonatomic) NSMutableDictionary *userData;
@property (strong, nonatomic) Firebase *firebase;
@property (strong, nonatomic) NSMutableDictionary *messages;

+ (id)currentUser;

- (void) loadUserData;
- (void) saveUserData:(NSObject *)value forKey:(NSString *)key;
- (NSObject *) userDataForKey:(NSString *)key;
- (NSMutableArray *)gridDataForGroupId:(NSString *)groupId;
- (NSUInteger) groupIndexForGroupId:(NSString *)groupId;
- (NSMutableArray *)groupInfo;
- (void)trySomething;
- (void)registerUserWithCompletionBlock:(void (^)())block;
- (void)createCrew;
- (void)meInfo;
- (void)myCrews;
- (BOOL)loggedIn;
- (void)logout;

@end
