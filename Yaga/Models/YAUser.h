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

typedef void (^contactsImportedBlock)(NSError *error, NSMutableArray *contacts);

@protocol CNetworkingDelegate <NSObject>
@optional
- (void)test;
@end


@interface YAUser : NSObject

@property (nonatomic, strong) YAGroup *currentGroup;
@property (nonatomic, strong) NSString *phoneNumber;

@property (nonatomic) BOOL phoneNumberIsRegistered;
@property (nonatomic, copy) NSString *dialCode;
@property (nonatomic, copy) NSString *countryCode;

@property (nonatomic,assign)  id delegate;
@property (strong, nonatomic) NSMutableDictionary *userData;
@property (strong, nonatomic) NSMutableDictionary *messages;

@property (strong, nonatomic) NSString *authCode;

+ (YAUser*)currentUser;

- (void)saveUserData:(NSObject *)value forKey:(NSString *)key;
- (NSObject *)userDataForKey:(NSString *)key;

- (void)saveObject:(NSObject *)value forKey:(NSString *)key;
- (id)objectForKey:(NSString*)key;

- (NSMutableArray *)gridDataForGroupId:(NSString *)groupId;

- (BOOL)loggedIn;
- (void)logout;

- (void)importContactsWithCompletion:(contactsImportedBlock)completion;

- (NSString*)username;
@end
