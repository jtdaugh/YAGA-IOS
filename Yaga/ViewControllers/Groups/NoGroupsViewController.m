//
//  NoGroupsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/13/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "NoGroupsViewController.h"
#import "AddMembersViewController.h"
#import "YAAuthManager.h"

@interface NoGroupsViewController ()

@end

@implementation NoGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"";
    
    [self.navigationController.navigationItem setHidesBackButton:YES];
    
    CGFloat width = VIEW_WIDTH * .8;
    [self.view setBackgroundColor:[UIColor blackColor]];

    CGFloat origin = VIEW_HEIGHT *.025;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
    [titleLabel setText:@"Looks like you're not in any groups 😔. Create a group now to start using Yaga"];
    [titleLabel setNumberOfLines:3];
    [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];

    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:titleLabel];
    
    origin = [self getNewOrigin:titleLabel];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    UIButton *nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [nextButton setBackgroundColor:PRIMARY_COLOR];
    [nextButton setTitle:@"Create Group" forState:UIControlStateNormal];
    [nextButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:nextButton];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)nextScreen {
    [self performSegueWithIdentifier:@"AddMembers" sender:self];
}

@end
