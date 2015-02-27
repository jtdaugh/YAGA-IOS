//
//  YANotificationView.h
//  Yaga
//
//  Created by valentinkovalski on 2/10/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YANotificationType) {
    YANotificationTypeSuccess = 0,
    YANotificationTypeError,
    YANotificationTypeMessage
};

typedef void (^actionHandlerBlock)(void);

@interface YANotificationView : NSObject

+ (void)showMessage:(NSString*)message viewType:(YANotificationType)type;

- (void)showMessage:(NSString*)message viewType:(YANotificationType)type actionHandler:(actionHandlerBlock)actionHandler;

@end
