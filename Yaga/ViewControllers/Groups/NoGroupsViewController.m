//
//  NoGroupsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/13/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "NoGroupsViewController.h"
#import "YAGroupAddMembersViewController.h"
#import "YAServer.h"
#import <ClusterPrePermissions.h>

@interface NoGroupsViewController ()

@end

@implementation NoGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"";
    
    [self.navigationController.navigationItem setHidesBackButton:YES];
    
    CGFloat width = VIEW_WIDTH * .8;
    [self.view setBackgroundColor:PRIMARY_COLOR];

    CGFloat origin = VIEW_HEIGHT *.025;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
    [titleLabel setText:@"Looks like you're not in any groups 😔. Create a group to start using Yaga"];
    [titleLabel setNumberOfLines:3];
    [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];

    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:titleLabel];
    
    origin = [self getNewOrigin:titleLabel];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    UIButton *nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [nextButton setBackgroundColor:[UIColor whiteColor]];
    [nextButton setTitle:@"Create Group" forState:UIControlStateNormal];
    [nextButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    nextButton.layer.cornerRadius = 8.0;
    nextButton.layer.masksToBounds = YES;
    [nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:nextButton];

}

- (void)viewDidAppear:(BOOL)animated {
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    
//    ClusterPrePermissions *permissions = [ClusterPrePermissions sharedPermissions];
//    [permissions
//     showPushNotificationPermissionsWithType:ClusterPushNotificationTypeAlert | ClusterPushNotificationTypeSound | ClusterPushNotificationTypeBadge
//     title:NSLocalizedString(@"Enable push notifications?", nil)
//     message:NSLocalizedString(@"Yaga wants to send you push notifications", nil)
//     denyButtonTitle:@"Not Now"
//     grantButtonTitle:@"Enable"
//     completionHandler:^(BOOL hasPermission, ClusterDialogResult userDialogResult, ClusterDialogResult systemDialogResult) {
//         
//     }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)nextScreen {
    [AnalyticsKit logEvent:@"Onboarding create group"];
    [self performSegueWithIdentifier:@"NoGroupsNameGroup" sender:self];
}

@end
