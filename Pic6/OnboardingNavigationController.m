//
//  OnboardingNavigationController.m
//  Pic6
//
//  Created by Raj Vir on 7/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "OnboardingNavigationController.h"
#import "SplashViewController.h"

@interface OnboardingNavigationController ()

@end

@implementation OnboardingNavigationController

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
    [self setNavigationBarHidden:YES];
    [self setViewControllers:@[[SplashViewController new]]];
    NSLog(@"hello navigation, it's the fuckin martian");
    
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setBarTintColor:TERTIARY_COLOR];
    [self.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationBar setTitleTextAttributes:@{
                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                     NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:20]
                                     }];
    [self.navigationBar setShadowImage:[UIImage new]];
    [self.navigationBar setBackgroundImage:[UIImage new]
                       forBarPosition:UIBarPositionAny
                           barMetrics:UIBarMetricsDefault];
    // Do any additional setup after loading the view.
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
