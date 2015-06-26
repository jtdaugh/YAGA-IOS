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

@interface YAFindGroupsViewConrtoller ()
@property (nonatomic, strong) NSArray *groupsDataArray;
@property (nonatomic, strong) NSMutableSet *pendingRequestsInProgress;
@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation YAFindGroupsViewConrtoller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Join Groups", @"");
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [self.view.backgroundColor copy];
    [self.tableView setAllowsSelection:NO];
    //    [self.tableView setSeparatorColor:PRIMARY_COLOR];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView registerClass:[GroupsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //ios8 fix for separatorInset
    if ([self.tableView respondsToSelector:@selector(layoutMargins)])
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    
    _groupsDataArray = [[NSUserDefaults standardUserDefaults] objectForKey:kFindGroupsCachedResponse];
    [self.tableView reloadData];
    
    [self setupPullToRefresh];
    [self.tableView triggerPullToRefresh];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(backButtonPressed:)];
    self.navigationItem.leftBarButtonItem = backButton;
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
}

- (void)backButtonPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger result = self.groupsDataArray.count;
    if(!result)
        result = 1;
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.textColor = PRIMARY_COLOR;
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1];
    cell.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:cell.bounds alpha:0.3];
    
    cell.textLabel.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, cell.textLabel.frame.size.width - 150, cell.textLabel.frame.size.height);
    
    cell.detailTextLabel.frame = CGRectMake(cell.detailTextLabel.frame.origin.x, cell.detailTextLabel.frame.origin.y, cell.detailTextLabel.frame.size.width - 150, cell.detailTextLabel.frame.size.height);
    [cell.textLabel setFont:[UIFont fontWithName:BOLD_FONT size:18]];
    
    if(!self.groupsDataArray.count) {
        cell.textLabel.text = NSLocalizedString(@"Wow, you're early. Create a group to get your friends on Yaga", @"");
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName size:18];
        UIButton *createGroupButton = [UIButton buttonWithType:UIButtonTypeCustom];
        createGroupButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:18];
        createGroupButton.tag = indexPath.row;
        createGroupButton.frame = CGRectMake(0, 0, 90, 30);
        [createGroupButton addTarget:self action:@selector(createGroupButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [createGroupButton setTitle:NSLocalizedString(@"Create", @"") forState:UIControlStateNormal];
        [createGroupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [createGroupButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [createGroupButton setTintColor:[UIColor whiteColor]];
        createGroupButton.layer.borderWidth = 2.0f;
        createGroupButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        createGroupButton.layer.cornerRadius = 4;
        cell.accessoryView = createGroupButton;
        return cell;
    }
    
    cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName size:28];
    
    NSDictionary *groupData = [self.groupsDataArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = groupData[YA_RESPONSE_NAME];
    cell.detailTextLabel.text = groupData[YA_RESPONSE_MEMBERS];
    
    if(indexPath.row == self.groupsDataArray.count - 1)
        cell.separatorInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, cell.bounds.size.width);
    
    __weak typeof(self) weakSelf = self;
    ((GroupsTableViewCell*)cell).editBlock = ^{
        [weakSelf tableView:weakSelf.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    };
    
    //ios8 fix
    if ([cell respondsToSelector:@selector(layoutMargins)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    
    if([self.pendingRequestsInProgress containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.frame = CGRectMake(0, 0, 90, 30);
        activityView.color = PRIMARY_COLOR;
        cell.accessoryView = activityView;
        [activityView startAnimating];
    }
    else if([groupData[YA_RESPONSE_PENDING_MEMBERS] boolValue]) {
        UILabel *pendingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 90, 30)];
        pendingLabel.textColor = [UIColor lightGrayColor];
        pendingLabel.font = [UIFont fontWithName:BIG_FONT size:18];
        pendingLabel.textAlignment = NSTextAlignmentCenter;
        pendingLabel.text = NSLocalizedString(@"Pending", @"");
        cell.accessoryView = pendingLabel;
    }
    else {
        UIButton *requestButton = [UIButton buttonWithType:UIButtonTypeCustom];
        requestButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
        requestButton.tag = indexPath.row;
        requestButton.frame = CGRectMake(0, 0, 90, 30);
        [requestButton addTarget:self action:@selector(requestButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [requestButton setTitle:NSLocalizedString(@"Request", @"") forState:UIControlStateNormal];
        [requestButton setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
        [requestButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [requestButton setTintColor:PRIMARY_COLOR];
        requestButton.layer.borderWidth = 1.5f;
        requestButton.layer.borderColor = [PRIMARY_COLOR CGColor];
        requestButton.layer.cornerRadius = 4;
        
        cell.accessoryView = requestButton;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(!self.groupsDataArray.count)
        return 150;
    
    NSDictionary *groupData = self.groupsDataArray[indexPath.row];
    
    NSDictionary *attributes = @{NSFontAttributeName:[GroupsTableViewCell defaultDetailedLabelFont]};
    CGRect rect = [groupData[YA_RESPONSE_MEMBERS] boundingRectWithSize:CGSizeMake([GroupsTableViewCell contentWidth] - 50, CGFLOAT_MAX)
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:attributes
                                                               context:nil];
    
    return rect.size.height + 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (IBAction)unwindToGrid:(id)source {}


- (void)requestButtonTapped:(UIButton*)sender {
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showHudWithText:NSLocalizedString(@"No internet connection, try later.", @"")];
        return;
    }
    
    if(!self.pendingRequestsInProgress)
        self.pendingRequestsInProgress = [NSMutableSet set];
    
    [self.pendingRequestsInProgress addObject:[NSNumber numberWithInteger:sender.tag]];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    NSDictionary *groupData = self.groupsDataArray[sender.tag];
    
    [[YAServer sharedServer] joinGroupWithId:groupData[YA_RESPONSE_ID] withCompletion:^(id response, NSError *error) {

        if(!error) {
            NSMutableDictionary *joinedGroupData = [NSMutableDictionary dictionaryWithDictionary:groupData];
            [joinedGroupData setObject:[NSNumber numberWithBool:YES] forKey:YA_RESPONSE_PENDING_MEMBERS];
            NSMutableArray *upatedDataArray = [NSMutableArray arrayWithArray:self.groupsDataArray];
            [upatedDataArray replaceObjectAtIndex:[upatedDataArray indexOfObject:groupData] withObject:joinedGroupData];
            _groupsDataArray = upatedDataArray;
            
        }
        else {
            DLog(@"Can't send request to join group");
        }
        
        [self.pendingRequestsInProgress removeObject:[NSNumber numberWithInteger:sender.tag]];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    }];
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
        
        [[YAServer sharedServer] searchGroupsWithCompletion:^(id response, NSError *error) {
            [weakSelf.tableView.pullToRefreshView stopAnimating];
            
            if(error) {
                [YAUtils showHudWithText:NSLocalizedString(@"Failed to search groups", @"")];
            }
            else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    weakSelf.groupsDataArray = [YAUtils readableGroupsArrayFromResponse:response];
                    [[NSUserDefaults standardUserDefaults] setObject:weakSelf.groupsDataArray forKey:kFindGroupsCachedResponse];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.tableView reloadData];
                    });
                });
            }
        }];
    }];
    
    YAPullToRefreshLoadingView *loadingView = [[YAPullToRefreshLoadingView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/10, 0, VIEW_WIDTH-VIEW_WIDTH/10/2, self.tableView.pullToRefreshView.bounds.size.height)];
    
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateLoading];
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateStopped];
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateTriggered];
}


@end
