//
//  YAPushNotificationHandler.h
//  Yaga
//
//  Created by valentinkovalski on 2/27/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YAPushNotificationHandler : NSObject

+ (instancetype)sharedHandler;

- (void)handlePushWithUserInfo:(NSDictionary*)userInfo;

@end
