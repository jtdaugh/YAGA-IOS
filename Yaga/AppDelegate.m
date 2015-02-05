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
#import "YAImageCache.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"539cb9ad26d770848f8d5bdd208ab6237a978448"];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];

//#define TESTING_MODE - uncomment that line to cleanup everything
#ifdef TESTING_MODE
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteAllObjects];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
#endif
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
#ifdef TESTING_MODE
    }];
#endif
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[YAServer sharedServer] startMonitoringInternetConnection:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];

        [[YAAssetsCreator sharedCreator] waitForAllOperationsToFinish];
        
        [[YAServerTransactionQueue sharedQueue] waitForAllTransactionsToFinish];
        
        [[YAServer sharedServer] startMonitoringInternetConnection:NO];
        
        [application endBackgroundTask:bgTask];
    });
}

#pragma mark - Push notifications
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    NSLog(@"didRegisterUserNotificationSettings %@", notificationSettings);
    NSLog(@"DEVICE TOKEN: %@", [[NSUserDefaults standardUserDefaults] objectForKey:YA_DEVICE_TOKEN]);
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

#pragma mark - Memory Warning
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [[YAImageCache sharedCache] removeAllObjects];
    
    NSLog(@"%@", application);
}

@end
