//
//  OnboardingNavigationController.m
//  Pic6
//
//  Created by Raj Vir on 7/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YaOnboardingNavigationController.h"
#import "YAPhoneNumberViewController.h"
#import "YAGroupAddMembersViewController.h"

@interface YaOnboardingNavigationController ()

@end

@implementation YaOnboardingNavigationController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNavigationBarHidden:NO];
    
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationBar setTitleTextAttributes:@{
                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                     NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:20]
                                     }];
    
    [self.navigationBar setShadowImage:[UIImage new]];
    [self.navigationBar setBarTintColor:PRIMARY_COLOR];
    [self.navigationBar setBackgroundImage:[UIImage new]
                       forBarPosition:UIBarPositionAny
                           barMetrics:UIBarMetricsDefault];
//    [self.navigationBar setBackgroundColor:[UIColor blackColor]];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-1000, -1000) forBarMetrics:UIBarMetricsDefault];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
