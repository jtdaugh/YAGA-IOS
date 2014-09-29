//
//  AppDelegate.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "GridViewController.h"
#import "OnboardingNavigationController.h"
#import "NetworkingTestViewController.h"
#import <Crashlytics/Crashlytics.h>
#import <Parse/Parse.h>


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [Firebase setOption:@"persistence" to:@YES];
    
    [Crashlytics startWithAPIKey:@"539cb9ad26d770848f8d5bdd208ab6237a978448"];
    
    [Parse setApplicationId:@"fMGmvOq0PhaTtIIJe371Ra5nMuv7T0Ot1ulNx2oi"
                  clientKey:@"Av1qzrSKppbGK4JAM3mEuksQKp9xeovLJQnROEWN"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
//    AnalyticsKitMixpanelProvider *mixpanel = [[AnalyticsKitMixpanelProvider alloc] initWithAPIKey:MIXPANEL_TOKEN];
//    
//    [AnalyticsKit initializeLoggers:@[mixpanel]];
    
    [self setupAudio];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    // Your don't need specify window color if you add root controller, you will not see window because root controller will be above window.
    // self.window.backgroundColor = [UIColor whiteColor];
    
    if(0){
        OnboardingNavigationController *vc = [[OnboardingNavigationController alloc] init];
        self.window.rootViewController = vc;
    } else {
        if(0){
            NetworkingTestViewController *vc = [[NetworkingTestViewController alloc] init];
            self.window.rootViewController = vc;
        } else {
            GridViewController *vc = [[GridViewController alloc] init];
            self.window.rootViewController = vc;
            
        }
        
    }
    
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
  
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)setupAudio {
    NSError *error = nil;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        
    if(error){
        NSLog(@"audio session error: %@", error);
    }
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
//    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
//    UInt32 doSetProperty = 1;
//    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
//    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];

}

@end
