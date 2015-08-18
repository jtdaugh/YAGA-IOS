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
#import "YAGifGridViewController.h"

#define JOINED_OR_FOLLOWED @"JOINED_OR_FOLLOWED"
#define headerAndAccessoryColor [UIColor colorWithRed:46.0/255.0 green:30.0/255.0 blue:117.0/255.0 alpha:1.0]
#define kAccessoryButtonWidth 70

@interface YAFindGroupsViewConrtoller () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSArray *groupsDataArray;
@property (nonatomic, strong) NSMutableSet *pendingRequestsInProgress;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;

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
    
    self.navigationItem.title = NSLocalizedString(@"Explore Channels", @"");
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [self.view.backgroundColor copy];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView registerClass:[GroupsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    if(!self.onboardingMode) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        [self setupFlexibleNavBar];
        self.flexibleNavBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
        self.delegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.flexibleNavBar.behaviorDefiner];
        self.tableView.delegate = (id<UITableViewDelegate>)self.delegateSplitter;
        self.tableView.contentInset = UIEdgeInsetsMake(self.flexibleNavBar.maximumBarHeight, 0, 44, 0);
        [self.view addSubview:self.tableView];
        [self.view addSubview:self.flexibleNavBar];
    } else {
        [self.view addSubview:self.tableView];
    }
    
    [self setupPullToRefresh];
    
    //    [self.tableView triggerPullToRefresh];
    
    _groupsDataArray = [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] objectForKey:kFindGroupsCachedResponse];
    
    [self filterAndReload];
}

- (void)doneButtonPressed:(id)sender {
    if(self.onboardingMode) {
        [self performSegueWithIdentifier:@"ResetRootAfterFindGroups" sender:self];
    }
    else
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(self.onboardingMode) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip", @"") style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed:)];
        
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        __weak typeof(self) weakSelf = self;
        //load groups first time here
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
            if(!error) {
                // TODO: Adjust mixpanel for humanity
                if([YAGroup allObjects].count) {
                    [[Mixpanel sharedInstance] track:@"Onboarding user already a part of some groups"];
                    
                    NSLog(@"groups count: %lu", (unsigned long)[YAGroup allObjects].count);
                    
                    if(self.onboardingMode){
                        [self doneButtonPressed:nil];
                    }
                }
                else {
                    [[Mixpanel sharedInstance] track:@"Onboarding user doesn't have any groups"];
                }
                
                weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
            }
            
            weakSelf.groupsListLoaded = YES;
            if(self.findGroupsFinished && self.groupsDataArray.count == 0) {
                [weakSelf performSegueWithIdentifier:@"ResetRootAfterFindGroups" sender:weakSelf];
            }
        }];
        
        __block UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.frame = CGRectMake(self.tableView.frame.size.width/2- activityView.frame.size.width/2, self.tableView.frame.size.height/3,  activityView.frame.size.width,  activityView.frame.size.height);
        activityView.color = PRIMARY_COLOR;
        [activityView startAnimating];
        [self.tableView addSubview:activityView];
        
        __block UILabel *findingGroupsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, activityView.frame.origin.y + activityView.frame.size.height, self.tableView.frame.size.width, 50)];
        findingGroupsLabel.text = NSLocalizedString(@"Finding groups", @"");
        findingGroupsLabel.textColor = PRIMARY_COLOR;
        findingGroupsLabel.font = [UIFont fontWithName:BIG_FONT size:26];
        findingGroupsLabel.textAlignment = NSTextAlignmentCenter;
        [self.tableView addSubview:findingGroupsLabel];
        
        [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSMutableArray *contacts, BOOL sentToServer) {
            //request push permissions here
            if(![YAUserPermissions pushPermissionsRequestedBefore])
                [YAUserPermissions registerUserNotificationSettings];
            
            if(error) {
                self.findGroupsFinished = YES;
                if(self.groupsListLoaded)
                    [weakSelf performSegueWithIdentifier:@"ResetRootAfterFindGroups" sender:weakSelf];
            } else {
                if(sentToServer) {
                    [[YAServer sharedServer] searchGroupsWithCompletion:^(id response, NSError *error) {
                        self.findGroupsFinished = YES;
                        
                        if(!error) {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                NSArray *readableArray = [YAUtils readableGroupsArrayFromResponse:response];
                                [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setObject:readableArray forKey:kFindGroupsCachedResponse];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if(readableArray.count) {
                                        weakSelf.groupsDataArray = readableArray;
                                        [self filterAndReload];
                                        
                                        [activityView removeFromSuperview];
                                        [findingGroupsLabel removeFromSuperview];
                                        [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_JOIN_GROUPS_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_JOIN_GROUPS_BODY", @"") dismissText:@"Got it" addToView:self.parentViewController.view] show];
                                        
                                    }
                                    else {
                                        if(self.groupsListLoaded)
                                            [weakSelf performSegueWithIdentifier:@"ResetRootAfterFindGroups" sender:weakSelf];
                                    }
                                });
                            });
                        }
                        else {
                            if(self.groupsListLoaded)
                                [weakSelf performSegueWithIdentifier:@"ResetRootAfterFindGroups" sender:weakSelf];
                        }
                    }];
                }
            }
        } excludingPhoneNumbers:nil];
        
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (IBAction)unwindToGrid:(id)source {}


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
        if(!error) {
            NSMutableDictionary *joinedGroupData = [NSMutableDictionary dictionaryWithDictionary:groupData];
            [joinedGroupData setObject:[NSNumber numberWithBool:YES] forKey:JOINED_OR_FOLLOWED];
            NSMutableArray *upatedDataArray = [NSMutableArray arrayWithArray:self.groupsDataArray];
            [upatedDataArray replaceObjectAtIndex:[upatedDataArray indexOfObject:groupData] withObject:joinedGroupData];
            self->_groupsDataArray = upatedDataArray;
            [self filterAndReload];
            
            if(self.onboardingMode) {
                BOOL wasEnabled = self.navigationItem.rightBarButtonItem.enabled;
                UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
                doneButton.enabled = wasEnabled;
                [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
            }
        }
        else {
            DLog(@"Can't send request to join group");
        }
        
        [self.pendingRequestsInProgress removeObject:groupData[YA_RESPONSE_ID]];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    
    if ([groupData[YA_RESPONSE_PRIVATE] boolValue]) {
        [[YAServer sharedServer] joinGroupWithId:groupData[YA_RESPONSE_ID] withCompletion:block];
    } else {
        [[YAServer sharedServer] followGroupWithId:groupData[YA_RESPONSE_ID] withCompletion:block];
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
            [weakSelf filterAndReload];
        
        void (^searchGroupsBlock)(void) = ^{
            [[YAServer sharedServer] searchGroupsWithCompletion:^(id response, NSError *error) {
                [weakSelf.tableView.pullToRefreshView stopAnimating];
                
                if(error) {
                    [YAUtils showHudWithText:NSLocalizedString(@"Failed to search groups", @"")];
                }
                else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        weakSelf.groupsDataArray = [YAUtils readableGroupsArrayFromResponse:response];
                        [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setObject:weakSelf.groupsDataArray forKey:kFindGroupsCachedResponse];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf filterAndReload];
                        });
                    });
                }
            }];
        };
        
        NSDate *lastYagaUsersRequested = [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] objectForKey:kLastYagaUsersRequestDate];
        if(!lastYagaUsersRequested) {
            //force upload phone contacts in case there is no information on server yet otherwise searchGroups will return nothgin
            [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSMutableArray *contacts, BOOL sentToServer) {
                searchGroupsBlock();
            } excludingPhoneNumbers:nil];
        }
        else {
            searchGroupsBlock();
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
    self.flexibleNavBar.maximumBarHeight = 116;
    self.flexibleNavBar.minimumBarHeight = 66;
    self.flexibleNavBar.layer.masksToBounds = YES;
    barFrame.size.height += 50;
    self.flexibleNavBar.frame = barFrame;
    self.flexibleNavBar.titleLabel.text = @"Explore Channels";
    [self.flexibleNavBar.rightBarButton setImage:[[UIImage imageNamed:@"Add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.flexibleNavBar.rightBarButton.imageEdgeInsets = UIEdgeInsetsMake(10, kFlexNavBarButtonWidth - kFlexNavBarButtonHeight + 20, 10, 0);
    
    [self.flexibleNavBar.rightBarButton addTarget:(YAMainTabBarController *)self.tabBarController action:@selector(presentCreateGroup) forControlEvents:UIControlEventTouchUpInside];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(20, 70, VIEW_WIDTH-40, 30)];
    self.searchBar.barStyle = UIBarStyleBlack;
    self.searchBar.translucent = NO;
    self.searchBar.barTintColor = [UIColor blackColor];
    self.searchBar.tintColor = [UIColor whiteColor];
    self.searchBar.backgroundColor = [UIColor blackColor];
    self.searchBar.delegate = self;
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setLeftViewMode:UITextFieldViewModeUnlessEditing];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *searchBarExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    searchBarExpanded.frame = CGRectMake(20, 70, VIEW_WIDTH-40, 30);
    [self.searchBar addLayoutAttributes:searchBarExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *searchBarCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    searchBarCollapsed.frame = CGRectMake(20, 22, VIEW_WIDTH-40, 30);
    [self.searchBar addLayoutAttributes:searchBarCollapsed forProgress:1.0];
    
    [self.flexibleNavBar addSubview:self.searchBar];
    
}

#pragma mark - UISearchBarDelegate

//doesn't work?
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text  = @"";
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    
    [self filterAndReload];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [searchBar setShowsCancelButton:YES animated:YES];
    
    [self filterAndReload];
}

#pragma mark - Private
- (void)filterAndReload {
    self.featuredGroups = [self.groupsDataArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary* evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject[@"featured"]  isEqual: @YES];
    }]];
    
    NSMutableArray *suggested = [NSMutableArray arrayWithArray:self.groupsDataArray];
    [suggested removeObjectsInArray:self.featuredGroups];
    self.suggestedGroups = suggested;
    
    [self.tableView reloadData];
}

- (NSDictionary*)groupDataAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *result;
    if(indexPath.section == 0) {
        result = indexPath.section == 0 && self.featuredGroups.count != 0 ? self.featuredGroups[indexPath.row] : self.suggestedGroups[indexPath.row];
    }
    else {
        result = self.suggestedGroups[indexPath.row];
    }
    
    return result;
}

- (NSString*)twoLinesDescriptionFromGroupData:(NSDictionary*)groupData {
    NSString *firstLine = [NSString stringWithFormat:@"%@ Followers", groupData[YA_RESPONSE_FOLLOWER_COUNT]];
    NSString *secondLine = [NSString stringWithFormat:@"Hosted by %@",  groupData[YA_RESPONSE_MEMBERS]];
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
    
    if(!result && self.tableView.pullToRefreshView.state == SVPullToRefreshStateStopped && !self.onboardingMode)
        result = 1;
    
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //todo:use UITableViewHeaderFooterView for reuse
    UIView *result = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 40)];
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
    
    if(self.suggestedGroups.count == 0 && self.featuredGroups.count == 0 && self.tableView.pullToRefreshView.state == SVPullToRefreshStateStopped && !self.onboardingMode) {
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
    
    UIColor *accessoryColor = private ? [UIColor darkGrayColor] : headerAndAccessoryColor;
    UIColor *textColor = private ? [UIColor darkGrayColor] : SECONDARY_COLOR;
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[YAUtils imageWithColor:[textColor colorWithAlphaComponent:0.3]]];
    
    cell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:26];
    cell.textLabel.textColor = textColor;
    cell.detailTextLabel.textColor = [textColor copy];
    cell.detailTextLabel.numberOfLines = 2;
    
    cell.textLabel.text = groupData[YA_RESPONSE_NAME];
    cell.detailTextLabel.text = [self twoLinesDescriptionFromGroupData:groupData];
    
    //    NSDictionary *groupData = [self.groupsDataArray objectAtIndex:indexPath.row];
    //    BOOL private = [groupData[YA_RESPONSE_PRIVATE] boolValue];
    //    UIColor *cellColor = private ? PRIMARY_COLOR : SECONDARY_COLOR;
    //
    //    cell.textLabel.textColor = cellColor;
    //    cell.textLabel.text = groupData[YA_RESPONSE_NAME];
    //    if (private) {
    //        cell.detailTextLabel.text = [NSString stringWithFormat:@"Private - %@", groupData[YA_RESPONSE_MEMBERS]];
    //    } else {
    //        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld followers - Hosted by %@", (long)[groupData[YA_RESPONSE_FOLLOWER_COUNT] integerValue], groupData[YA_RESPONSE_MEMBERS]];
    //    }

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
    else if([groupData[JOINED_OR_FOLLOWED] boolValue]) {
        UILabel *pendingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kAccessoryButtonWidth, 35)];
        pendingLabel.textColor = private ? [UIColor lightGrayColor] : SECONDARY_COLOR;
        pendingLabel.font = [UIFont fontWithName:BIG_FONT size:15];
        pendingLabel.textAlignment = NSTextAlignmentCenter;
        pendingLabel.text = private ? NSLocalizedString(@"Pending", @"") :  NSLocalizedString(@"Following", @"");
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
    RLMResults *results = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", groupData[@"serverId"]]];
    
    //try to find an existing group
    __block YAGroup *group;
    
    if(results.count) {
        group = results[0];
    }
    //or create new group from server response data, refresh and push grid to navigation stack
    else {
        group = [YAGroup groupWithServerResponseDictionary:groupData];
        MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:@"Fetching group data.."];
        [group refreshWithCompletion:^(NSError *error) {
            [hud hide:YES];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            if(error) {
                [YAUtils showHudWithText:[NSString stringWithFormat:@"Can not fetch group info, error %@", error.localizedDescription]];
                return;
            }
            
            YAGifGridViewController *gridVC = [YAGifGridViewController new];
            [self.navigationController pushViewController:gridVC animated:YES];
            
        } showPullDownToRefresh:NO];
    }
}

#pragma mark - UIScrollView
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    CGFloat sectionHeaderHeight = -70;
//    if (scrollView.contentOffset.y<=sectionHeaderHeight&&scrollView.contentOffset.y>=0) {
//        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
//    } else if (scrollView.contentOffset.y>=sectionHeaderHeight) {
//        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, 0, 0);
//    }
//}
@end
