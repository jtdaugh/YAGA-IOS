//
//  YAStreamsViewController.m
//  Yaga
//
//  Created by valentinkovalski on 8/31/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAStreamsViewController.h"
#import "YALatestStreamViewController.h"
#import "YAMyStreamViewController.h"
#import "SquareCashStyleBehaviorDefiner.h"

@interface YAStreamsViewController ()
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, strong) UIViewController *currentViewController;

@end

@implementation YAStreamsViewController

- (void)setupNavbar {
    [self.flexibleNavBar.titleButton setTitle:@"" forState:UIControlStateNormal];
    
    self.flexibleNavBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = CGRectMake(20, 30, VIEW_WIDTH - 40, 30);
    expanded.alpha = 1;
    [self.segmentedControl addLayoutAttributes:expanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    collapsed.frame = CGRectMake(20, 0, VIEW_WIDTH - 40, 0);
    collapsed.alpha = -1; //to hide it even quicker
    [self.segmentedControl addLayoutAttributes:collapsed forProgress:1.0];
    
    self.flexibleNavBar.maximumBarHeight = 70;
}

- (void)setupSegments {
    [self.segmentedControl insertSegmentWithTitle:@"Latest Videos" atIndex:0 animated:NO];
    [self.segmentedControl insertSegmentWithTitle:@"My Videos" atIndex:1 animated:NO];
    self.segmentedControl.selectedSegmentIndex = 0;
    
    YALatestStreamViewController *latestStream = [YALatestStreamViewController new];
    latestStream.flexibleNavBar = self.flexibleNavBar;
    
    YAMyStreamViewController *myStream = [YAMyStreamViewController new];
    myStream.flexibleNavBar = self.flexibleNavBar;

    self.viewControllers = @[latestStream, myStream];
}
@end
