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
#import "BLKDelegateSplitter.h"
#import "YABarBehaviorDefiner.h"
#import "YAMainTabBarController.h"

#define FOOTER_HEIGHT (CAMERA_BUTTON_SIZE/2 + 170)
#define HEADER_HEIGHT 40

@interface YAGroupsListViewController ()
@property (nonatomic, strong) MutableOrderedDictionary *groupsDictionary;

@property (nonatomic) BOOL animatePush;

//needed to have pull down to refresh shown for at least 1 second
@property (nonatomic, strong) NSDate *willRefreshDate;
@property (nonatomic) CGFloat topInset;
@property (nonatomic, strong) BLKDelegateSplitter *delegateSplitter;
@property (nonatomic, strong) UIView *noDataView;
@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation YAGroupsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self setupCollectionView];
    
    //notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateState)  name:GROUPS_REFRESHED_NOTIFICATION    object:nil];
    
    //force to open last selected group
    self.animatePush = NO;
    
    [self setupPullToRefresh];

    [self updateState];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupFlexibleBar];

    [self updateState];
    BOOL forceRefresh = YES;
    for (NSArray *array in self.groupsDictionary.allValues) {
        if ([array count]) {
            forceRefresh = NO;
            break;
        }
    }
    [[Mixpanel sharedInstance] track:@"Viewed My Channels"];

    if (forceRefresh) {
        [self showNoDataMessage:NO];
        
        // manual trigger pull to refresh
        [self.collectionView triggerPullToRefresh];
    }
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

- (void)setupFlexibleBar {
    self.delegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.flexibleNavBar.behaviorDefiner];
    self.collectionView.delegate = (id<UICollectionViewDelegate>)self.delegateSplitter;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.flexibleNavBar.maximumBarHeight, 0, 0, 0);
    self.collectionView.alwaysBounceVertical = YES;
    
    self.collectionView.pullToRefreshView.originalTopInset = self.flexibleNavBar.maximumBarHeight;
    self.collectionView.contentOffset = CGPointMake(0, -self.flexibleNavBar.maximumBarHeight);
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
    self.groupsDictionary = [MutableOrderedDictionary new];
    for(NSString *sectionName in self.queriesForSection.allKeys) {
        NSString *query = self.queriesForSection[sectionName];
        RLMResults *queryResult = [[YAGroup allObjects] objectsWhere:query];
        if(queryResult.count) {
            queryResult = [queryResult sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
            [self.groupsDictionary setObject:[self arrayFromRLMResults:queryResult] forKey:sectionName];
        }
    }
 
    [self showNoDataMessage:self.groupsDictionary.count == 0];

    [self.collectionView reloadData];
}

- (NSMutableArray *)arrayFromRLMResults:(RLMResults *)results {
    NSMutableArray *arr = [NSMutableArray array];
    for (id obj in results) {
        [arr addObject:obj];
    }
    return arr;
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

- (YAGroup*)groupAtIndexPath:(NSIndexPath*)indexPath {
    NSArray *groupsForSection = [self.groupsDictionary objectAtIndex:indexPath.section];
    YAGroup *result = [groupsForSection objectAtIndex:indexPath.item];
    
    return result;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.groupsDictionary.count;
       
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *groupsForSection = [self.groupsDictionary objectAtIndex:section];
    return groupsForSection.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    if([[self.groupsDictionary keyAtIndex:section] isEqualToString:kNoSectionName])
        return CGSizeMake(0, 0);
    else
        return CGSizeMake(VIEW_WIDTH, 40);
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
            [findButton addTarget:(YAMainTabBarController *)self.tabBarController  action:@selector(presentFindGroups) forControlEvents:UIControlEventTouchUpInside];

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

        UILabel *label = (UILabel*)[reusableview viewWithTag:100];
        if (!label) {
            label = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, VIEW_WIDTH - 5, 20)];
            label.tag = 100;
            label.textColor = SECONDARY_COLOR;
            label.font = [UIFont fontWithName:BOLD_FONT size:14];
            [reusableview addSubview:label];
        }
        
        label.text = self.groupsDictionary.allKeys[indexPath.section];
        return reusableview;
    }
    return nil;
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GroupsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.group = [self groupAtIndexPath:indexPath];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = [self groupAtIndexPath:indexPath];
    [self.navigationController pushViewController:vc animated:self.animatePush];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group  = [self groupAtIndexPath:indexPath];
    return [GroupsCollectionViewCell sizeForGroup:group];
}

- (void)showNoDataMessage:(BOOL)show {
    if(show && !self.noDataView) {
        CGRect noDataFrame = self.collectionView.bounds;
        noDataFrame.origin.y = -self.collectionView.pullToRefreshView.originalTopInset;
        noDataFrame.size.height -= noDataFrame.origin.y;
        self.noDataView = [[UIView alloc] initWithFrame:noDataFrame];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.noDataView.bounds.size.height/2 - 140, VIEW_WIDTH, 60)];
        label.font = [UIFont fontWithName:BIG_FONT size:24];
        label.text = @"Nothing here yet";
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.textColor = PRIMARY_COLOR;
        [self.noDataView addSubview:label];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:(YAMainTabBarController *)self.tabBarController  action:@selector(presentFindGroups) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(VIEW_WIDTH / 4, self.noDataView.bounds.size.height/2 - 90, VIEW_WIDTH / 2, 40);
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
@end
