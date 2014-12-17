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
- (void)sendSMSAuthRequestWithCompletion:(responseBlock)completion;
@end
