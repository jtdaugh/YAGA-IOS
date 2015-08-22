//
//  YAPostToGroupsViewController.m
//  Yaga
//
//  Created by valentinkovalski on 8/14/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAPostToGroupsViewController.h"
#import "UIImage+Color.h"
#import "NameGroupViewController.h"
#import "YASloppyNavigationController.h"
#import "YAGroup.h"
#import "YAPostGroupCell.h"
#import "YAAssetsCreator.h"
#import "YAStandardFlexibleHeightBar.h"
#import "YAMainTabBarController.h"
#import "YAPopoverView.h"

@interface YAPostToGroupsViewController ()
@property (nonatomic, strong) NSMutableArray *hostingGoups;
@property (nonatomic, strong) NSMutableArray *privateGroups;
@property (nonatomic, strong) NSMutableArray *followingGroups;

@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) UITableView *tableView;
@end

#define kGroupRowHeight 60
#define kSendButtonHeight 70

#define kCellId @"groupCell"
@implementation YAPostToGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"Post To Channel", @"");
    
    YAStandardFlexibleHeightBar *navBar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
    navBar.titleLabel.text = @"Select Channels";
    [navBar.leftBarButton setImage:[[UIImage imageNamed:@"Back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [navBar.rightBarButton setImage:[[UIImage imageNamed:@"Add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [navBar.leftBarButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    [navBar.rightBarButton addTarget:self action:@selector(addNewGroup) forControlEvents:UIControlEventTouchUpInside];

    
    CGRect frame = self.view.bounds;
    self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(navBar.frame.size.height, 0, kSendButtonHeight, 0);
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[YAPostGroupCell class] forCellReuseIdentifier:kCellId];
    self.tableView.rowHeight = 60;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.editing = NO;
    [self.view addSubview:self.tableView];
    [self.view addSubview:navBar]; // Need the navBar on top of tableView

    RLMResults *hostGroups = [[YAGroup allObjects] objectsWhere:@"publicGroup = 1 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup'"];
    RLMResults *privateGroups = [[YAGroup allObjects] objectsWhere:@"publicGroup = 0 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup'"];
    RLMResults *followGroups = [[YAGroup allObjects] objectsWhere:@"amFollowing = 1 && streamGroup = 0 && name != 'EmptyGroup'"];
    
    RLMResults *hostingSorted = [hostGroups sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    RLMResults *privateSorted = [privateGroups sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    RLMResults *followSorted = [followGroups sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    
    self.hostingGoups = [self arrayFromRLMResults:hostingSorted];
    self.followingGroups = [self arrayFromRLMResults:followSorted];
    self.privateGroups = [self arrayFromRLMResults:privateSorted];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, kSendButtonHeight);
    [self.sendButton setBackgroundColor:[UIColor colorWithRed:5.0/255.0 green:135.0/255.0 blue:195.0/255.0 alpha:1.0]];

    [self.view addSubview:self.sendButton];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:30];
    
    UIView *blackButtonLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.sendButton.bounds.size.width, 2)];
    blackButtonLine.backgroundColor = [UIColor blackColor];
    [self.sendButton addSubview:blackButtonLine];
    
    //[self.sendButton setImage:[UIImage imageNamed:@"Disclosure"] forState:UIControlStateNormal];
    //[self.sendButton setImageEdgeInsets:UIEdgeInsetsMake(0, self.view.bounds.size.width - 50, 0, 0)];
}

- (NSMutableArray *)arrayFromRLMResults:(RLMResults *)results {
    NSMutableArray *arr = [NSMutableArray array];
    for (id obj in results) {
        [arr addObject:obj];
    }
    return arr;
}

- (NSMutableArray *)arrayForSection:(NSUInteger)section {
    if (section == 0) {
        if (self.hostingGoups.count) return self.hostingGoups;
        if (self.privateGroups.count) return self.privateGroups;
        return self.followingGroups;
    } else if (section == 1) {
        if (self.hostingGoups.count && self.privateGroups.count) return self.privateGroups;
        return self.followingGroups;
    }
    return self.followingGroups;
}

- (void)addNewlyCreatedGroupToList:(YAGroup *)group {
    NSIndexPath *newIndex;
    if (group.publicGroup) {
        [self.hostingGoups insertObject:group atIndex:0];
        newIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    } else {
        [self.privateGroups insertObject:group atIndex:0];
        newIndex = [NSIndexPath indexPathForRow:0 inSection:self.hostingGoups.count ? 1 : 0];
    }
    [self.tableView insertRowsAtIndexPaths:@[newIndex] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView selectRowAtIndexPath:newIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self showHidePostMessage];
}

- (void)backPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger result = self.hostingGoups.count ? 1 : 0;
    result += self.privateGroups.count ? 1 : 0;
    result += self.followingGroups.count ? 1 : 0;
    
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self arrayForSection:section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSArray *arr = [self arrayForSection:section];
    UIView *result = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 40)];
    result.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 15, VIEW_WIDTH - 5, 20)];
    label.font = [UIFont fontWithName:BOLD_FONT size:14];
    if (arr == self.hostingGoups) {
        label.textColor = HOSTING_GROUP_COLOR;
        label.text = @"HOSTING";
    } else if (arr == self.privateGroups) {
        label.textColor = PRIVATE_GROUP_COLOR;
        label.text = @"PRIVATE";
    } else {
        label.textColor = PUBLIC_GROUP_COLOR;
        label.text = @"FOLLOWING (Pending approval from Host)";
    }
    [result addSubview:label];
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YAPostGroupCell *cell = (YAPostGroupCell*)[tableView dequeueReusableCellWithIdentifier:kCellId forIndexPath:indexPath];
    
    YAGroup *group = [[self arrayForSection:indexPath.section] objectAtIndex:indexPath.item];
    
    cell.textLabel.text = group.name;
    [cell setSelectionColor:group.amMember ? (group.publicGroup ? HOSTING_GROUP_COLOR :  PRIVATE_GROUP_COLOR) : PUBLIC_GROUP_COLOR];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[Mixpanel sharedInstance] track:@"Selected Group"];

    if ([self arrayForSection:indexPath.section] == self.followingGroups) {
        if (![YAUtils hasSeenPendingApprovalMessage]) {
            [YAUtils setSeenPendingApprovalMessage];
            [self showFirstPendingApprovalSelectionPopover];
        }
    }
    [self showHidePostMessage];
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showHidePostMessage];
}

#pragma mark - Table View Delegate


#pragma mark - Private
- (void)addNewGroup {
    NameGroupViewController *nameGroupVC = [NameGroupViewController new];
    YASloppyNavigationController *navVC = [[YASloppyNavigationController alloc] initWithRootViewController:nameGroupVC];
    [[Mixpanel sharedInstance] track:@"Create New Channel after post"];

    [self presentViewController:navVC animated:YES completion:nil];
}

- (void)showHidePostMessage {
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];

    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        
        if(selectedIndexPaths.count > 0) {
            NSString *pluralSuffix = selectedIndexPaths.count == 1 ? @" >" : @"s >";
            NSString *sendTitle = [NSString stringWithFormat:@"Send to %lu channel%@", selectedIndexPaths.count, pluralSuffix];
            
            [self.sendButton setTitle:sendTitle forState:UIControlStateNormal];
            self.sendButton.frame = CGRectMake(0, self.view.bounds.size.height - kSendButtonHeight, self.view.bounds.size.width, kSendButtonHeight);
        }
        else {
            self.sendButton.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, kSendButtonHeight);
        }
        
    }completion:^(BOOL finished) {
        
    }];
}

- (void)sendButtonTapped {
    NSMutableArray *groups = [NSMutableArray new];
    
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        [groups addObject:[[self arrayForSection:indexPath.section] objectAtIndex:indexPath.item]];
    }
    if(groups.count) {
        [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:
                                                    self.settings[@"videoUrl"]
                                                    withCaptionText:self.settings[@"captionText"]
                                                                  x:[self.settings[@"captionX"] floatValue]
                                                                  y:[self.settings[@"captionY"]  floatValue]
                                                              scale:[self.settings[@"captionScale"] floatValue] rotation:[self.settings[@"captionRotation"] floatValue]
                                                        addToGroups:groups];
        
        [[Mixpanel sharedInstance] track:@"Video posted"];
        
        [((YAMainTabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController) returnToStreamViewController];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [[Mixpanel sharedInstance] track:@"Posted to channels" properties:@{@"count": [NSNumber numberWithInteger:self.tableView.indexPathsForSelectedRows.count]}];

}

- (BOOL)blockCameraPresentationOnBackground {
    return YES;
}


- (void)showFirstPendingApprovalSelectionPopover {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_PENDING_APPROVAL_POST_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_PENDING_APPROVAL_POST_BODY", @"") dismissText:@"Got it" addToView:self.view] show];
}

@end
