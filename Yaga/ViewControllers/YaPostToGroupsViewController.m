//
//  YAPostToGroupsViewController.m
//  Yaga
//
//  Created by valentinkovalski on 8/14/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAPostToGroupsViewController.h"
#import "UIImage+Color.h"
#import "YAGroupAddMembersViewController.h"
//#import "YASloppyNavigationController.h"
#import "YAGroup.h"
#import "YAPostGroupCell.h"
#import "YAServer.h"
#import "YAAssetsCreator.h"
#import "YAStandardFlexibleHeightBar.h"
//#import "YAMainTabBarController.h"
//#import "YAPopoverView.h"

@interface YAPostToGroupsViewController ()
@property (nonatomic, strong) NSMutableArray *groups;

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
    
    YAStandardFlexibleHeightBar *navBar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
    [navBar.titleButton setTitle:@"Choose Recipients" forState:UIControlStateNormal];
    [navBar.leftBarButton setImage:self.video.group ? [UIImage imageNamed:@"X"] : [[UIImage imageNamed:@"Back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
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
    
    RLMResults *groups = self.video.group ? [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId != '%@'", self.video.group.serverId]] : [YAGroup allObjects];
    RLMResults *groupsSorted = [groups sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    
    self.groups = [self arrayFromRLMResults:groupsSorted];
    
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

- (void)createChatFinishedWithGroup:(YAGroup *)group wasPreexisting:(BOOL)preexisting {
    if (preexisting) {
        // find index
        int index = -1;
        for (int i = 0; i < self.groups.count; i++) {
            YAGroup *groupAtIndex = self.groups[i];
            if ([group.serverId isEqualToString:groupAtIndex.serverId]) {
                index = i;
                break;
            }
        }
        if (index != -1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self showHidePostMessage];
            return;
        }
    }
    NSIndexPath *newIndex;
    [self.groups insertObject:group atIndex:0];
    newIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[newIndex] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView selectRowAtIndexPath:newIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self showHidePostMessage];
}

- (void)backPressed {
    if (self.video.group) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YAPostGroupCell *cell = (YAPostGroupCell*)[tableView dequeueReusableCellWithIdentifier:kCellId forIndexPath:indexPath];
    
    YAGroup *group = [self.groups objectAtIndex:indexPath.item];
    
    cell.textLabel.text = group.members.count == 1 ? [[group.members firstObject] displayName] : group.name;
    [cell setSelectionColor:PRIMARY_COLOR];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[Mixpanel sharedInstance] track:@"Selected Group"];
    
//    if ([self arrayForSection:indexPath.section] == self.followingGroups) {
//        if (![YAUtils hasSeenPendingApprovalMessage]) {
//            [YAUtils setSeenPendingApprovalMessage];
//            [self showFirstPendingApprovalSelectionPopover];
//        }
//    }
    [self showHidePostMessage];
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showHidePostMessage];
}

#pragma mark - Table View Delegate


#pragma mark - Private
- (void)addNewGroup {
    YAGroupAddMembersViewController *newGroupVC = [YAGroupAddMembersViewController new];
    newGroupVC.inCreateGroupFlow = YES;
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newGroupVC];
    navVC.navigationBarHidden = YES;
    
    [[Mixpanel sharedInstance] track:@"Create New Chat after post"];
    
    [self presentViewController:navVC animated:YES completion:nil];
}

- (void)showHidePostMessage {
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        
        if(selectedIndexPaths.count > 0) {
            NSString *pluralSuffix = selectedIndexPaths.count == 1 ? @" >" : @"s >";
            NSString *sendTitle = [NSString stringWithFormat:@"Send to %lu chat%@", selectedIndexPaths.count, pluralSuffix];
            
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
    NSMutableArray *groupIds = [NSMutableArray new];
    
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        [groups addObject:[self.groups objectAtIndex:indexPath.item]];
        [groupIds addObject:((YAGroup *)[self.groups objectAtIndex:indexPath.item]).serverId];
    }
    if ([groups count]) {
        if (self.video.group) {
            [[YAServer sharedServer] copyVideo:self.video toGroupsWithIds:groupIds withCompletion:^(id response, NSError *error) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }];
        } else {
            [[YAServer sharedServer] postUngroupedVideo:self.video toGroups:groups];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
//    if(groups.count) {
//        [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:
//         self.settings[@"videoUrl"]
//                                                    withCaptionText:self.settings[@"captionText"]
//                                                                  x:[self.settings[@"captionX"] floatValue]
//                                                                  y:[self.settings[@"captionY"]  floatValue]
//                                                              scale:[self.settings[@"captionScale"] floatValue] rotation:[self.settings[@"captionRotation"] floatValue]
//                                                        addToGroups:groups];
    
        [[Mixpanel sharedInstance] track:@"Video posted"];
        
//        [((YAMainTabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController) returnToStreamViewController];
        [self dismissViewControllerAnimated:YES completion:nil];
    
//    [[Mixpanel sharedInstance] track:@"Posted to channels" properties:@{@"count": [NSNumber numberWithInteger:self.tableView.indexPathsForSelectedRows.count]}];
}


- (BOOL)blockCameraPresentationOnBackground {
    return YES;
}


//- (void)showFirstPendingApprovalSelectionPopover {
//    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_PENDING_APPROVAL_POST_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_PENDING_APPROVAL_POST_BODY", @"") dismissText:@"Got it" addToView:self.view] show];
//}

@end
