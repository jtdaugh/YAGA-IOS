//
//  CNetworking.h
//  Pic6
//
//  Created by Raj Vir on 7/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAGroup.h"

@import MessageUI;

@class YAUser;

typedef void (^contactsImportedBlock)(NSError *error, NSMutableArray *contacts, BOOL sentToServer);

@protocol CNetworkingDelegate <NSObject>
@optional
- (void)test;
@end


@interface YAUser : NSObject<MFMessageComposeViewControllerDelegate> {
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
}

@property (nonatomic) BOOL phoneNumberIsRegistered;
@property (nonatomic, copy) NSString *dialCode;
@property (nonatomic, copy) NSString *countryCode;

@property (strong, nonatomic) NSMutableDictionary *userData;
@property (strong, nonatomic) NSMutableDictionary *messages;

@property (strong, nonatomic) NSString *authCode;

+ (YAUser*)currentUser;
- (void)saveObject:(NSObject *)value forKey:(NSString *)key;
- (id)objectForKey:(NSString*)key;

- (NSMutableArray *)gridDataForGroupId:(NSString *)groupId;

- (BOOL)loggedIn;
- (void)logout;

// Will call completion when contacts loaded locally and a second time if it needs to refresh yaga-users from server
- (void)importContactsWithCompletion:(contactsImportedBlock)completion excludingPhoneNumbers:(NSSet*)excludePhonesSet;

- (NSString*)formatDate:(NSDate*)date;
- (NSString*)username;
- (NSString*)phoneNumber;
- (NSString*)serverId;
- (NSString*)deviceToken;

@property (nonatomic, readonly) NSMutableDictionary *phonebook;

- (void)iMessageWithFriends:(NSArray*)friendNumbers group:(YAGroup*)group withCompletion:(completionBlock)completion;

//this will make sure caches folder isn't bigger than 300MB
- (BOOL)assetsFolderSizeExceeded;

- (void)purgeOldVideos;

- (BOOL)hasUnviewedVideosInGroups;

- (void)purgeUnusedAssets;

@end
