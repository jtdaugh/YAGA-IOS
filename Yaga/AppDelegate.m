//
//  AppDelegate.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#define ALREADY_LAUNCHED_KEY @"HasLaunchedOnce"

#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
#import "YAUser.h"

#import <AVFoundation/AVFoundation.h>
#import "YAServer.h"

#import "YAUtils.h"
#import "YAServerTransactionQueue.h"
#import "YAAssetsCreator.h"
#import "YAImageCache.h"

#import "YANotificationView.h"
#import "YAPushNotificationHandler.h"

#import <AddressBookUI/AddressBookUI.h>

#import "AnalyticsKitMixpanelProvider.h"

@interface AppDelegate ()
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, strong) YANotificationView *notificationView;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //analytics
    NSString *mixPanelAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"YAMixPanelAppId"];
    AnalyticsKitMixpanelProvider *mixPanel = [[AnalyticsKitMixpanelProvider alloc] initWithAPIKey:mixPanelAppId];
    [AnalyticsKit initializeLoggers:@[mixPanel]];
    
    // Continue music playback in our app
    NSError *error;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&error];
    if (!success) {
        //Handle error
        DLog(@"%@", [error localizedDescription]);
    } else {
        
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:ALREADY_LAUNCHED_KEY])
    {
       
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ALREADY_LAUNCHED_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // This is the first launch ever
        [AnalyticsKit logEvent:@"Opened App for the first time"];
    }
    
    [Crashlytics startWithAPIKey:@"539cb9ad26d770848f8d5bdd208ab6237a978448"];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];

    // Uncomments for testing tooltips
//    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kFirstVideoRecorded];
//    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kCellWasAlreadyTapped];
    
//#define TESTING_MODE - uncomment that line to cleanup everything

#ifdef TESTING_MODE
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteAllObjects];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[YAUser currentUser] purgeUnusedAssets];
    
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
        
#ifdef TESTING_MODE
    }];
#endif
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [AnalyticsKit logEvent:@"Opened app"];
    
    [[YAServer sharedServer] startMonitoringInternetConnection:YES];
    
    [self endBackgroundTask];
    
    [self removeNotificationsBadge];
}

- (void)removeNotificationsBadge {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    //and clean notifications center
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self beginBackgroundTask];
        
        [[YAAssetsCreator sharedCreator] waitForAllOperationsToFinish];
        
        [[YAServerTransactionQueue sharedQueue] waitForAllTransactionsToFinish];
        
        [[YAServer sharedServer] startMonitoringInternetConnection:NO];
        
        [self endBackgroundTask];
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [AnalyticsKit applicationWillEnterForeground];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [AnalyticsKit applicationDidEnterBackground];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [AnalyticsKit applicationWillTerminate];
}

- (void)beginBackgroundTask {
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
    self.bgTask = UIBackgroundTaskInvalid;
}

#pragma mark - Push notifications
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    DLog(@"didRegisterUserNotificationSettings %@", notificationSettings);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    DLog(@"didRegisterForRemoteNotificationsWithDeviceToken %@", deviceToken);
    
    [[NSUserDefaults standardUserDefaults] setObject:[self deviceTokenFromData:deviceToken] forKey:YA_DEVICE_TOKEN];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    DLog(@"didFailToRegisterForRemoteNotificationsWithError %@", [error localizedDescription]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    DLog(@"didReceiveRemoteNotification %@", userInfo);
    
    if(application.applicationState == UIApplicationStateActive) {
        NSString *alert = userInfo[@"aps"][@"alert"];
        
        self.notificationView = [YANotificationView new];
        [self.notificationView showMessage:alert viewType:YANotificationTypeMessage actionHandler:^{
            [[YAPushNotificationHandler sharedHandler] handlePushWithUserInfo:userInfo];
        }];
    }
    else {
        [[YAPushNotificationHandler sharedHandler] handlePushWithUserInfo:userInfo];
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
    
    DLog(@"applicationDidReceiveMemoryWarning!");
}

@end
