//
//  MyCrewsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MyCrewsViewController.h"
#import "CNetworking.h"
#import "ElevatorTableView.h"
#import "CreateGroupViewController.h"

@interface MyCrewsViewController ()

@end

@implementation MyCrewsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGFloat width = VIEW_WIDTH * .8;
    
    NSLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.025;
    
    self.cta = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
    [self.cta setText:@"Looks like you're already a part of a group. Pick which one you'd like to go to now."];
    [self.cta setNumberOfLines:4];
    [self.cta setFont:[UIFont fontWithName:BIG_FONT size:24]];
    //    [self.cta setBackgroundColor:PRIMARY_COLOR];
    //    [self.cta sizeToFit];
    [self.cta setTextAlignment:NSTextAlignmentCenter];
    [self.cta setTextColor:[UIColor whiteColor]];
    [self.view addSubview:self.cta];

    origin = [self getNewOrigin:self.cta];
    
    ElevatorTableView *elevator = [[ElevatorTableView alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
    
    [elevator setScrollEnabled:NO];
    [elevator setRowHeight:90];
    [elevator setSeparatorColor:PRIMARY_COLOR];
    [elevator setBackgroundColor:[UIColor clearColor]];
    [elevator setSeparatorInset:UIEdgeInsetsZero];
    [elevator setUserInteractionEnabled:YES];
    
    elevator.delegate = self;

    [self.view addSubview:elevator];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == ([tableView numberOfRowsInSection:0] - 1)){
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"broken"
//                                                        message:@"not working right now"
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
        [self presentViewController:[[CreateGroupViewController alloc] init] animated:YES completion:nil];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            //
        }];
//        [self configureGroupInfo: [[[CNetworking currentUser] groupInfo] objectAtIndex:indexPath.row]];
//        [self closeElevator];
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
