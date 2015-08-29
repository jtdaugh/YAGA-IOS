//
//  YAChannelsViewController.m
//  Yaga
//
//  Created by valentinkovalski on 8/28/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAChannelsViewController.h"
#import "YAStandardFlexibleHeightBar.h"
#import "YAMainTabBarController.h"
#import "YABarBehaviorDefiner.h"
#import "YAFindGroupsViewConrtoller.h"
#import "YAGroupsListViewController.h"
#import "OrderedDictionary.h"
#import "BLKDelegateSplitter.h"

@interface YAChannelsViewController ()

@property (nonatomic, strong) UIView *noDataView;
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, strong) UIViewController *currentViewController;
@end

@implementation YAChannelsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _flexibleNavBar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
    [self.flexibleNavBar.titleButton setTitle:@"Channels" forState:UIControlStateNormal];

    [self.flexibleNavBar.rightBarButton setTitle:@"New" forState:UIControlStateNormal];
    
    [self.flexibleNavBar.rightBarButton addTarget:(YAMainTabBarController *)self.tabBarController action:@selector(presentCreateGroup) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.flexibleNavBar];
    
    //segmented control
    _segmentedControl = [UISegmentedControl new];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    
    [self.segmentedControl insertSegmentWithTitle:@"Suggested" atIndex:0 animated:NO];
    [self.segmentedControl insertSegmentWithTitle:@"My Channels" atIndex:1 animated:NO];
    [self.segmentedControl insertSegmentWithTitle:@"Following" atIndex:2 animated:NO];
    
    // Suggested + Hosting + Following + Private
    self.segmentedControl.selectedSegmentIndex = 0;
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = CGRectMake(20, self.flexibleNavBar.frame.size.height, VIEW_WIDTH - 40, 30);
    expanded.alpha = 1;
    [self.segmentedControl addLayoutAttributes:expanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    collapsed.frame = CGRectMake(20, 0, VIEW_WIDTH - 40, 0);
    collapsed.alpha = -1; //to hide it even quicker
    [self.segmentedControl addLayoutAttributes:collapsed forProgress:1.0];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    [self.flexibleNavBar addSubview:self.segmentedControl];
    self.flexibleNavBar.maximumBarHeight = 110;
    
    YAFindGroupsViewConrtoller *suggested = [YAFindGroupsViewConrtoller new];
    suggested.flexibleNavBar = self.flexibleNavBar;
    
    YAGroupsListViewController *myChannels = [YAGroupsListViewController new];
    myChannels.queriesForSection = [MutableOrderedDictionary new];
    [myChannels.queriesForSection setObject:@"publicGroup = 1 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup'" forKey:@"PUBLIC"];
    [myChannels.queriesForSection setObject:@"publicGroup = 0 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup'" forKey:@"PRIVATE"];
    
    myChannels.flexibleNavBar = self.flexibleNavBar;
    
    YAGroupsListViewController *following = [YAGroupsListViewController new];
    following.queriesForSection = [MutableOrderedDictionary new];
    [following.queriesForSection setObject:@"amFollowing = 1 && streamGroup = 0 && name != 'EmptyGroup'" forKey:kNoSectionName];
    following.flexibleNavBar = self.flexibleNavBar;
    
    self.viewControllers = @[suggested, myChannels, following];
    
    self.currentViewController = suggested;
    
    [self addChildViewController:self.currentViewController];
    
    [self.view addSubview:self.currentViewController.view];
    [self.view bringSubviewToFront:self.flexibleNavBar];
}

- (void)segmentedControlChanged:(UISegmentedControl*)segmentedControl {
    UIViewController *vc = self.viewControllers[segmentedControl.selectedSegmentIndex];

    vc.view.alpha = 0;
    
    [self addChildViewController:vc];
    [self.currentViewController.view removeFromSuperview];
    vc.view.frame = self.view.bounds;
    [self.view addSubview:vc.view];
    [self.view bringSubviewToFront:self.flexibleNavBar];
    [vc didMoveToParentViewController:self];
    [self.currentViewController removeFromParentViewController];
    self.currentViewController = vc;
    self.navigationItem.title = vc.title;
    
    [UIView animateWithDuration:0.1 animations:^{
        vc.view.alpha = 1;
    }];
}


@end
