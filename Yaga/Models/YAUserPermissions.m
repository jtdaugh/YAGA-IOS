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
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPushesPermissionsRequestedBefore];
}

+ (void)registerUserNotificationSettings {
    //permission dialog was shown and user denied?
    BOOL iosDialogShown = [self pushPermissionsRequestedBefore];
    
    if(iosDialogShown && [[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone) {
        NSDate *remindDialogDate = [[NSUserDefaults standardUserDefaults] objectForKey:kPushesPermissionsAlertNextTimeToShow];
        
        //remind dialog date is later than now or doesn't exist? show remind dialog
        if(!remindDialogDate || [remindDialogDate compare:[NSDate date]] == NSOrderedDescending) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Push notifications", @"") message:NSLocalizedString(@"Push notifications are disabled", @"") preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Never show this again", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:kPushesPermissionsAlertNextTimeToShow];
            }]];
             
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remind me later", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSDate *date = [[NSDate date] dateByAddingTimeInterval:24 * 60 * 60 * 3];//remind in 3 days
                [[NSUserDefaults standardUserDefaults] setObject:date forKey:kPushesPermissionsAlertNextTimeToShow];
            }]];
            
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    }
    else {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPushesPermissionsRequestedBefore];
    }
}

@end
