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
#import "YAGridViewController.h"

#import "YAUserPermissions.h"
#import "YAFindGroupsViewConrtoller.h"
#import "YACollectionViewController.h"

#define HEADER_HEIGHT 40
#define FOOTER_HEIGHT 200

@interface YAGroupsViewController ()
@property (nonatomic, strong) RLMResults *groups;
@property (nonatomic, strong) NSDictionary *groupsUpdatedAt;
@property (nonatomic, strong) YAGroup *editingGroup;
@property (nonatomic, strong) YAFindGroupsViewConrtoller *findGroups;
@property (nonatomic) BOOL animatePush;
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
    layout.minimumLineSpacing = 0;
    layout.itemSize = CGSizeMake(VIEW_WIDTH, [GroupsCollectionViewCell cellHeight]);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(leftMargin, origin, VIEW_WIDTH - leftMargin, self.view.bounds.size.height - origin) collectionViewLayout:layout];
    
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.collectionView];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [self.view.backgroundColor copy];
    if (self.yInset) {
        self.collectionView.contentInset = UIEdgeInsetsMake([self.yInset floatValue], 0, 0, 0);
    }
    [self.collectionView registerClass:[GroupsCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"HeaderView"];
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionFooter
                   withReuseIdentifier:@"FooterView"];

    [self setupPullToRefresh];
    
    //notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidChange:)  name:GROUP_DID_CHANGE_NOTIFICATION    object:nil];
    
    //force to open last selected group
    self.animatePush = NO;
    [self groupDidChange:nil];
    [self updateState];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
        [self updateState];
    }];
    if (self.animatePush) {
        [YAUser currentUser].currentGroup = nil;
    }
    self.animatePush = YES;
    
    [self.delegate updateCameraAccessories];
    
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

- (void)groupDidChange:(NSNotification*)notif {
    if ([self.navigationController.visibleViewController isEqual:self]) {
        //open current group if needed
        if([YAUser currentUser].currentGroup) {
            YACollectionViewController *vc = [YACollectionViewController new];
            vc.delegate = self.delegate;
            [self.navigationController pushViewController:vc animated:self.animatePush];
            [self.delegate updateCameraAccessories];
        }
    } else {
        // Grid is already visible, let it push the VC
    }
    self.animatePush = YES;
}

- (void)updateState {
    
    self.groups = [[YAGroup allObjects] sortedResultsUsingProperty:@"updatedAt" ascending:NO];
    
    self.groupsUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT];
    
    [self.collectionView reloadData];
    
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
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self.delegate updateCameraAccessories];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group = self.groups[indexPath.item];
    NSString *membersString = group.membersString;
    
    return [GroupsCollectionViewCell sizeForMembersString:membersString];
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        if (reusableview==nil) {
            reusableview=[[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, HEADER_HEIGHT)];
        }
        CGFloat labelHeight = 36;
        UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake(40, (HEADER_HEIGHT - labelHeight)/2, VIEW_WIDTH, labelHeight)];
        label.text= @"My Groups";
        [label setFont:[UIFont fontWithName:BOLD_FONT size:24]];
        label.textColor = [UIColor lightGrayColor];
        [reusableview addSubview:label];
        return reusableview;
    } else if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        
        if (reusableview==nil) {
            reusableview=[[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, FOOTER_HEIGHT)];
        }
        
        CGSize labelSize = CGSizeMake(VIEW_WIDTH*0.8, 100);
        UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - labelSize.width)/2, 10, labelSize.width, labelSize.height)];
        label.numberOfLines = 3;
        label.font = [UIFont fontWithName:BIG_FONT size:16];
        label.textColor = [UIColor lightGrayColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text=@"Looking for more?\nExplore groups your friends\nare in or create a new group!";
        [reusableview addSubview:label];
        
        CGSize buttonSize = CGSizeMake(140, 50);
        UIButton *findButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/4 - buttonSize.width/2 + 2, FOOTER_HEIGHT - buttonSize.height - 20, buttonSize.width, buttonSize.height)];
        findButton.backgroundColor = [UIColor whiteColor];
        [findButton setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
        findButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
        findButton.layer.borderColor = [PRIMARY_COLOR CGColor];
        findButton.layer.borderWidth = 3;
        findButton.layer.cornerRadius = buttonSize.height/2;
        findButton.layer.masksToBounds = YES;
        [findButton setTitle:@"Find Groups" forState:UIControlStateNormal];
        [reusableview addSubview:findButton];
        
        UIButton *createButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH*3/4 - buttonSize.width/2 - 2, FOOTER_HEIGHT - buttonSize.height - 20, buttonSize.width, buttonSize.height)];
        createButton.backgroundColor = PRIMARY_COLOR;
        [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        createButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
        createButton.layer.borderColor = [PRIMARY_COLOR CGColor];
        createButton.layer.borderWidth = 3;
        createButton.layer.cornerRadius = buttonSize.height/2;
        createButton.layer.masksToBounds = YES;
        [createButton setTitle:@"Create Group" forState:UIControlStateNormal];
        [reusableview addSubview:createButton];
        
        return reusableview;
        
    }
    return nil;
}

// Header size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(VIEW_WIDTH, HEADER_HEIGHT);
}

// Footer size
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(VIEW_WIDTH, FOOTER_HEIGHT);;
}



@end
