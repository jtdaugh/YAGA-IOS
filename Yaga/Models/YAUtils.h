//
//  YAUtils.h
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAVideo.h"
#import "YANotificationView.h"

typedef void (^uploadDataCompletionBlock)(NSError *error);

@interface YAUtils : NSObject
+ (NSString *)readableNumberFromString:(NSString*)input;
+ (UIColor*)inverseColor:(UIColor*)color;
+ (NSString*)cachesDirectory;
+ (NSString *)uniqueId;
+ (NSURL*)urlFromFileName:(NSString*)fileName;

//UI
+ (void)showNotification:(NSString*)message type:(YANotificationType)type;

+ (UIView*)createBackgroundViewWithFrame:(CGRect)frame alpha:(CGFloat)alpha;
+ (UIImage *)imageWithColor:(UIColor *)color;
+ (BOOL)validatePhoneNumber:(NSString*)value error:(NSError **)error;

//video actions
+ (void)showVideoOptionsForVideo:(YAVideo*)video;
+ (void)deleteVideo:(YAVideo*)video;
@end
