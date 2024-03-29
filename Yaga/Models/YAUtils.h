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

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

typedef void (^uploadDataCompletionBlock)(NSError *error);
typedef void (^confirmationBlock)(void);
typedef void (^stringCompletionBlock)(NSString *string, NSError *error);

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
+ (BOOL)validatePhoneNumber:(NSString*)value;

//video actions
+ (void)confirmDeleteVideo:(YAVideo*)video withConfirmationBlock:(confirmationBlock)block;
+ (void)confirmFlagVideo:(YAVideo*)video withConfirmationBlock:(confirmationBlock)block;

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

+ (UIColor *)UIColorFromUsernameString:(NSString *)username;

+ (NSString*)phoneNumberFromText:(NSString *)text numberFormat:(NBEPhoneNumberFormat)format;

+ (UIButton *)circleButtonWithImage:(NSString *)imageName diameter:(CGFloat)diameter center:(CGPoint)center;

+ (NSArray*)readableGroupsArrayFromResponse:(NSArray *)response;

// Tooltip/defaults helpers
+ (BOOL)hasSeenFollowingScreen;
+ (void)setSeenFollowingScreen;

+ (BOOL)hasVisitedStream;
+ (void)setVisitedStream;

+ (BOOL)hasVisitedPublicGroup;
+ (void)setVisitedPublicGroup;

+ (BOOL)hasCreatedPublicGroup;
+ (void)setCreatedPublicGroup;

+ (BOOL)hasVisitedPrivateGroup;
+ (void)setVisitedPrivateGroup;

+ (BOOL)hasSeenPendingApprovalMessage;
+ (void)setSeenPendingApprovalMessage;

+ (BOOL)hasTappedRecord;
+ (void)setTappedRecord;

+ (BOOL)hasSeenCamera;
+ (void)setSeenCamera;

+ (BOOL)hasSeenTrimView;
+ (void)setSeenTrimView;

//etc

//get random quote of the day
+ (void)randomQuoteWithCompletion:(stringCompletionBlock)completion;


//server side paging
+ (NSDictionary*)urlParametersFromString:(NSString*)urlString;

+ (void)showBubbleWithText:(NSString*)text bubbleWidth:(CGFloat)width forView:(UIView*)view;
+ (void)showBubbleWithText:(NSString*)text bubbleWidth:(CGFloat)width forView:(UIView*)view arrowDirection:(BOOL)arrowUp;
+ (void)showBubbleWithTextOnce:(NSString*)text bubbleWidth:(CGFloat)width forView:(UIView*)view;
+ (void)hideBubbleWithText:(NSString*)text;
@end
