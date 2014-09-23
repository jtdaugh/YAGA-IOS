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

@interface CNetworking : NSObject
@property (nonatomic,assign)id delegate;
@property (strong, nonatomic) NSMutableDictionary *userData;
@property (strong, nonatomic) Firebase *firebase;
@property (strong, nonatomic) NSMutableArray *groupInfo;
@property (strong, nonatomic) NSMutableDictionary *messages;

+ (id)currentUser;

- (void) loadUserData;
- (void) saveUserData:(NSObject *)value forKey:(NSString *)key;
- (NSObject *) userDataForKey:(NSString *)key;
- (NSMutableArray *)gridDataForGroupId:(NSString *)groupId;
- (NSUInteger) groupIndexForGroupId:(NSString *)groupId;
- (void)trySomething;
- (void)registerUser;

@end
