//
//  AppDelegate.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
#import "YAUser.h"

#import <AVFoundation/AVFoundation.h>
#import "YAServer.h"

#import "YAUtils.h"
#import "YAServerTransactionQueue.h"
#import "YAAssetsCreator.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"539cb9ad26d770848f8d5bdd208ab6237a978448"];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    //#warning TESTING REMOVE ALL GROUPS
    //    [[RLMRealm defaultRealm] beginWriteTransaction];
    //    [[RLMRealm defaultRealm] deleteObjects:[YAGroup allObjects]];
    //    [[RLMRealm defaultRealm] commitWriteTransaction];
    //
    //#warning TESTING REMOVE ALL VIDEOS IN CURRENT GROUP
    //    [[RLMRealm defaultRealm] beginWriteTransaction];
    //    [[YAUser currentUser].currentGroup.videos removeAllObjects];
    //    [[RLMRealm defaultRealm] commitWriteTransaction];
    ////
    //    #warning TESTING REMOVE ALL VIDEOS IN TRANSATION QUEUE
    //    [[YAServerTransactionQueue sharedQueue] clearTransactionQueue];
    
    NSString *identifier;
    if([[YAUser currentUser] loggedIn] && [YAUser currentUser].currentGroup) {
        identifier = @"LoggedInUserNavigationController";
    }
    else if(![[YAUser currentUser] loggedIn]) {
        identifier = @"OnboardingNavigationController";
    }
    else if([[YAUser currentUser] loggedIn] && ![YAUser currentUser].currentGroup && ![YAGroup allObjects].count) {
        identifier = @"OnboardingNoGroupsNavigationController";
    }
    else if([[YAUser currentUser] loggedIn] && ![YAUser currentUser].currentGroup && [YAGroup allObjects].count) {
        identifier = @"OnboardingSelectGroupNavigationController";
    }
    
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    self.window.rootViewController = viewController;
    
    [self.window makeKeyAndVisible];
    
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    [application registerForRemoteNotifications];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[YAServer sharedServer] startMonitoringInternetConnection:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[YAServer sharedServer] startMonitoringInternetConnection:NO];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        
        // Wait until the pending operations finish
        [[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
        [[YAAssetsCreator sharedCreator] waitForAllOperationsToFinish];
        
        [application endBackgroundTask: bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

#pragma mark - Push notifications
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    NSLog(@"didRegisterUserNotificationSettings %@", notificationSettings);
    
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken %@", [self deviceTokenFromData:deviceToken]);
    
    [[NSUserDefaults standardUserDefaults] setObject:[self deviceTokenFromData:deviceToken] forKey:YA_DEVICE_TOKEN];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@", [error localizedDescription]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification %@", userInfo);
    [YAUtils showNotification:[NSString stringWithFormat:@"Push: %@", [userInfo description]] type:AZNotificationTypeMessage];
    
    //for tests
    NSString *testAlert = @"New video at group ";
    if([userInfo[@"aps"][@"alert"] rangeOfString:testAlert].location != NSNotFound) {
        NSString *groupId = [[userInfo[@"aps"][@"alert"] stringByReplacingOccurrencesOfString:testAlert withString:@""] stringByReplacingOccurrencesOfString:@"!" withString:@""];
        NSLog(@"group id from push %@", groupId);
        
        if([groupId isEqualToString:[YAUser currentUser].currentGroup.serverId]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_GROUP_NOTIFICATION object:[YAUser currentUser].currentGroup];
        }
    }
}


#pragma mark - utils
- (NSString *)deviceTokenFromData:(NSData *)data {
    NSString *token = [NSString stringWithFormat:@"%@", [data description]];
    
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    return token;
}

@end
