//
//  MyCrewsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//


#import "YAGroupsListViewController.h"
#import "YAUser.h"
#import "YAUtils.h"

#import "GroupsCollectionViewCell.h"
#import "YAServer.h"
#import "UIImage+Color.h"
#import "YAServer.h"

#import "YAGroupAddMembersViewController.h"
#import "YAGroupOptionsViewController.h"
#import "YACreateGroupNavigationController.h"

#import "UIScrollView+SVPullToRefresh.h"
#import "YAPullToRefreshLoadingView.h"
#import "NameGroupViewController.h"

#import "YASloppyNavigationController.h"
#import "YAGroupGridViewController.h"
#import "YAMainTabBarController.h"
#import "YAStandardFlexibleHeightBar.h"
#import "BLKDelegateSplitter.h"
#import "YABarBehaviorDefiner.h"

#define FOOTER_HEIGHT (CAMERA_BUTTON_SIZE/2 + 170)
#define HEADER_HEIGHT 40

@interface YAGroupsListViewController ()
@property (nonatomic, strong) NSMutableArray *hostingGoups;
@property (nonatomic, strong) NSMutableArray *privateGroups;
@property (nonatomic, strong) NSMutableArray *followingGroups;

@property (nonatomic) BOOL animatePush;

//needed to have pull down to refresh shown for at least 1 second
@property (nonatomic, strong) NSDate *willRefreshDate;
@property (nonatomic) CGFloat topInset;
@property (nonatomic, strong) YAStandardFlexibleHeightBar *flexibleNavBar;
@property (nonatomic, strong) BLKDelegateSplitter *delegateSplitter;

@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation YAGroupsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self setupCollectionView];
    self.flexibleNavBar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
    [self.flexibleNavBar.titleButton setTitle:@"My Channels" forState:UIControlStateNormal];
    [self.flexibleNavBar.leftBarButton setTitle:@"Explore" forState:UIControlStateNormal];
    [self.flexibleNavBar.leftBarButton addTarget:self action:@selector(findGroupsPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.flexibleNavBar.rightBarButton setImage:[[UIImage imageNamed:@"Add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

    [self.flexibleNavBar.rightBarButton addTarget:(YAMainTabBarController *)self.tabBarController action:@selector(presentCreateGroup) forControlEvents:UIControlEventTouchUpInside];
    self.flexibleNavBar.behaviorDefiner = [YABarBehaviorDefiner new];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];

    self.delegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.flexibleNavBar.behaviorDefiner];
    self.collectionView.delegate = (id<UICollectionViewDelegate>)self.delegateSplitter;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.flexibleNavBar.frame.size.height, 0, 0, 0);
    self.collectionView.alwaysBounceVertical = YES;
    [self.view addSubview:self.flexibleNavBar];

    //notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateState)  name:GROUPS_REFRESHED_NOTIFICATION    object:nil];
    
    //force to open last selected group
    self.animatePush = NO;
    
    [self setupPullToRefresh];

    [self updateState];
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateState];
    if (![self.collectionView numberOfSections]) {
        [self.collectionView triggerPullToRefresh];
    }
    [super viewWillAppear:animated];
    [[Mixpanel sharedInstance] track:@"Viewed My Channels"];

}

- (void)findGroupsPressed {
    self.tabBarController.selectedIndex = 1;
}

- (void)setupCollectionView {
    if (self.collectionView) {
        [self.collectionView removeFromSuperview];
    }
    CGFloat origin = 0;
    CGFloat leftMargin = 0;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.itemSize = CGSizeMake(VIEW_WIDTH, [GroupsCollectionViewCell cellHeight]);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(leftMargin, origin, VIEW_WIDTH - leftMargin, self.view.bounds.size.height - origin) collectionViewLayout:layout];
    
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.collectionView];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [self.view.backgroundColor copy];
    self.collectionView.contentInset = UIEdgeInsetsMake(self.topInset, 0, 0, 0);
    [self.collectionView registerClass:[GroupsCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionFooter
                   withReuseIdentifier:@"FooterView"];
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"HeaderView"];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.animatePush = YES;
    
    //load phonebook if it wasn't done before
    if(![YAUser currentUser].phonebook.count) {
        [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSArray *contacts, BOOL sentToServer) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                });
            }
        } excludingPhoneNumbers:nil];
    }
}

- (void)setupPullToRefresh {
    //pull to refresh
    __weak typeof(self) weakSelf = self;
    
    [self.collectionView addPullToRefreshWithActionHandler:^{
        weakSelf.willRefreshDate = [NSDate date];
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
            [weakSelf delayedHidePullToRefresh];
        }];
    }];
    
    
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
    RLMResults *hostGroups = [[YAGroup allObjects] objectsWhere:@"publicGroup = 1 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup'"];
    RLMResults *privateGroups = [[YAGroup allObjects] objectsWhere:@"publicGroup = 0 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup'"];
    RLMResults *followGroups = [[YAGroup allObjects] objectsWhere:@"amFollowing = 1 && streamGroup = 0 && name != 'EmptyGroup'"];
    
    RLMResults *hostingSorted = [hostGroups sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    RLMResults *privateSorted = [privateGroups sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    RLMResults *followSorted = [followGroups sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    
    self.hostingGoups = [self arrayFromRLMResults:hostingSorted];
    self.followingGroups = [self arrayFromRLMResults:followSorted];
    self.privateGroups = [self arrayFromRLMResults:privateSorted];

    [self.collectionView reloadData];
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSUInteger result = self.hostingGoups.count ? 1 : 0;
    result += self.privateGroups.count ? 1 : 0;
    result += self.followingGroups.count ? 1 : 0;
    
    return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
        return [self arrayForSection:section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GroupsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.group = [[self arrayForSection:indexPath.section] objectAtIndex:indexPath.item];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    YAGroup *group = [[self arrayForSection:indexPath.section] objectAtIndex:indexPath.item];
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = group;
    [self.navigationController pushViewController:vc animated:self.animatePush];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group  = [[self arrayForSection:indexPath.section] objectAtIndex:indexPath.item];
    return [GroupsCollectionViewCell sizeForGroup:group];
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        if (![reusableview.subviews count]) {
            CGSize labelSize = CGSizeMake(VIEW_WIDTH*0.8, 70);
            UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - labelSize.width)/2, 20, labelSize.width, labelSize.height)];
            label.numberOfLines = 3;
            label.font = [UIFont fontWithName:BIG_FONT size:16];
            label.textColor = [UIColor lightGrayColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.text=@"Looking for more?\nExplore popular channels\nor create a new one!";
            [reusableview addSubview:label];
            
            CGSize buttonSize = CGSizeMake(VIEW_WIDTH/2 - 30, 50);
            UIButton *findButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/4 - buttonSize.width/2 + 2, FOOTER_HEIGHT - CAMERA_BUTTON_SIZE/2 - buttonSize.height - 20, buttonSize.width, buttonSize.height)];
            findButton.backgroundColor = [UIColor whiteColor];
            [findButton setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
            findButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
            findButton.layer.borderColor = [PRIMARY_COLOR CGColor];
            findButton.layer.borderWidth = 3;
            findButton.layer.cornerRadius = buttonSize.height/2;
            findButton.layer.masksToBounds = YES;
            [findButton setTitle:@"Explore" forState:UIControlStateNormal];
            [findButton addTarget:self action:@selector(findGroupsPressed) forControlEvents:UIControlEventTouchUpInside];

            [reusableview addSubview:findButton];
            
            UIButton *createButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH*3/4 - buttonSize.width/2 - 2, FOOTER_HEIGHT - CAMERA_BUTTON_SIZE/2 - buttonSize.height - 20, buttonSize.width, buttonSize.height)];
            createButton.backgroundColor = PRIMARY_COLOR;
            [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            createButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
            createButton.layer.borderColor = [PRIMARY_COLOR CGColor];
            createButton.layer.borderWidth = 3;
            createButton.layer.cornerRadius = buttonSize.height/2;
            createButton.layer.masksToBounds = YES;
            [createButton setTitle:@"New Channel" forState:UIControlStateNormal];
            [createButton addTarget:(YAMainTabBarController *)self.tabBarController  action:@selector(presentCreateGroup) forControlEvents:UIControlEventTouchUpInside];
            [reusableview addSubview:createButton];
        }
        return reusableview;
        
    } else if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        if (![reusableview.subviews count]) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, VIEW_WIDTH - 5, 20)];
            [reusableview addSubview:label];
        }
        
        NSArray *arr = [self arrayForSection:indexPath.section];
        reusableview.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
        
        UILabel *label = nil;
        for (UIView *subview in reusableview.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                label = (UILabel *)subview;
                break;
            }
        }

        label.font = [UIFont fontWithName:BOLD_FONT size:14];
        if (arr == self.hostingGoups) {
            label.textColor = HOSTING_GROUP_COLOR;
            label.text = @"HOSTING";
        } else if (arr == self.privateGroups) {
            label.textColor = PRIVATE_GROUP_COLOR;
            label.text = @"PRIVATE";
        } else {
            label.textColor = PUBLIC_GROUP_COLOR;
            label.text = @"FOLLOWING";
        }
        return reusableview;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(VIEW_WIDTH, 40);
}

// Footer size
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section {
    if (section == [collectionView numberOfSections] - 1) {
        // Only want a footer for the last section
        return CGSizeMake(VIEW_WIDTH, FOOTER_HEIGHT);
    }
    return CGSizeZero;
}

@end
