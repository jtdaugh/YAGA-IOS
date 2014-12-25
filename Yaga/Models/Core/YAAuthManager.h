//
//  YAAuthManager.h
//  Yaga
//
//  Created by Iegor on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YAAuthManager : NSObject
typedef void(^responseBlock)(bool response, NSString* error);
+ (instancetype)sharedManager;

- (void)isPhoneNumberRegistered:(NSString *)phoneNumber completion:(responseBlock)completion;

- (void)sendSMSAuthRequestForNumber:(NSString*)number withCompletion:(responseBlock)completion;
- (void)sendTokenRequestWithCompletion:(responseBlock)completion;
- (void)getInfoForCurrentUserWithCompletion:(responseBlock)completion; 
    
    
- (void)sendUserNameRegistration:(NSString*)name withCompletion:(responseBlock)completion;

- (void)addCascadingUsers:(NSArray*)users toGroup:(NSNumber*)groupId withCompletion:(responseBlock)completion;
- (void)sendGroupRenamingWithName:(NSString*)newName forGroupId:(NSNumber*)groupId withCompletion:(responseBlock)completion;
- (void)sendGroupRemovingForGroupId:(NSNumber*)groupId withCompletion:(responseBlock)completion;

- (void)getGroupsWithCompletion:(responseBlock)completion;

@end
