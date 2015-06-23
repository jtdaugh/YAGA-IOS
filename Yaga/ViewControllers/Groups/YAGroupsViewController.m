//
//  MyCrewsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//


#import "YAGroupsViewController.h"
#import "YAUser.h"
#import "YAUtils.h"

#import "GroupsCollectionViewCell.h"
#import "YAServer.h"
#import "UIImage+Color.h"
#import "YAServer.h"

#import "YAGroupAddMembersViewController.h"
#import "YAGroupOptionsViewController.h"

#import "UIScrollView+SVPullToRefresh.h"
#import "YAPullToRefreshLoadingView.h"
#import "NameGroupViewController.h"
#import "GridViewController.h"

#import "YAUserPermissions.h"
#import "YAFindGroupsViewConrtoller.h"
#import "GridViewController.h"
#import "YACollectionViewController.h"

@interface YAGroupsViewController ()
@property (nonatomic, strong) RLMResults *groups;
@property (nonatomic, strong) UIButton *createGroupButton;
@property (nonatomic, strong) NSDictionary *groupsUpdatedAt;
@property (nonatomic, strong) YAGroup *editingGroup;
@property (nonatomic, strong) YAFindGroupsViewConrtoller *findGroups;

//needed to have pull down to refresh shown for at least 1 second
@property (nonatomic, strong) NSDate *willRefreshDate;

@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation YAGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES];
    
    
    CGFloat origin = 0;
    CGFloat leftMargin = 0;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 20;
    layout.itemSize = CGSizeMake(VIEW_WIDTH, [GroupsCollectionViewCell cellHeight]);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(leftMargin, origin, VIEW_WIDTH - leftMargin, self.view.bounds.size.height - origin) collectionViewLayout:layout];
    
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.collectionView];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [self.view.backgroundColor copy];
    self.collectionView.contentInset = UIEdgeInsetsMake(VIEW_HEIGHT/2 + 2 - CAMERA_MARGIN, 0, 0, 0);

    [self.collectionView registerClass:[GroupsCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
    
    [self setupPullToRefresh];
    
    //notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateState];
    
    [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
        [self updateState];
    }];
}

- (void)setupPullToRefresh {
    //pull to refresh
    __weak typeof(self) weakSelf = self;
    
    [self.collectionView addPullToRefreshWithActionHandler:^{
        weakSelf.willRefreshDate = [NSDate date];
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
//            [weakSelf updateState];
            [weakSelf delayedHidePullToRefresh];
//            [weakSelf.collectionView.pullToRefreshView stopAnimating];
        }];
    }];
    
    //    self.collectionView.pullToRefreshView.
    
    YAPullToRefreshLoadingView *loadingView = [[YAPullToRefreshLoadingView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/10, 0, VIEW_WIDTH-VIEW_WIDTH/10/2, self.collectionView.pullToRefreshView.bounds.size.height)];
    
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateLoading];
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateStopped];
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateTriggered];
}

- (void)delayedHidePullToRefresh {
    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:self.willRefreshDate];
    
    double hidePullToRefreshAfter = 1 - seconds;
    if(hidePullToRefreshAfter < 0)
        hidePullToRefreshAfter = 0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(hidePullToRefreshAfter * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView.pullToRefreshView stopAnimating];
        [self updateState];
    });
}

- (void)groupDidRefresh:(NSNotification*)notif {
    [self updateState];
}

- (void)updateState {
    
    self.groups = [[YAGroup allObjects] sortedResultsUsingProperty:@"updatedAt" ascending:NO];
    
    self.groupsUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT];
    
    [self.collectionView reloadData];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [YAUser currentUser].currentGroup = nil;
    
    if(![YAUserPermissions pushPermissionsRequestedBefore])
        [YAUserPermissions registerUserNotificationSettings];
    
    //load phonebook if it wasn't done before
    if(![YAUser currentUser].phonebook.count) {
        [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSArray *contacts) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                });
            }
        } excludingPhoneNumbers:nil];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if([touch.view isKindOfClass:[UICollectionViewCell class]])
        return NO;
    // UITableViewCellContentView => UITableViewCell
    if([touch.view.superview isKindOfClass:[UICollectionViewCell class]])
        return NO;
    // UITableViewCellContentView => UITableViewCellScrollView => UITableViewCell
    if([touch.view.superview.superview isKindOfClass:[UICollectionViewCell class]])
        return NO;
    
    if([touch.view isKindOfClass:[UIButton class]])
        return NO;
    
    return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
 
    [self.delegate scrollViewDidScroll];

}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GroupsCollectionViewCell *cell;
    
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    YAGroup *group = [self.groups objectAtIndex:indexPath.item];
    
    cell.groupName = group.name;
    cell.membersString = group.membersString;
    
    cell.muted = group.muted;
    
    NSDate *localGroupUpdateDate = [self.groupsUpdatedAt objectForKey:group.localId];
    if(!localGroupUpdateDate || [group.updatedAt compare:localGroupUpdateDate] == NSOrderedDescending) {
        cell.showUpdatedIndicator = YES;
    }
    else {
        cell.showUpdatedIndicator = NO;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group = self.groups[indexPath.item];
    [YAUser currentUser].currentGroup = group;
    YACollectionViewController *vc = [YACollectionViewController new];
    vc.delegate = self.delegate;
    [self.navigationController pushViewController:vc animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group = self.groups[indexPath.item];
    NSString *membersString = group.membersString;
    
    return [GroupsCollectionViewCell sizeForMembersString:membersString];
}

- (void)createGroup {
    [self.navigationController pushViewController:[NameGroupViewController new] animated:YES];
}

- (void)segmentedControlValueChanged:(UISegmentedControl*)segmentedControl {
    if(segmentedControl.selectedSegmentIndex == 1) {
        [[YAServer sharedServer] searchGroupsWithCompletion:^(id response, NSError *error) {
            if(!error) {
                self.findGroups = [YAFindGroupsViewConrtoller new];
                self.findGroups.groupsDataArray = (NSArray*)response;
                [self addChildViewController:self.findGroups];
                self.findGroups.view.frame = self.view.bounds;
                [self.view addSubview:self.findGroups.view];
            }
            else {
                DLog(@"Failed to search groups");
                segmentedControl.selectedSegmentIndex = 0;
            }
        }];
    }
    else {
        [self.findGroups removeFromParentViewController];
        [self.findGroups.view removeFromSuperview];
        self.findGroups = nil;
    }
}

@end
