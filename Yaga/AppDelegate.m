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
    
//#warning TESTING REMOVE ALL VIDEOS IN CURRENT GROUP
//    [[RLMRealm defaultRealm] beginWriteTransaction];
//    [[YAUser currentUser].currentGroup.videos removeAllObjects];
//    [[RLMRealm defaultRealm] commitWriteTransaction];
//    
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
}

@end
