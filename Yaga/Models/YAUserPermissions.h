//
//  YAPermissionsNotifier.h
//  Yaga
//
//  Created by valentinkovalski on 3/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YAUserPermissions : NSObject

+ (BOOL)pushPermissionsRequestedBefore;
+ (void)registerUserNotificationSettings;

@end
