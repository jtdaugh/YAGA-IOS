//
//  NoGroupsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/13/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "NoGroupsViewController.h"
#import "AddMembersViewController.h"

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
    
    self.cta = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
    [self.cta setText:@"Looks like you're not in any groups 😔. Create a group now to start using Yaga"];
    [self.cta setNumberOfLines:3];
    [self.cta setFont:[UIFont fontWithName:BIG_FONT size:24]];
    //    [self.cta setBackgroundColor:PRIMARY_COLOR];
    //    [self.cta sizeToFit];
    [self.cta setTextAlignment:NSTextAlignmentCenter];
    [self.cta setTextColor:[UIColor whiteColor]];
    [self.view addSubview:self.cta];
    
    origin = [self getNewOrigin:self.cta];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.next = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.next setBackgroundColor:PRIMARY_COLOR];
    [self.next setTitle:@"Create Group" forState:UIControlStateNormal];
    [self.next.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.next addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    
//    self.next.layer.shadowColor = [UIColor whiteColor].CGColor;
//    self.next.layer.shadowOpacity = 1.0;
//    self.next.layer.shadowRadius = 0;
//    self.next.layer.shadowOffset = CGSizeMake(4.0f, 4.0f);
    
    [self.view addSubview:self.next];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat) getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)nextScreen {
    AddMembersViewController *vc = [[AddMembersViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    NSLog(@"watup");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
