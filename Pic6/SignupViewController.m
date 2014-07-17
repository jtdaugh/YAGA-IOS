//
//  SignupViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "SignupViewController.h"
#import "GridViewController.h"
#import "AppDelegate.h"

@interface SignupViewController ()

@end

@implementation SignupViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor greenColor]];
    [self setTitle:@"Sign Up"];
    
    UIButton *exit = [[UIButton alloc] initWithFrame:CGRectMake(0, 40, VIEW_WIDTH, 200)];
    [exit setBackgroundColor:[UIColor redColor]];
    [exit addTarget:self action:@selector(exit) forControlEvents:UIControlEventTouchUpInside];
    [exit setTitle:@"Exit to main app" forState:UIControlStateNormal];
    [exit.titleLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:exit];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)exit {
    GridViewController *grid = [[GridViewController alloc] init];
    grid.onboarding = [NSNumber numberWithBool:YES];
    [self.navigationController pushViewController:grid animated:YES];
    
//    [self.navigationController popToViewController:grid animated:YES];
//    self.navigationController.v
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
