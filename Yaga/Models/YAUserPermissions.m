//
//  YAPermissionsNotifier.m
//  Yaga
//
//  Created by valentinkovalski on 3/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAUserPermissions.h"

#define kPushesPermissionsRequestedBefore        @"kPushesPermissionsRequestedBefore"
#define kPushesPermissionsAlertNextTimeToShow    @"kPushesPermissionsAlertNextTimeToShow"

@implementation YAUserPermissions

+ (BOOL)pushPermissionsRequestedBefore {
    return [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] boolForKey:kPushesPermissionsRequestedBefore];
}

+ (void)registerUserNotificationSettings {
    //permission dialog was shown and user denied?
    BOOL iosDialogShown = [self pushPermissionsRequestedBefore];
    
    BOOL notRegistered;
    //ios8
    if([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        notRegistered = [[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone;
    }
    //ios7
    else {
        notRegistered = [[UIApplication sharedApplication] enabledRemoteNotificationTypes] == UIRemoteNotificationTypeNone;
    }
    
    if(iosDialogShown && notRegistered) {
        NSDate *remindDialogDate = [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] objectForKey:kPushesPermissionsAlertNextTimeToShow];
        
        //remind dialog date is later than now or doesn't exist? show remind dialog
        if(!remindDialogDate || [remindDialogDate compare:[NSDate date]] == NSOrderedDescending) {
            MSAlertController*alert = [MSAlertController alertControllerWithTitle:NSLocalizedString(@"Push notifications", @"") message:NSLocalizedString(@"Push notifications are disabled", @"") preferredStyle:MSAlertControllerStyleAlert];
            
            [alert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"Never show this again", @"") style:MSAlertActionStyleDefault handler:^(MSAlertAction *action) {
                [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:kPushesPermissionsAlertNextTimeToShow];
            }]];
             
            [alert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"Remind me later", @"") style:MSAlertActionStyleDefault handler:^(MSAlertAction *action) {
                NSDate *date = [[NSDate date] dateByAddingTimeInterval:24 * 60 * 60 * 3];//remind in 3 days
                [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setObject:date forKey:kPushesPermissionsAlertNextTimeToShow];
            }]];
            
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    }
    else {
        //ios8
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        }
        //ios7
        else {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }
    }
}

@end
