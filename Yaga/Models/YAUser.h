//
//  CNetworking.h
//  Pic6
//
//  Created by Raj Vir on 7/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAGroup.h"

@class YAUser;

typedef void (^contactsImportedBlock)(NSError *error, NSArray *contacts);

@protocol CNetworkingDelegate <NSObject>
@optional
- (void)test;
@end

#define nUsername @"username"
#define nPhone @"phone"
#define nCountry @"country"
#define nToken @"token"
#define nUserId @"user_id"
#define nCompositeName @"composite_name"
#define nFirstname @"firstname"
#define nRegistered @"registered"
#define nCurrentGroup @"current_group"

@interface YAUser : NSObject
@property (nonatomic,assign)id delegate;
@property (strong, nonatomic) NSMutableDictionary *userData;
@property (strong, nonatomic) NSMutableDictionary *messages;
@property (strong, nonatomic) NSMutableArray *groups;

+ (YAUser*)currentUser;

- (void)saveUserData:(NSObject *)value forKey:(NSString *)key;
- (NSObject *)userDataForKey:(NSString *)key;
- (NSMutableArray *)gridDataForGroupId:(NSString *)groupId;
- (NSUInteger) groupIndexForGroupId:(NSString *)groupId;
- (void)trySomething;
- (void)registerUserWithCompletionBlock:(void (^)())block;
- (void)findFriends:(NSArray *)numbers withCompletionBlock:(void (^)())block;
- (void)createCrew:(NSString *)name withMembers:(NSArray *)hashes withCompletionBlock:(void (^)())block;
- (void)myCrewsWithCompletion:(void (^)())block;
- (void)meInfo;
- (void)myCrews;
- (BOOL)loggedIn;
- (void)logout;

//
- (void)importContactsWithCompletion:(contactsImportedBlock)completion;

@end
