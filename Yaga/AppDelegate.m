//
//  AppDelegate.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#define ALREADY_LAUNCHED_KEY @"HasLaunchedOnce"

#import "AppDelegate.h"
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

#import "YAUserPermissions.h"

#import <Parse/Parse.h>
#import <ParseCrashReporting/ParseCrashReporting.h>

#import "YARealmMigrationManager.h"


@interface AppDelegate ()
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, strong) YANotificationView *notificationView;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Relam migration
    YARealmMigrationManager *migrationsMaganaer = [YARealmMigrationManager new];
    [migrationsMaganaer executeMigrations];
    
    //analytics
//    NSString *mixPanelAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"YAMixPanelAppId"];
//    AnalyticsKitMixpanelProvider *mixPanel = [[AnalyticsKitMixpanelProvider alloc] initWithAPIKey:MIXPANEL_TOKEN];
//    [AnalyticsKit initializeLoggers:@[mixPanel]];
    
    // Continue music playback in our app
    NSError *error;
//    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                           error:&error];
    
//    UInt32 doSetProperty = 1;
    
//    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
    
//    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
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
        
        [[Mixpanel sharedInstance] track:@"Opened App for the first time"];
    }
    
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
    
    if([YAUserPermissions pushPermissionsRequestedBefore])
        [YAUserPermissions registerUserNotificationSettings];
    
    [ParseCrashReporting enable];
    [Parse setApplicationId:@"kJ6CSJ9AS0ynVDGniOssk0qtIpBCvy7v5JlUHLx4"
                  clientKey:@"q34FRaKtYSh9VPSsLLM8JWHcSPRGn4X2i6gTJV1v"];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

    // Initialize the library with your
    // Mixpanel project token, MIXPANEL_TOKEN
#ifdef DEBUG
    [Mixpanel sharedInstanceWithToken:MIXPANEL_DEBUG_TOKEN];
#else
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
#endif
    
    if([[YAUser currentUser] loggedIn]){
        [[Mixpanel sharedInstance] identify:[YAUser currentUser].phoneNumber];
        [[Mixpanel sharedInstance].people set:@{@"$phone":[YAUser currentUser].phoneNumber}];
        [[Mixpanel sharedInstance].people set:@{@"$name":[YAUser currentUser].username}];
        NSLog(@"setting people... %@", [YAUser currentUser].username);
    }
    // Later, you can get your instance with
    // Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[Mixpanel sharedInstance] track:@"Opened app"];
//    [AnalyticsKit logEvent:@"Opened app"];
    
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
//    [AnalyticsKit applicationWillEnterForeground];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
//    [AnalyticsKit applicationDidEnterBackground];
}

- (void)applicationWillTerminate:(UIApplication *)application {
//    [AnalyticsKit applicationWillTerminate];
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
