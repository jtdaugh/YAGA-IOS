
//
//  YAFindGroupsViewConrtoller.m
//
//
//  Created by valentinkovalski on 6/18/15.
//
//

#import "YAFindGroupsViewConrtoller.h"
#import "GroupsTableViewCell.h"
#import "YAGroup.h"
#import "YAServer.h"
#import "YAUser.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "YAPullToRefreshLoadingView.h"
#import "NameGroupViewController.h"
#import "YAPopoverView.h"
#import "YAUserPermissions.h"
#import "YAMainTabBarController.h"
#import "YAStandardFlexibleHeightBar.h"
#import "BLKDelegateSplitter.h"
#import "SquareCashStyleBehaviorDefiner.h"
#import "YAGroupGridViewController.h"

#define headerAndAccessoryColor SECONDARY_COLOR
#define kAccessoryButtonWidth 70

@interface YAFindGroupsViewConrtoller () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSArray *groupsDataArray;
@property (nonatomic, strong) NSMutableSet *pendingRequestsInProgress;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIActivityIndicatorView *searchActivity;
@property (nonatomic, strong) UIActivityIndicatorView *searchTableActivity;
@property (nonatomic, strong) UILabel *searchResultLabel;

@property (atomic, assign) BOOL groupsListLoaded;
@property (atomic, assign) BOOL findGroupsFinished;

@property (nonatomic, strong) YAStandardFlexibleHeightBar *flexibleNavBar;
@property (nonatomic, strong) BLKDelegateSplitter *delegateSplitter;

@property (nonatomic, strong) NSArray *featuredGroups;
@property (nonatomic, strong) NSArray *suggestedGroups;

@end

static NSString *CellIdentifier = @"GroupsCell";
static NSString *HeaderIdentifier = @"GroupsHeader";

@implementation YAFindGroupsViewConrtoller

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationItem.title = NSLocalizedString(@"Explore Channels", @"");
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [self.view.backgroundColor copy];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView registerClass:[GroupsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    [self setupFlexibleNavBar];
    
    [self setupPullToRefresh];
    
    _groupsDataArray = [[NSUserDefaults standardUserDefaults] objectForKey:kFindGroupsCachedResponse];
    
    [self filterAndReload:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![self.groupsDataArray count] && ![self.searchBar.text length]) {
        // Don't auto trigger this if already populated, shouldn't change that often
        [self.tableView triggerPullToRefresh];
    }
    
    [[Mixpanel sharedInstance] track:@"Viewed Explore"];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)accessoryButtonTapped:(UIButton*)sender event:(id)event{
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        return;
    }
    
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    
    if(!self.pendingRequestsInProgress)
        self.pendingRequestsInProgress = [NSMutableSet set];
    
    NSDictionary *groupData = [self groupDataAtIndexPath:indexPath];
    [self.pendingRequestsInProgress addObject:groupData[YA_RESPONSE_ID]];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    responseBlock block = ^(id response, NSError *error) {
        BOOL private = [groupData[YA_RESPONSE_PRIVATE] boolValue];
        [self.pendingRequestsInProgress removeObject:groupData[YA_RESPONSE_ID]];
        if(!error) {
            
            NSMutableArray *upatedDataArray = [NSMutableArray arrayWithArray:self.groupsDataArray];

            if (private) {
                NSMutableDictionary *joinedGroupData = [NSMutableDictionary dictionaryWithDictionary:groupData];
                [joinedGroupData setObject:[NSNumber numberWithBool:YES] forKey:YA_RESPONSE_PENDING_MEMBERS];
                [upatedDataArray replaceObjectAtIndex:[upatedDataArray indexOfObject:groupData] withObject:joinedGroupData];
                [[NSUserDefaults standardUserDefaults] setObject:upatedDataArray forKey:kFindGroupsCachedResponse];
            } else {
                [upatedDataArray removeObject:groupData];
                [[NSUserDefaults standardUserDefaults] setObject:upatedDataArray forKey:kFindGroupsCachedResponse];
            }
            
            self.groupsDataArray = upatedDataArray;
            
            [self filterAndReload:NO];

            if (!private && !error) {
                // Need to delete section if now empty
                if ([self.tableView numberOfRowsInSection:indexPath.section] == 1)
                    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                else
                    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            if(![groupData[YA_RESPONSE_PRIVATE] boolValue]){
                [YAUtils showHudWithText:[NSString stringWithFormat:@"Following %@!", groupData[YA_RESPONSE_NAME]]];
            }
        }
        else {
            DLog(@"Can't send request to join channel");
        }
    };
    
    //adding [YAUser currentUser].username to pending members, not making another call to server
    if ([groupData[YA_RESPONSE_PRIVATE] boolValue]) {
        [[YAServer sharedServer] joinGroupWithId:groupData[YA_RESPONSE_ID] withCompletion:block];
        [[Mixpanel sharedInstance] track:@"Channel Requested to join"];
    } else {
        [[YAServer sharedServer] followGroupWithId:groupData[YA_RESPONSE_ID] withCompletion:block];
        [[Mixpanel sharedInstance] track:@"Channel Followed"];
    }
}

- (void)createGroupButtonTapped:(UIButton*)sender {
    __weak id presentingController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        [presentingController pushViewController:[NameGroupViewController new] animated:YES];
    }];
}

- (void)setupPullToRefresh {
    //pull to refresh
    __weak typeof(self) weakSelf = self;
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        if(![YAServer sharedServer].serverUp) {
            [weakSelf.tableView.pullToRefreshView stopAnimating];
            [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
            return;
        }
        
        if(!weakSelf.groupsDataArray.count)
            [weakSelf filterAndReload:YES];
        
        void (^discoverGroupsBlock)(void) = ^{
            [[YAServer sharedServer] discoverGroupsWithCompletion:^(id response, NSError *error) {
                [weakSelf.tableView.pullToRefreshView stopAnimating];
                
                if(error) {
                    [YAUtils showHudWithText:NSLocalizedString(@"Failed to discover groups", @"")];
                }
                else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        weakSelf.groupsDataArray = [YAUtils readableGroupsArrayFromResponse:response];
                        [[NSUserDefaults standardUserDefaults] setObject:weakSelf.groupsDataArray forKey:kFindGroupsCachedResponse];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf filterAndReload:YES];
                        });
                    });
                }
            }];
        };
        
        NSDate *lastYagaUsersRequested = [[NSUserDefaults standardUserDefaults] objectForKey:kLastYagaUsersRequestDate];
        if(!lastYagaUsersRequested) {
            //force upload phone contacts in case there is no information on server yet otherwise searchGroups will return nothgin
            [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSMutableArray *contacts, BOOL sentToServer) {
                discoverGroupsBlock();
            } excludingPhoneNumbers:nil];
        }
        else {
            discoverGroupsBlock();
        }
        
    }];
    
    YAPullToRefreshLoadingView *loadingView = [[YAPullToRefreshLoadingView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/10, 0, VIEW_WIDTH-VIEW_WIDTH/10/2, self.tableView.pullToRefreshView.bounds.size.height)];
    
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateLoading];
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateStopped];
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateTriggered];
}

- (void)setupFlexibleNavBar {
    self.flexibleNavBar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
    CGRect barFrame = self.flexibleNavBar.frame;
    self.flexibleNavBar.maximumBarHeight = 110;
    self.flexibleNavBar.minimumBarHeight = 66;
    self.flexibleNavBar.layer.masksToBounds = YES;
    barFrame.size.height += 44;
    self.flexibleNavBar.frame = barFrame;
    self.flexibleNavBar.titleLabel.text = @"Explore Channels";
    [self.flexibleNavBar.rightBarButton setImage:[[UIImage imageNamed:@"Add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [self.flexibleNavBar.rightBarButton addTarget:(YAMainTabBarController *)self.tabBarController action:@selector(presentCreateGroup) forControlEvents:UIControlEventTouchUpInside];
    
    //search bar
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(20, 68, VIEW_WIDTH-40, 30)];
    self.searchBar.searchTextPositionAdjustment = UIOffsetMake(20, 0);
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.barStyle = UIBarStyleDefault;
    self.searchBar.barTintColor = self.flexibleNavBar.backgroundColor;
    self.searchBar.translucent = NO;
    self.searchBar.tintColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.searchBar.delegate = self;
    self.searchBar.alpha = 0.8;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *searchBarExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    searchBarExpanded.frame = CGRectMake(20, 68, VIEW_WIDTH-40, 30);
    [self.searchBar addLayoutAttributes:searchBarExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *searchBarCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    searchBarCollapsed.frame = CGRectMake(20, 27, VIEW_WIDTH-40, 30);
    [self.searchBar addLayoutAttributes:searchBarCollapsed forProgress:1.0];
    [self.flexibleNavBar addSubview:self.searchBar];
    
    //post adjustments
    self.flexibleNavBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];

    self.delegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.flexibleNavBar.behaviorDefiner];
    self.tableView.delegate = (id<UITableViewDelegate>)self.delegateSplitter;
    self.tableView.contentInset = UIEdgeInsetsMake(self.flexibleNavBar.maximumBarHeight, 0, 44, 0);
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.flexibleNavBar];
    self.navigationController.navigationBar.translucent = NO;

    //important to reassign initial pull to refresh inset, there is no way to recreate it
    self.tableView.pullToRefreshView.originalTopInset = self.tableView.contentInset.top;
}

#pragma mark - UISearchBarDelegate

//doesn't work?
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self.searchResultLabel removeFromSuperview];
    [self.searchTableActivity removeFromSuperview];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setLeftViewMode:UITextFieldViewModeAlways];

    self.groupsDataArray = [[NSUserDefaults standardUserDefaults] objectForKey:kFindGroupsCachedResponse];
    [self filterAndReload:YES];
}

- (void)restoreNonSearchResults {
    [self.searchResultLabel removeFromSuperview];
    [self.searchTableActivity removeFromSuperview];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setLeftViewMode:UITextFieldViewModeAlways];
    [self.searchActivity removeFromSuperview];
    self.searchActivity = nil;
    
    self.groupsDataArray = [[NSUserDefaults standardUserDefaults] objectForKey:kFindGroupsCachedResponse];
    [self filterAndReload:YES];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    [[Mixpanel sharedInstance] track:@"Searched Channels"];

}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {

    __weak typeof(self) weakSelf = self;
    if(searchBar.text.length) {
        if(!self.searchActivity)
            self.searchActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.searchActivity.frame = CGRectMake(15, 10, 10, 10);
        [self.searchBar addSubview:self.searchActivity];
        [self.searchActivity  startAnimating];
        [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setLeftViewMode:UITextFieldViewModeNever];
        
        if(!self.searchTableActivity)
            self.searchTableActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.searchTableActivity.frame = CGRectMake(self.tableView.frame.size.width/2- self.searchTableActivity.frame.size.width/2, self.tableView.frame.size.height/4,  self.searchTableActivity.frame.size.width,  self.searchTableActivity.frame.size.height);
        self.searchTableActivity.color = PRIMARY_COLOR;
        [self.searchTableActivity startAnimating];
        [self.tableView addSubview:self.searchTableActivity];
        
        if(!self.searchResultLabel)
            self.searchResultLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.searchTableActivity.frame.origin.y + self.searchTableActivity.frame.size.height, self.tableView.frame.size.width, 50)];
        self.searchResultLabel.text =[NSString stringWithFormat:@"Searching %@", searchBar.text];
        self.searchResultLabel.textColor = PRIMARY_COLOR;
        self.searchResultLabel.font = [UIFont fontWithName:BIG_FONT size:26];
        self.searchResultLabel.textAlignment = NSTextAlignmentCenter;
        [self.tableView addSubview:self.searchResultLabel];
        
        self.groupsDataArray = nil;
        [self filterAndReload:YES];

        [[YAServer sharedServer] searchGroupsByName:[searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] withCompletion:^(id response, NSError *error) {
            if(error) {
                [YAUtils showHudWithText:@"Error occured, try later"];
                
                [self restoreNonSearchResults];
                return;
            }
            [weakSelf.searchTableActivity removeFromSuperview];

            [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setLeftViewMode:UITextFieldViewModeAlways];
            [self.searchActivity removeFromSuperview];
            self.searchActivity = nil;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSArray *readableArray = [YAUtils readableGroupsArrayFromResponse:response];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.searchBar.text.length != 0) { // If search bar is empty, should be using cached results.
                        if(readableArray.count) {
                            weakSelf.groupsDataArray = readableArray;
                            [weakSelf.searchResultLabel removeFromSuperview];
                            weakSelf.searchResultLabel = nil;
                        }
                        else {
                            weakSelf.groupsDataArray = nil;
                            weakSelf.searchResultLabel.text = [NSString stringWithFormat:@"Nothing found for %@", searchBar.text];
                        }
                        [weakSelf filterAndReload:YES];
                    }
                });
            });
            
        }];
    }
    else {
        [self restoreNonSearchResults];
    }
}

#pragma mark - Private
- (void)filterAndReload:(BOOL)reload {
    NSArray *filtered = self.groupsDataArray;
    
    if(self.searchBar.text.length != 0) {
        // Re-filter in case search query changed since request.
        filtered = [filtered filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary* evaluatedObject, NSDictionary *bindings) {
            return [[((NSString *)evaluatedObject[YA_RESPONSE_NAME]) lowercaseString] rangeOfString:[self.searchBar.text lowercaseString]].location != NSNotFound;
        }]];
    }
    
    self.featuredGroups = [filtered filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary* evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject[@"featured"] isEqual: @YES];
    }]];
    
    NSMutableArray *suggested = [NSMutableArray arrayWithArray:filtered];
    [suggested removeObjectsInArray:self.featuredGroups];
    
    // Sort non-featured groups by public first
    self.suggestedGroups = [suggested sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        BOOL onePrivate = [obj1[YA_RESPONSE_PRIVATE] boolValue], twoPrivate = [obj2[YA_RESPONSE_PRIVATE] boolValue];
        return (onePrivate == twoPrivate) ? NSOrderedSame : (onePrivate ? NSOrderedDescending : NSOrderedAscending);
    }];
    
    if (reload)
        [self.tableView reloadData];
}

- (NSDictionary*)groupDataAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *result;
    if(indexPath.section == 0) {
        result = self.featuredGroups.count != 0 ? self.featuredGroups[indexPath.row] : self.suggestedGroups[indexPath.row];
    }
    else {
        result = self.suggestedGroups[indexPath.row];
    }
    
    return result;
}

- (NSString*)twoLinesDescriptionFromGroupData:(NSDictionary*)groupData {
    NSString *firstLine;
    NSString *secondLine;
    if ([groupData[YA_RESPONSE_PRIVATE] boolValue]) {
        firstLine = @"🔒 Private Channel";
        secondLine = groupData[YA_RESPONSE_MEMBERS];
    } else {
        firstLine = [NSString stringWithFormat:@"%@ %@", groupData[YA_RESPONSE_FOLLOWER_COUNT], ([groupData[YA_RESPONSE_FOLLOWER_COUNT] intValue] == 1)?@"Follower":@"Followers"];
        secondLine = [NSString stringWithFormat:@"Hosted by %@",  groupData[YA_RESPONSE_MEMBERS]];
    }
    return [NSString stringWithFormat:@"%@\n%@", firstLine, secondLine];
}

#pragma mark - TableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger result = self.featuredGroups.count ? 1 : 0;
    
    result += self.suggestedGroups.count ? 1 : 0;
    
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger result = section == 0 && self.featuredGroups.count ? self.featuredGroups.count : self.suggestedGroups.count;
    
    if(!result && self.tableView.pullToRefreshView.state == SVPullToRefreshStateStopped)
        result = 1;
    
    return result;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;

}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //todo:use UITableViewHeaderFooterView for reuse
    UIView *result = [[UIView alloc] initWithFrame:CGRectMake(100, self.tableView.contentOffset.y, VIEW_WIDTH, 40)];
    result.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, VIEW_WIDTH - 15, 20)];
    label.font = [UIFont fontWithName:BOLD_FONT size:14];
    label.textColor = headerAndAccessoryColor;
    label.text = section == 0 && self.featuredGroups.count ? @"FEATURED" : @"SUGGESTED";
    [result addSubview:label];
    
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.featuredGroups.count == 0 && self.suggestedGroups.count == 0)
        return 150;
    
    //    NSDictionary *groupData = self.groupsDataArray[indexPath.row];
    //    NSDictionary *attributes = @{NSFontAttributeName:[GroupsTableViewCell defaultDetailedLabelFont]};
    //    CGRect rect = [groupData[YA_RESPONSE_MEMBERS] boundingRectWithSize:CGSizeMake([GroupsTableViewCell contentWidth] - 50, CGFLOAT_MAX)
    //                                                               options:NSStringDrawingUsesLineFragmentOrigin
    //                                                            attributes:attributes
    //                                                               context:nil];
    //
    //    return rect.size.height + 80;
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1];
    cell.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:cell.bounds alpha:0.3];
    
    cell.textLabel.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, cell.textLabel.frame.size.width - 150, cell.textLabel.frame.size.height);
    
    cell.detailTextLabel.frame = CGRectMake(cell.detailTextLabel.frame.origin.x, cell.detailTextLabel.frame.origin.y, cell.detailTextLabel.frame.size.width - 150, cell.detailTextLabel.frame.size.height);
    
    cell.backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    
    if(self.suggestedGroups.count == 0 && self.featuredGroups.count == 0 && self.tableView.pullToRefreshView.state == SVPullToRefreshStateStopped) {
        cell.textLabel.text = NSLocalizedString(@"Wow, you're early. Create a group to get your friends on Yaga", @"");
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:18];
        cell.textLabel.textColor = PRIMARY_COLOR;
        UIButton *createGroupButton = [UIButton buttonWithType:UIButtonTypeCustom];
        createGroupButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:18];
        createGroupButton.tag = indexPath.row;
        createGroupButton.frame = CGRectMake(0, 0, 90, 30);
        [createGroupButton addTarget:self action:@selector(createGroupButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [createGroupButton setTitle:NSLocalizedString(@"Create", @"") forState:UIControlStateNormal];
        [createGroupButton setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
        [createGroupButton setTitleColor:PRIMARY_COLOR_ACCENT forState:UIControlStateHighlighted];
        [createGroupButton setTintColor:PRIMARY_COLOR];
        createGroupButton.layer.borderWidth = 2.0f;
        createGroupButton.layer.borderColor = [PRIMARY_COLOR CGColor];
        createGroupButton.layer.cornerRadius = 4;
        cell.accessoryView = createGroupButton;
        return cell;
    }
    
    NSDictionary *groupData = [self groupDataAtIndexPath:indexPath];
    BOOL private = [groupData[YA_RESPONSE_PRIVATE] boolValue];
    
    UIColor *accessoryColor = private ? PRIVATE_GROUP_COLOR : PUBLIC_GROUP_COLOR;
    UIColor *textColor = private ? PRIVATE_GROUP_COLOR : PUBLIC_GROUP_COLOR;
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[YAUtils imageWithColor:[textColor colorWithAlphaComponent:0.3]]];
    
    cell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:26];
    cell.textLabel.textColor = textColor;
    cell.detailTextLabel.textColor = [textColor copy];
    cell.detailTextLabel.numberOfLines = 2;
    
    cell.textLabel.text = groupData[YA_RESPONSE_NAME];
    cell.detailTextLabel.text = [self twoLinesDescriptionFromGroupData:groupData];

    
    //ios8 fix
    if ([cell respondsToSelector:@selector(layoutMargins)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    
    if([self.pendingRequestsInProgress containsObject:groupData[YA_RESPONSE_ID]]) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.frame = CGRectMake(0, 0, kAccessoryButtonWidth, 30);
        activityView.color = accessoryColor;
        cell.accessoryView = activityView;
        [activityView startAnimating];
    }
    else if([groupData[YA_RESPONSE_PENDING_MEMBERS] boolValue]) {
        UILabel *pendingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kAccessoryButtonWidth, 35)];
        pendingLabel.textColor = private ? [UIColor lightGrayColor] : PUBLIC_GROUP_COLOR;
        pendingLabel.font = [UIFont fontWithName:BIG_FONT size:15];
        pendingLabel.textAlignment = NSTextAlignmentCenter;
        pendingLabel.text = NSLocalizedString(@"Pending", @"");
        cell.accessoryView = pendingLabel;
    }
    else {
        UIButton *requestButton = [UIButton buttonWithType:UIButtonTypeCustom];
        requestButton.clipsToBounds = YES;
        requestButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:15];
        requestButton.tag = indexPath.row;
        requestButton.frame = CGRectMake(0, 0, kAccessoryButtonWidth, 35);
        
        [requestButton setTitle:private ? NSLocalizedString(@"Request", @"") : NSLocalizedString(@"Follow", @"") forState:UIControlStateNormal];
        [requestButton setTitleColor:accessoryColor forState:UIControlStateNormal];
        [requestButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [requestButton setTintColor:accessoryColor];
        [requestButton setBackgroundImage:[YAUtils imageWithColor:accessoryColor] forState:UIControlStateHighlighted];
        requestButton.layer.borderWidth = 2.5f;
        requestButton.layer.borderColor = [accessoryColor CGColor];
        requestButton.layer.cornerRadius = 8;
        [requestButton addTarget:self action:@selector(accessoryButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = requestButton;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *groupData = [self groupDataAtIndexPath:indexPath];
    if ([groupData[YA_RESPONSE_PRIVATE] boolValue]) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return; // Can't view a private group
    }
    
    RLMResults *results = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", groupData[YA_RESPONSE_ID]]];
    
    void (^openGroupBlock)(YAGroup *group, NSIndexPath *indexPath) = ^(YAGroup *group, NSIndexPath *indexPath){
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [[RLMRealm defaultRealm] beginWriteTransaction];
        group.amFollowing = NO; // Need to reset this here, because other code assumes visibilty == following.
        [[RLMRealm defaultRealm] commitWriteTransaction];

        YAGroupGridViewController *vc = [YAGroupGridViewController new];
        vc.group = group;
        [self.navigationController pushViewController:vc animated:YES];
    };
    
    [[Mixpanel sharedInstance] track:@"Tapped into unfollowed group"];

    //try to find an existing group
    if(results.count) {
        YAGroup *group = results[0];
        openGroupBlock(group, indexPath);
    }
    //or create new group from server response data, refresh and push grid to navigation stack
    else {
        YAGroup *group = [YAGroup groupWithServerResponseDictionary:groupData];
        [[RLMRealm defaultRealm] beginWriteTransaction];
        [[RLMRealm defaultRealm] addObject:group];
        [[RLMRealm defaultRealm] commitWriteTransaction];
        
        MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:@"Fetching channel data.."];
        [group refreshWithCompletion:^(NSError *error) {
            [hud hide:YES];
            
            if(error) {
                [YAUtils showHudWithText:[NSString stringWithFormat:@"Can not fetch group info, error %@", error.localizedDescription]];
                return;
            }
            
            openGroupBlock(group, indexPath);
            
        } showPullDownToRefresh:NO];
    }
}
@end
