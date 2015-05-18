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
#import "MBProgressHUD.h"
#import "NBPhoneNumberUtil.h"

typedef void (^uploadDataCompletionBlock)(NSError *error);

@interface YAUtils : NSObject <UIAlertViewDelegate>
+ (NSString *)readableNumberFromString:(NSString*)input;
+ (UIColor*)inverseColor:(UIColor*)color;
+ (NSString*)cachesDirectory;
+ (NSString *)uniqueId;
+ (NSURL*)urlFromFileName:(NSString*)fileName;

//UI
+ (void)showNotification:(NSString*)message type:(YANotificationType)type;
+ (void)showHudWithText:(NSString*)text;
+ (MBProgressHUD*)showIndeterminateHudWithText:(NSString*)text;

+ (UIView*)createBackgroundViewWithFrame:(CGRect)frame alpha:(CGFloat)alpha;
+ (UIImage *)imageWithColor:(UIColor *)color;
+ (BOOL)validatePhoneNumber:(NSString*)value error:(NSError **)error;

//video actions
+ (void)deleteVideo:(YAVideo*)video;
//Alert view
+ (instancetype)instance;
+ (void)showAlertViewWithTitle:(NSString*)title
                       message:(NSString*)message
             forViewController:(UIViewController*)vc
                 accepthButton:(NSString*)okButtonTitle
                  cancelButton:(NSString*)cancelButtonTitle
                  acceptAction:(void (^)())acceptAction
                  cancelAction:(void (^)())cancelAction;

//GIF
+ (void)copyGIFToClipboard:(YAVideo*)video;

+ (NSString*)phoneNumberFromText:(NSString *)text numberFormat:(NBEPhoneNumberFormat)format;
@end
