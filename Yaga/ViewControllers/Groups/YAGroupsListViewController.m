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

#import "UIScrollView+SVPullToRefresh.h"
#import "YAPullToRefreshLoadingView.h"
#import "NameGroupViewController.h"

#import "YAFindGroupsViewConrtoller.h"
#import "YAGifGridViewController.h"

#define FOOTER_HEIGHT (CAMERA_BUTTON_SIZE/2 + 170)

@interface YAGroupsListViewController ()
@property (nonatomic, strong) RLMResults *groups;
@property (nonatomic, strong) YAGroup *editingGroup;
@property (nonatomic, strong) YAFindGroupsViewConrtoller *findGroups;
@property (nonatomic) BOOL animatePush;

//needed to have pull down to refresh shown for at least 1 second
@property (nonatomic, strong) NSDate *willRefreshDate;
@property (nonatomic) CGFloat topInset;

@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation YAGroupsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self.view setBackgroundColor:[UIColor colorWithWhite:0.97 alpha:1]];

    [self setupCollectionView];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationItem.title = @"Groups";
    

    //notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidChange:)  name:GROUP_DID_CHANGE_NOTIFICATION    object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateState)  name:GROUPS_REFRESHED_NOTIFICATION    object:nil];
    
    //force to open last selected group
    self.animatePush = NO;
    [self groupDidChange:nil];
    
    [self setupBarItems];
    
    [self updateState];
}

- (void)setupBarItems {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Find" style:UIBarButtonItemStylePlain target:self action:@selector(findGroupsPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createGroupPressed)];
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
    
    [self setupPullToRefresh];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.animatePush) {
        // Need to set group to nil when we swipe back to this screen.
        // The animate push hack is because sometimes -viewDidAppear was getting called
        // even when we forced the gif collection view push in -viewDidLoad
        [YAUser currentUser].currentGroup = nil;
    }
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

- (void)groupDidChange:(NSNotification*)notif {
    [self.collectionView.pullToRefreshView stopAnimating];
    
    if ([self.navigationController.topViewController isEqual:self]) {
        //open current group if needed
        if([YAUser currentUser].currentGroup) {
            YAGifGridViewController *vc = [YAGifGridViewController new];
            [self.navigationController pushViewController:vc animated:self.animatePush];
        }
    } else {
        // Grid is already visible, let it reload
    }
    self.animatePush = YES;
}

- (void)updateState {
//    self.groups = [[YAGroup allObjects] sortedResultsUsingProperty:@"updatedAt" ascending:NO];
    
    self.groups = [[YAGroup allObjects] sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"publicGroup" ascending:NO], [RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    
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

    cell.publicGroup = group.publicGroup;
    
    cell.showUpdatedIndicator = group.hasUnviewedVideos;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    YAGroup *group = self.groups[indexPath.item];
    [YAUser currentUser].currentGroup = group;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group = self.groups[indexPath.item];
    NSString *membersString = group.membersString;
    
    return [GroupsCollectionViewCell sizeForMembersString:membersString];
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        
        if (reusableview==nil) {
            reusableview=[[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, FOOTER_HEIGHT)];
        }
        
        CGSize labelSize = CGSizeMake(VIEW_WIDTH*0.8, 70);
        UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - labelSize.width)/2, 20, labelSize.width, labelSize.height)];
        label.numberOfLines = 3;
        label.font = [UIFont fontWithName:BIG_FONT size:16];
        label.textColor = [UIColor lightGrayColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text=@"Looking for more?\nExplore groups your friends\nare in or create a new group!";
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
        [findButton setTitle:@"Find Groups" forState:UIControlStateNormal];
        [findButton addTarget:self action:@selector(findCellPressed:) forControlEvents:UIControlEventTouchUpInside];

        [reusableview addSubview:findButton];
        
        UIButton *createButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH*3/4 - buttonSize.width/2 - 2, FOOTER_HEIGHT - CAMERA_BUTTON_SIZE/2 - buttonSize.height - 20, buttonSize.width, buttonSize.height)];
        createButton.backgroundColor = PRIMARY_COLOR;
        [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        createButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
        createButton.layer.borderColor = [PRIMARY_COLOR CGColor];
        createButton.layer.borderWidth = 3;
        createButton.layer.cornerRadius = buttonSize.height/2;
        createButton.layer.masksToBounds = YES;
        [createButton setTitle:@"Create Group" forState:UIControlStateNormal];
        [createButton addTarget:self action:@selector(createCellPressed:) forControlEvents:UIControlEventTouchUpInside];
        [reusableview addSubview:createButton];
        
        return reusableview;
        
    }
    return nil;
}

// Footer size
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(VIEW_WIDTH, FOOTER_HEIGHT);;
}

@end