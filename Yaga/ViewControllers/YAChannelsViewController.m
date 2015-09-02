//
//  YAChannelsViewController.m
//  Yaga
//
//  Created by valentinkovalski on 8/28/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAChannelsViewController.h"
#import "YAStandardFlexibleHeightBar.h"
#import "YAMainTabBarController.h"
#import "YABarBehaviorDefiner.h"
#import "YAFindGroupsViewConrtoller.h"
#import "YAGroupsListViewController.h"
#import "OrderedDictionary.h"
#import "BLKDelegateSplitter.h"
#import "YAServer.h"
#import "YAGroup.h"
#import "GroupsTableViewCell.h"
#import "NameGroupViewController.h"
#import "YAGroupGridViewController.h"
#import "OrderedDictionary.h"

#define kAccessoryButtonWidth 70
static NSString *CellIdentifier = @"GroupsCell";
static NSString *HeaderIdentifier = @"GroupsHeader";

@interface YAChannelsViewController ()
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, strong) UIViewController *currentViewController;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *searchTableView;

@property (nonatomic, strong) UIActivityIndicatorView *searchActivity;
@property (nonatomic, strong) UIActivityIndicatorView *searchTableActivity;
@property (nonatomic, strong) UILabel *searchResultLabel;

@property (nonatomic, strong) BLKDelegateSplitter *searchDelegateSplitter;

@property (nonatomic, strong) NSArray *serverResults;
@property (nonatomic, strong) MutableOrderedDictionary *searchResultsDictionary;
@property (nonatomic, strong) NSMutableSet *pendingRequestsInProgress;
@end

@implementation YAChannelsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _flexibleNavBar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
   
    [self.view addSubview:self.flexibleNavBar];
    
    //segmented control
    _segmentedControl = [UISegmentedControl new];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    
    [self.view addSubview:self.currentViewController.view];
    [self.view bringSubviewToFront:self.flexibleNavBar];
    
    self.segmentedControl.selectedSegmentIndex = 0;
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = CGRectMake(20, self.flexibleNavBar.frame.size.height, VIEW_WIDTH - 40, 30);
    expanded.alpha = 1;
    [self.segmentedControl addLayoutAttributes:expanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    collapsed.frame = CGRectMake(20, 0, VIEW_WIDTH - 40, 0);
    collapsed.alpha = -1; //to hide it even quicker
    [self.segmentedControl addLayoutAttributes:collapsed forProgress:1.0];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    [self.flexibleNavBar addSubview:self.segmentedControl];
    self.flexibleNavBar.maximumBarHeight = 110;
    
    [self setupNavbar];
    [self setupSegments];
    
    //show first view controller
    [self segmentedControlChanged:self.segmentedControl];
}

- (void)setupNavbar {
    [self.flexibleNavBar.titleButton setTitle:@"Channels" forState:UIControlStateNormal];
    
    [self.flexibleNavBar.rightBarButton setTitle:@"New" forState:UIControlStateNormal];
    [self.flexibleNavBar.rightBarButton addTarget:(YAMainTabBarController *)self.tabBarController action:@selector(presentCreateGroup) forControlEvents:UIControlEventTouchUpInside];
    
    [self.flexibleNavBar.leftBarButton setTitle:@"Search" forState:UIControlStateNormal];
    [self.flexibleNavBar.leftBarButton addTarget:self action:@selector(showSearch) forControlEvents:UIControlEventTouchUpInside];
    
    self.flexibleNavBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];
}

- (void)setupSegments {
    [self.segmentedControl insertSegmentWithTitle:@"Private" atIndex:0 animated:NO];
    [self.segmentedControl insertSegmentWithTitle:@"Public" atIndex:1 animated:NO];
    [self.segmentedControl insertSegmentWithTitle:@"Discover" atIndex:2 animated:NO];
    self.segmentedControl.selectedSegmentIndex = 0;
    
    YAGroupsListViewController *private = [YAGroupsListViewController new];
    private.queriesForSection = [MutableOrderedDictionary new];
    [private.queriesForSection setObject:@"publicGroup = 0 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup'" forKey:kNoSectionName];
    
    private.flexibleNavBar = self.flexibleNavBar;
    
    YAGroupsListViewController *public = [YAGroupsListViewController new];
    public.queriesForSection = [MutableOrderedDictionary new];
    [public.queriesForSection setObject:@"amMember = 1 && publicGroup = 1 && streamGroup = 0 && name != 'EmptyGroup'" forKey:@"HOSTING"];
    [public.queriesForSection setObject:@"amFollowing = 1 && streamGroup = 0 && name != 'EmptyGroup'" forKey:@"FOLLOWING"];
    public.flexibleNavBar = self.flexibleNavBar;

    YAFindGroupsViewConrtoller *discover = [YAFindGroupsViewConrtoller new];
    discover.flexibleNavBar = self.flexibleNavBar;
    

    self.viewControllers = @[private, public, discover];
}

- (void)segmentedControlChanged:(UISegmentedControl*)segmentedControl {
    UIViewController *vc = self.viewControllers[segmentedControl.selectedSegmentIndex];

    vc.view.alpha = 0;
    
    [self addChildViewController:vc];
    vc.view.frame = self.view.bounds;
    [self.view addSubview:vc.view];
    [self.view bringSubviewToFront:self.flexibleNavBar];
    [vc didMoveToParentViewController:self];
    self.navigationItem.title = vc.title;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.currentViewController.view.alpha = 0;
        vc.view.alpha = 1;
    } completion:^(BOOL finished) {
        if (finished) {
            [self.currentViewController.view removeFromSuperview];
            [self.currentViewController removeFromParentViewController];
            self.currentViewController = vc;
        }
    }];
}

- (void)showSearch {
    [self.flexibleNavBar.leftBarButton setTitle:@"" forState:UIControlStateNormal];
    self.flexibleNavBar.leftBarButton.enabled = NO;
    
    //search bar
    self.searchBar = [[UISearchBar alloc] initWithFrame:self.segmentedControl.frame];
    self.searchBar.searchTextPositionAdjustment = UIOffsetMake(20, 0);
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.barStyle = UIBarStyleDefault;
    self.searchBar.barTintColor = self.flexibleNavBar.backgroundColor;
    self.searchBar.translucent = NO;
    self.searchBar.tintColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.searchBar.delegate = self;
    self.searchBar.alpha = 0;
    self.searchBar.showsCancelButton = YES;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = self.segmentedControl.frame;
    expanded.alpha = 0;
    [self.segmentedControl addLayoutAttributes:expanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    collapsed.frame = CGRectMake(20, 0, VIEW_WIDTH - 40, 0);
    collapsed.alpha = -1; //to hide it even quicker
    [self.segmentedControl addLayoutAttributes:collapsed forProgress:1.0];
    
    expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = self.segmentedControl.frame;
    expanded.alpha = 1;
    [self.searchBar addLayoutAttributes:expanded forProgress:0.0];
    collapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    collapsed.frame = CGRectMake(20, 0, VIEW_WIDTH - 40, 0);
    collapsed.alpha = -1; //to hide it even quicker
    [self.searchBar addLayoutAttributes:collapsed forProgress:1.0];
    
    [self.flexibleNavBar addSubview:self.searchBar];
    
    [self.searchBar becomeFirstResponder];

    [UIView animateWithDuration:0.2 animations:^{
        self.segmentedControl.alpha = 0;
        self.searchBar.alpha = 1;
    }];
}

- (void)hideSearch {
    [self.flexibleNavBar.leftBarButton setTitle:@"Search" forState:UIControlStateNormal];
    self.flexibleNavBar.leftBarButton.enabled = YES;
    
    [self.searchTableView removeFromSuperview];
    self.searchTableView = nil;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = self.segmentedControl.frame;
    expanded.alpha = 1;
    [self.segmentedControl addLayoutAttributes:expanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    collapsed.frame = CGRectMake(20, 0, VIEW_WIDTH - 40, 0);
    collapsed.alpha = -1; //to hide it even quicker
    [self.segmentedControl addLayoutAttributes:collapsed forProgress:1.0];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.flexibleNavBar.leftBarButton.alpha = 1;
        self.segmentedControl.alpha = 1;
        self.searchBar.alpha = 0;
    } completion:^(BOOL finished) {
        [self.searchBar removeFromSuperview];
        self.searchBar = nil;
        
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self hideSearch];
}

- (void)showHideSearchResults {
    if(self.searchBar.text.length && !self.searchTableView) {
        self.searchTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
        self.searchTableView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.searchTableView];
        [self.view bringSubviewToFront:self.flexibleNavBar];
        
        
        [self.searchTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self.searchTableView registerClass:[GroupsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
        
        self.searchTableView.contentInset = UIEdgeInsetsMake(75, 0, 44, 0);
        self.searchDelegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.flexibleNavBar.behaviorDefiner];
        self.searchTableView.delegate = (id<UITableViewDelegate>)self.searchDelegateSplitter;
        self.searchTableView.dataSource = self;
    }
    else if(!self.searchBar.text.length) {
        [self.searchTableView removeFromSuperview];
        self.searchTableView = nil;
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {

    [self showHideSearchResults];
    
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
        self.searchTableActivity.frame = CGRectMake(self.searchTableView.frame.size.width/2- self.searchTableActivity.frame.size.width/2, self.searchTableView.frame.size.height/4,  self.searchTableActivity.frame.size.width,  self.searchTableActivity.frame.size.height);
        self.searchTableActivity.color = PRIMARY_COLOR;
        [self.searchTableActivity startAnimating];
        [self.searchTableView addSubview:self.searchTableActivity];

        if(!self.searchResultLabel)
            self.searchResultLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.searchTableActivity.frame.origin.y + self.searchTableActivity.frame.size.height, self.searchTableView.frame.size.width, 50)];
        self.searchResultLabel.text =[NSString stringWithFormat:@"Searching %@", searchBar.text];
        self.searchResultLabel.textColor = PRIMARY_COLOR;
        self.searchResultLabel.font = [UIFont fontWithName:BIG_FONT size:26];
        self.searchResultLabel.textAlignment = NSTextAlignmentCenter;
        [self.searchTableView addSubview:self.searchResultLabel];

        self.searchResultsDictionary = nil;
        
        [self.searchTableView reloadData];

        [[YAServer sharedServer] searchGroupsByName:[searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] withCompletion:^(id response, NSError *error) {
            if(error) {
                [YAUtils showHudWithText:@"Error occured, try later"];

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
                            weakSelf.serverResults = readableArray;
                            [weakSelf.searchResultLabel removeFromSuperview];
                            weakSelf.searchResultLabel = nil;
                        }
                        else {
                            weakSelf.serverResults = nil;
                            weakSelf.searchResultLabel.text = [NSString stringWithFormat:@"Nothing found for %@", searchBar.text];
                        }
                        [weakSelf filterAndReload:YES];
                    }
                });
            });

        }];
    }
}

- (void)filterAndReload:(BOOL)reload {
    self.searchResultsDictionary = [MutableOrderedDictionary new];
    
    if(self.searchBar.text.length != 0) {
        // Re-filter in case search query changed since request.
        self.serverResults = [self.serverResults filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary* evaluatedObject, NSDictionary *bindings) {
            return [[((NSString *)evaluatedObject[YA_RESPONSE_NAME]) lowercaseString] rangeOfString:[self.searchBar.text lowercaseString]].location != NSNotFound;
        }]];
    }
    
    NSArray *featured = [self.serverResults filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary* evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject[@"featured"] isEqual: @YES];
    }]];
    
    if(featured.count)
        [self.searchResultsDictionary setObject:featured forKey:@"FEATURED"];
    
    NSMutableArray *suggested = [NSMutableArray arrayWithArray:self.serverResults];
    [suggested removeObjectsInArray:featured];
    
    // Sort non-featured groups by public first
    suggested = [[suggested sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        BOOL onePrivate = [obj1[YA_RESPONSE_PRIVATE] boolValue], twoPrivate = [obj2[YA_RESPONSE_PRIVATE] boolValue];
        return (onePrivate == twoPrivate) ? NSOrderedSame : (onePrivate ? NSOrderedDescending : NSOrderedAscending);
    }] copy];
    
    if(suggested.count)
        [self.searchResultsDictionary setObject:suggested forKey:@"SUGGESTED"];
   
    NSArray *serverGroupNames = [[featured valueForKey:@"name"] arrayByAddingObjectsFromArray:[suggested valueForKey:@"name"]];
    
    if(reload) {
        //local search
        NSArray *localPublic = [self localArrayOfChannelsQueriedBy:[NSString stringWithFormat:@"publicGroup = 1 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup' && name CONTAINS '%@'", self.searchBar.text]];
        
        if(localPublic.count)
            [self.searchResultsDictionary setObject:localPublic forKey:@"PUBLIC"];
        
        NSArray *localPrivate = [self localArrayOfChannelsQueriedBy:[NSString stringWithFormat:@"publicGroup = 0 && amMember = 1 && streamGroup = 0 && name != 'EmptyGroup' && name CONTAINS '%@'", self.searchBar.text]];
        
        if(localPrivate.count)
            [self.searchResultsDictionary setObject:localPrivate forKey:@"PRIVATE"];
        
        NSArray *localFollowing = [self localArrayOfChannelsQueriedBy:[NSString stringWithFormat:@"amFollowing = 1 && streamGroup = 0 && name != 'EmptyGroup' && name CONTAINS '%@'", self.searchBar.text]];
        
        
        if(localFollowing.count)
            [self.searchResultsDictionary setObject:localFollowing forKey:@"FOLLOWING"];
        
        [self.searchTableView reloadData];
    }
}

- (NSArray*)localArrayOfChannelsQueriedBy:(NSString*)query {
    RLMResults *queryResult = [[YAGroup allObjects] objectsWhere:query];
    
    NSArray *resultArray;
    if(queryResult.count) {
        queryResult = [queryResult sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
        resultArray = [self arrayFromRLMResults:queryResult];
    }
    
    return resultArray;
}

- (NSMutableArray *)arrayFromRLMResults:(RLMResults *)results {
    NSMutableArray *arr = [NSMutableArray array];
    for (YAGroup *group in results) {
        [arr addObject:[group dictionaryRepresentation]];
    }
    return arr;
}

- (NSDictionary*)groupDataAtIndexPath:(NSIndexPath*)indexPath {
    NSArray *sectionGroupData = [self.searchResultsDictionary objectAtIndex:indexPath.section];
    return [sectionGroupData objectAtIndex:indexPath.row];
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

- (void)accessoryButtonTapped:(UIButton*)sender event:(id)event{
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        return;
    }
    
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.searchTableView];
    NSIndexPath *indexPath = [self.searchTableView indexPathForRowAtPoint: currentTouchPosition];
    
    if(!self.pendingRequestsInProgress)
        self.pendingRequestsInProgress = [NSMutableSet set];
    
    NSDictionary *groupData = [self groupDataAtIndexPath:indexPath];
    [self.pendingRequestsInProgress addObject:groupData[YA_RESPONSE_ID]];
    
    [self.searchTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    responseBlock block = ^(id response, NSError *error) {
        BOOL private = [groupData[YA_RESPONSE_PRIVATE] boolValue];
        [self.pendingRequestsInProgress removeObject:groupData[YA_RESPONSE_ID]];
        if(!error) {
            
            NSMutableArray *upatedDataArray = [NSMutableArray arrayWithArray:self.serverResults];
            
            if (private) {
                NSMutableDictionary *joinedGroupData = [NSMutableDictionary dictionaryWithDictionary:groupData];
                [joinedGroupData setObject:[NSNumber numberWithBool:YES] forKey:YA_RESPONSE_PENDING_MEMBERS];
                [upatedDataArray replaceObjectAtIndex:[upatedDataArray indexOfObject:groupData] withObject:joinedGroupData];
                [[NSUserDefaults standardUserDefaults] setObject:upatedDataArray forKey:kFindGroupsCachedResponse];
            } else {
                [upatedDataArray removeObject:groupData];
                [[NSUserDefaults standardUserDefaults] setObject:upatedDataArray forKey:kFindGroupsCachedResponse];
            }
            
            self.serverResults = upatedDataArray;
            
            [self filterAndReload:NO];
            
            if (!private && !error) {
                // Need to delete section if now empty
                if ([self.searchTableView numberOfRowsInSection:indexPath.section] == 1)
                    [self.searchTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
                else
                    [self.searchTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [self.searchTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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


#pragma mark - TableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.searchResultsDictionary.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sectionArray = [self.searchResultsDictionary objectAtIndex:section];
    return sectionArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.searchResultsDictionary.count == 0)
        return 150;
    
    return 100;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //todo:use UITableViewHeaderFooterView for reuse
    UIView *result = [[UIView alloc] initWithFrame:CGRectMake(100, self.searchTableView.contentOffset.y, VIEW_WIDTH, 40)];
    result.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, VIEW_WIDTH - 15, 20)];
    label.font = [UIFont fontWithName:BOLD_FONT size:14];
    label.textColor = SECONDARY_COLOR;
    label.text = [self.searchResultsDictionary keyAtIndex:section];
    [result addSubview:label];
    
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1];
    cell.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:cell.bounds alpha:0.3];
    
    cell.textLabel.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, cell.textLabel.frame.size.width - 150, cell.textLabel.frame.size.height);
    
    cell.detailTextLabel.frame = CGRectMake(cell.detailTextLabel.frame.origin.x, cell.detailTextLabel.frame.origin.y, cell.detailTextLabel.frame.size.width - 150, cell.detailTextLabel.frame.size.height);
    
    cell.backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    
//    if(self.suggestedGroups.count == 0 && self.featuredGroups.count == 0) {
//        cell.textLabel.text = NSLocalizedString(@"Nothing has been found", @"");
//        cell.textLabel.numberOfLines = 0;
//        cell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:18];
//        cell.textLabel.textColor = PRIMARY_COLOR;
//        return cell;
//    }
    
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
//        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//        activityView.frame = CGRectMake(0, 0, kAccessoryButtonWidth, 30);
//        activityView.color = accessoryColor;
//        cell.accessoryView = activityView;
//        [activityView startAnimating];
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
        [self.searchTableView deselectRowAtIndexPath:indexPath animated:YES];
        return; // Can't view a private group
    }
    
    RLMResults *results = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", groupData[YA_RESPONSE_ID]]];
    
    void (^openGroupBlock)(YAGroup *group, NSIndexPath *indexPath) = ^(YAGroup *group, NSIndexPath *indexPath){
        [self.searchTableView deselectRowAtIndexPath:indexPath animated:YES];
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
            
        } pageOffset:0 showPullDownToRefresh:NO];
    }
}


@end
