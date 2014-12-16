//
//  MyCrewsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MyCrewsViewController.h"
#import "YAUser.h"
#import "GroupListTableView.h"
#import "CreateViewController.h"

@interface MyCrewsViewController ()

@end

@implementation MyCrewsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGFloat width = VIEW_WIDTH * .8;
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    NSLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.025;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
    [titleLabel setText:@"Looks like you're already a part of a group. Pick which one you'd like to go to now."];
    [titleLabel setNumberOfLines:4];
    [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:titleLabel];

    origin = [self getNewOrigin:titleLabel];
    
    GroupListTableView *groupsTableView = [[GroupListTableView alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
    
    [groupsTableView setScrollEnabled:NO];
    [groupsTableView setRowHeight:90];
    [groupsTableView setSeparatorColor:PRIMARY_COLOR];
    [groupsTableView setBackgroundColor:[UIColor clearColor]];
    [groupsTableView setSeparatorInset:UIEdgeInsetsZero];
    [groupsTableView setUserInteractionEnabled:YES];
    
    groupsTableView.delegate = self;

    [self.view addSubview:groupsTableView];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == ([tableView numberOfRowsInSection:0] - 1)){
        [self presentViewController:[[CreateViewController alloc] init] animated:YES completion:nil];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (CGFloat) getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
