//
//  YALatestStreamViewController.m
//  Yaga
//
//  Created by Jesse on 8/18/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YALatestStreamViewController.h"
#import "YAPendingGroupReminderCell.h"
#import "YAGroupGridViewController.h"

@interface YALatestStreamViewController ()

@property (nonatomic, strong) NSArray *groupsWithPendingUnapproved;
@property (nonatomic) BOOL shouldForcePullToRefresh;

@end

static NSString *CellIdentifier = @"PendingCell";

@implementation YALatestStreamViewController

- (void)initStreamGroup {
    RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", kPublicStreamGroupId]];
    if(groups.count == 1) {
        self.group = [groups objectAtIndex:0];
    }
    else {
        [[RLMRealm defaultRealm] beginWriteTransaction];
        self.group = [YAGroup group];
        self.group.serverId = kPublicStreamGroupId;
        self.group.name = NSLocalizedString(@"Latest Videos", @"");
        self.group.streamGroup = YES;
        [[RLMRealm defaultRealm] addObject:self.group];
        [[RLMRealm defaultRealm] commitWriteTransaction];
    }
    self.groupsWithPendingUnapproved = @[];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appBecameActive {
    if (self.collectionView.pullToRefreshView) {
        [self manualTriggerPullToRefresh];
    } else {
        self.shouldForcePullToRefresh = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.shouldForcePullToRefresh)
        [self manualTriggerPullToRefresh];
    self.shouldForcePullToRefresh = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updatePending];
}

- (void)updatePending {
    NSMutableArray *pendingGroups = [NSMutableArray new];
    RLMResults *groups = [YAGroup objectsWhere:@"pendingPostsCount != 0"];
    for(YAGroup *group in groups) {
        if (!(group.amMember && group.publicGroup)) {
            continue;
        }
        
        [pendingGroups addObject:group];
    }
    BOOL reload = (([pendingGroups count] && ![self.groupsWithPendingUnapproved count]) || (![pendingGroups count] && [self.groupsWithPendingUnapproved count]));
    self.groupsWithPendingUnapproved = [NSArray arrayWithArray:pendingGroups];
    if (reload) {
        [self.collectionView reloadData];
    }
}

// Hijack some collection view delegate methods to insert the pending rows
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // return a clickable group pending cell
        YAGroup *group = [self.groupsWithPendingUnapproved objectAtIndex:indexPath.item];
        YAPendingGroupReminderCell *cell;
        
        @try { // Try catch in obj c LOL
             cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        }
        @catch (NSException *exception) {
            [self.collectionView registerClass:[YAPendingGroupReminderCell class] forCellWithReuseIdentifier:CellIdentifier];
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"Pending videos in %@", group.name];
        
        // Hide separator for last cell.
        cell.separatorView.hidden = (indexPath.row == [self.groupsWithPendingUnapproved count] - 1);
        cell.boldSeparatorView.hidden = (indexPath.row != [self.groupsWithPendingUnapproved count] - 1);
        return cell;
        
    } else {
        return [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return section == 0 ? 0.0 : 1.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return section == 0 ? 0.0 : 1.0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.groupsWithPendingUnapproved count];
    } else {
        return [super collectionView:collectionView numberOfItemsInSection:0];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        YAGroup *group = [self.groupsWithPendingUnapproved objectAtIndex:indexPath.item];
        [self openGroup:group];
    } else {
        [super collectionView:collectionView didSelectItemAtIndexPath:indexPath]; // Don't need to manipulate indexPath.section
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return CGSizeMake(VIEW_WIDTH, kReminderCellHeight);
    } else {
        return [super collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
    }
}

- (void)openGroup:(YAGroup *)group {
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = group;
    vc.openStraightToPendingSection = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)performAdditionalRefreshRequests {
    [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
        [self updatePending];
    }];
}

- (NSInteger)gifGridSection {
    return 1;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

@end
