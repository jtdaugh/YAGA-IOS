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
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *noDataView;
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
    self.flexibleNavBar.maximumBarHeight = 110;
    self.flexibleNavBar.minimumBarHeight = 20;

    [self.flexibleNavBar.rightBarButton addTarget:(YAMainTabBarController *)self.tabBarController action:@selector(presentCreateGroup) forControlEvents:UIControlEventTouchUpInside];
    self.flexibleNavBar.behaviorDefiner = [YABarBehaviorDefiner new];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];
    
    self.delegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.flexibleNavBar.behaviorDefiner];
    self.collectionView.delegate = (id<UICollectionViewDelegate>)self.delegateSplitter;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.flexibleNavBar.maximumBarHeight, 0, 0, 0);
    self.collectionView.alwaysBounceVertical = YES;
    [self.view addSubview:self.flexibleNavBar];
    
    //important to reassign initial pull to refresh inset, there is no way to recreate it
    self.collectionView.pullToRefreshView.originalTopInset = self.collectionView.contentInset.top;
    
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
//    [self.collectionView registerClass:[UICollectionReusableView class]
//            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
//                   withReuseIdentifier:@"HeaderView"];

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

    BOOL noData = self.hostingGoups.count == 0 && self.followingGroups.count == 0 && self.privateGroups.count == 0;
    BOOL noDataForSelectedSegment = self.segmentedControl.selectedSegmentIndex == 0 ?
                                                                self.hostingGoups.count == 0 :
                                                                self.followingGroups.count == 0 && self.privateGroups.count == 0;
    
    [self showNoDataMessage:noData || noDataForSelectedSegment];
    
    [self showSegmentedControl:!noData];

    [self.collectionView reloadData];
}

- (NSMutableArray *)arrayFromRLMResults:(RLMResults *)results {
    NSMutableArray *arr = [NSMutableArray array];
    for (id obj in results) {
        [arr addObject:obj];
    }
    return arr;
}

- (NSMutableArray *)arrayForSelectedSegment {
//    if (section == 0) {
//        if (self.hostingGoups.count) return self.hostingGoups;
//        if (self.privateGroups.count) return self.privateGroups;
//        return self.followingGroups;
//    } else if (section == 1) {
//        if (self.hostingGoups.count && self.privateGroups.count) return self.privateGroups;
//        return self.followingGroups;
//    }
//    return self.followingGroups;
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0: {
            return self.hostingGoups;
        }
        case 1: {
            NSMutableArray *privateAndFollowing = [NSMutableArray arrayWithArray:self.privateGroups];
            [privateAndFollowing addObjectsFromArray:self.followingGroups];
            return privateAndFollowing;
        }
        default:
            return nil;
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
//    NSUInteger result = self.hostingGoups.count ? 1 : 0;
//    result += self.privateGroups.count ? 1 : 0;
//    result += self.followingGroups.count ? 1 : 0;
//    
//    return result;
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
        return [self arrayForSelectedSegment].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GroupsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.group = [[self arrayForSelectedSegment] objectAtIndex:indexPath.item];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    YAGroup *group = [[self arrayForSelectedSegment] objectAtIndex:indexPath.item];
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = group;
    [self.navigationController pushViewController:vc animated:self.animatePush];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group  = [[self arrayForSelectedSegment] objectAtIndex:indexPath.item];
    return [GroupsCollectionViewCell sizeForGroup:group];
}


//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
//           viewForSupplementaryElementOfKind:(NSString *)kind
//                                 atIndexPath:(NSIndexPath *)indexPath {
//    if (kind == UICollectionElementKindSectionFooter) {
//        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
//        if (![reusableview.subviews count]) {
//            CGSize labelSize = CGSizeMake(VIEW_WIDTH*0.8, 70);
//            UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - labelSize.width)/2, 20, labelSize.width, labelSize.height)];
//            label.numberOfLines = 3;
//            label.font = [UIFont fontWithName:BIG_FONT size:16];
//            label.textColor = [UIColor lightGrayColor];
//            label.textAlignment = NSTextAlignmentCenter;
//            label.text=@"Looking for more?\nExplore popular channels\nor create a new one!";
//            [reusableview addSubview:label];
//            
//            CGSize buttonSize = CGSizeMake(VIEW_WIDTH/2 - 30, 50);
//            UIButton *findButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/4 - buttonSize.width/2 + 2, FOOTER_HEIGHT - CAMERA_BUTTON_SIZE/2 - buttonSize.height - 20, buttonSize.width, buttonSize.height)];
//            findButton.backgroundColor = [UIColor whiteColor];
//            [findButton setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
//            findButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
//            findButton.layer.borderColor = [PRIMARY_COLOR CGColor];
//            findButton.layer.borderWidth = 3;
//            findButton.layer.cornerRadius = buttonSize.height/2;
//            findButton.layer.masksToBounds = YES;
//            [findButton setTitle:@"Explore" forState:UIControlStateNormal];
//            [findButton addTarget:self action:@selector(findGroupsPressed) forControlEvents:UIControlEventTouchUpInside];
//
//            [reusableview addSubview:findButton];
//            
//            UIButton *createButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH*3/4 - buttonSize.width/2 - 2, FOOTER_HEIGHT - CAMERA_BUTTON_SIZE/2 - buttonSize.height - 20, buttonSize.width, buttonSize.height)];
//            createButton.backgroundColor = PRIMARY_COLOR;
//            [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            createButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
//            createButton.layer.borderColor = [PRIMARY_COLOR CGColor];
//            createButton.layer.borderWidth = 3;
//            createButton.layer.cornerRadius = buttonSize.height/2;
//            createButton.layer.masksToBounds = YES;
//            [createButton setTitle:@"New Channel" forState:UIControlStateNormal];
//            [createButton addTarget:(YAMainTabBarController *)self.tabBarController  action:@selector(presentCreateGroup) forControlEvents:UIControlEventTouchUpInside];
//            [reusableview addSubview:createButton];
//        }
//        return reusableview;
//        
//    } else if (kind == UICollectionElementKindSectionHeader) {
//        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
//        if (![reusableview.subviews count]) {
//            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, VIEW_WIDTH - 5, 20)];
//            [reusableview addSubview:label];
//        }
//        
//        NSArray *arr = [self arrayForSegment:indexPath.section];
//        reusableview.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
//        
//        UILabel *label = nil;
//        for (UIView *subview in reusableview.subviews) {
//            if ([subview isKindOfClass:[UILabel class]]) {
//                label = (UILabel *)subview;
//                break;
//            }
//        }
//
//        label.font = [UIFont fontWithName:BOLD_FONT size:14];
//        if (arr == self.hostingGoups) {
//            label.textColor = HOSTING_GROUP_COLOR;
//            label.text = @"HOSTING";
//        } else if (arr == self.privateGroups) {
//            label.textColor = PRIVATE_GROUP_COLOR;
//            label.text = @"PRIVATE";
//        } else {
//            label.textColor = PUBLIC_GROUP_COLOR;
//            label.text = @"FOLLOWING";
//        }
//        return reusableview;
//    }
//    return nil;
//}

//- (CGSize)collectionView:(UICollectionView *)collectionView
//                  layout:(UICollectionViewLayout *)collectionViewLayout
//referenceSizeForHeaderInSection:(NSInteger)section {
//    return CGSizeMake(VIEW_WIDTH, 40);
//}

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

#pragma mark - UISegmentedControl

- (void)showSegmentedControl:(BOOL)show {
    if(show && !self.segmentedControl) {
        //segmented control
        self.segmentedControl = [UISegmentedControl new];
        self.segmentedControl.tintColor = [UIColor whiteColor];
        
        [self.segmentedControl insertSegmentWithTitle:@"Hosting" atIndex:0 animated:NO];
        [self.segmentedControl insertSegmentWithTitle:@"All" atIndex:1 animated:NO];
        self.segmentedControl.selectedSegmentIndex = 0;
        BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        expanded.frame = CGRectMake(VIEW_WIDTH/4, self.flexibleNavBar.frame.size.height, VIEW_WIDTH/2, 30);
        expanded.alpha = 1;
        [self.segmentedControl addLayoutAttributes:expanded forProgress:0.0];
        BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        collapsed.frame = CGRectMake(VIEW_WIDTH/4, 0, VIEW_WIDTH/2, 0);
        collapsed.alpha = -1; //to hide it even quicker
        [self.segmentedControl addLayoutAttributes:collapsed forProgress:1.0];
        [self.segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
        [self.flexibleNavBar addSubview:self.segmentedControl];
        self.flexibleNavBar.maximumBarHeight = 110;
    }
    else if(!show) {
        [self.segmentedControl removeFromSuperview];
        self.segmentedControl = nil;
        self.flexibleNavBar.maximumBarHeight = 66;
    }
    
    //adjust collection view and pulltorefresh
    self.collectionView.contentInset = UIEdgeInsetsMake(self.flexibleNavBar.maximumBarHeight, 0, 0, 0);
    self.collectionView.pullToRefreshView.originalTopInset = self.flexibleNavBar.maximumBarHeight;
}

- (void)showNoDataMessage:(BOOL)show {
    if(show && !self.noDataView) {
        self.noDataView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.noDataView.bounds.size.height/2 - 40, VIEW_WIDTH, 60)];
        label.font = [UIFont fontWithName:BIG_FONT size:24];
        label.text = @"Nothing here yet";
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.textColor = PRIMARY_COLOR;
        [self.noDataView addSubview:label];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(findGroupsPressed) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(VIEW_WIDTH / 4, self.noDataView.bounds.size.height/2 + 20, VIEW_WIDTH / 2, 40);
        [button setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];

        button.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
        [button setTitle:@"Tap to explore" forState:UIControlStateNormal];
        [self.noDataView addSubview:button];
        
        [self.collectionView addSubview:self.noDataView];
        
    }
    else if(!show) {
        [self.noDataView removeFromSuperview];
        self.noDataView = nil;
    }
}

- (void)segmentedControlChanged:(UISegmentedControl*)segmentedControl {
    [self updateState];
}

@end
