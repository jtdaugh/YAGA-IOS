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

#define kFindGroupsCachedResponse @"kFindGroupsCachedResponse"

@interface YAFindGroupsViewConrtoller ()
@property (nonatomic, strong) NSArray *groupsDataArray;
@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation YAFindGroupsViewConrtoller

- (void)setGroupsDataArray:(NSArray *)groupsDataArray {
    NSMutableArray *result = [NSMutableArray new];
    for (NSDictionary *groupData in groupsDataArray) {
        NSArray *members = groupData[YA_RESPONSE_MEMBERS];
        NSString *membersString = [self membersStringFromMembersArray:members];
        
        BOOL isPending = [self alreadyRequestedAccessToGroup:groupData];
        [result addObject:@{YA_RESPONSE_ID : groupData[YA_RESPONSE_ID], YA_RESPONSE_NAME : groupData[YA_RESPONSE_NAME], YA_RESPONSE_MEMBERS : membersString, YA_RESPONSE_PENDING_MEMBERS : [NSNumber numberWithBool:isPending]}];
    }
    _groupsDataArray = result;
}

- (BOOL)alreadyRequestedAccessToGroup:(NSDictionary*)groupData {
    for (NSDictionary *pending_member in groupData[YA_RESPONSE_PENDING_MEMBERS]) {
        NSString *phoneNumber = pending_member[YA_RESPONSE_USER][YA_RESPONSE_MEMBER_PHONE];
        if([phoneNumber isEqualToString:[YAUser currentUser].phoneNumber])
            return YES;
    }
    return NO;
}

- (NSString*)contactDisplayNameFromDictionary:(NSDictionary*)contactDictionary {
    NSString *phoneNumber = contactDictionary[YA_RESPONSE_USER][YA_RESPONSE_MEMBER_PHONE];
    NSString *name = contactDictionary[YA_RESPONSE_USER][YA_RESPONSE_NAME];
    name = [name isKindOfClass:[NSNull class]] ? @"" : name;
    
    if(!name.length) {
        if([[YAUser currentUser].phonebook objectForKey:phoneNumber]) {
            name = [[YAUser currentUser].phonebook objectForKey:phoneNumber][nCompositeName];
        }
        else {
            name = kDefaultUsername;
        }
    }
    return name;
}

- (NSString*)membersStringFromMembersArray:(NSArray*)members {
    if(!members.count) {
        return NSLocalizedString(@"No members", @"");
    }
    
    NSString *results = @"";
    
    NSUInteger andMoreCount = 0;
    for(int i = 0; i < members.count; i++) {
        NSDictionary *contatDictionary = [members objectAtIndex:i];
        
        NSString *displayName = [self contactDisplayNameFromDictionary:contatDictionary];
        
        if([displayName isEqualToString:kDefaultUsername] || ! displayName)
            andMoreCount++;
        else {
            if(!results.length)
                results = displayName;
            else
                results = [results stringByAppendingFormat:@", %@", displayName];
        }
        if (i >= kMaxUsersShownInList) {
            andMoreCount += members.count - kMaxUsersShownInList;
            break;
        }
    }
    
    if(andMoreCount == 1) {
        if(results.length)
            results = [results stringByAppendingString:NSLocalizedString(@" and 1 more", @"")];
        else
            results = NSLocalizedString(@"ONE_UNKOWN_USER", @"");
    }
    else if(andMoreCount > 1) {
        if(!results.length) {
            results = [results stringByAppendingFormat:NSLocalizedString(@"N_UNKOWN_USERS_TEMPLATE", @""), andMoreCount];
        }
        else {
            results = [results stringByAppendingFormat:NSLocalizedString(@"OTHER_CONTACTS_TEMPLATE", @""), andMoreCount];
        }
        
    }
    return results;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Join Groups", @"");
    
    self.view.backgroundColor = PRIMARY_COLOR;
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [self.view.backgroundColor copy];
    
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
    return self.groupsDataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSDictionary *groupData = [self.groupsDataArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = groupData[YA_RESPONSE_NAME];
    cell.detailTextLabel.text = groupData[YA_RESPONSE_MEMBERS];
    
    cell.textLabel.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, cell.textLabel.frame.size.width - 150, cell.textLabel.frame.size.height);
    
    cell.detailTextLabel.frame = CGRectMake(cell.detailTextLabel.frame.origin.x, cell.detailTextLabel.frame.origin.y, cell.detailTextLabel.frame.size.width - 150, cell.detailTextLabel.frame.size.height);
    
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
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:cell.bounds alpha:0.3];
    
    UIButton *requestButton = [UIButton buttonWithType:UIButtonTypeCustom];
    requestButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:18];
    requestButton.tag = indexPath.row;
    requestButton.frame = CGRectMake(0, 0, 90, 30);
    [requestButton addTarget:self action:@selector(requestButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [requestButton setTitle:NSLocalizedString(@"Request", @"") forState:UIControlStateNormal];
    [requestButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [requestButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [requestButton setTintColor:[UIColor whiteColor]];
    requestButton.layer.borderWidth = 2.0f;
    requestButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    requestButton.layer.cornerRadius = 4;
    
    UILabel *pendingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 90, 30)];
    pendingLabel.textColor = [UIColor whiteColor];
    pendingLabel.font = [UIFont fontWithName:BOLD_FONT size:18];
    pendingLabel.textAlignment = NSTextAlignmentCenter;
    pendingLabel.text = NSLocalizedString(@"Pending", @"");
    
    cell.accessoryView = [groupData[YA_RESPONSE_PENDING_MEMBERS] boolValue]? pendingLabel : requestButton;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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
    NSDictionary *groupData = self.groupsDataArray[sender.tag];
    [[YAServer sharedServer] joinGroupWithId:groupData[YA_RESPONSE_ID] withCompletion:^(id response, NSError *error) {
        if(!error) {
            NSMutableDictionary *joinedGroupData = [NSMutableDictionary dictionaryWithDictionary:groupData];
            [joinedGroupData setObject:[NSNumber numberWithBool:YES] forKey:YA_RESPONSE_PENDING_MEMBERS];
            NSMutableArray *upatedDataArray = [NSMutableArray arrayWithArray:self.groupsDataArray];
            [upatedDataArray replaceObjectAtIndex:[upatedDataArray indexOfObject:groupData] withObject:joinedGroupData];
            _groupsDataArray = upatedDataArray;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            DLog(@"Can't send request to join group");
        }
    }];
}

- (void)setupPullToRefresh {
    //pull to refresh
    __weak typeof(self) weakSelf = self;
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        [[YAServer sharedServer] searchGroupsWithCompletion:^(id response, NSError *error) {
            if(error) {
                [YAUtils showHudWithText:NSLocalizedString(@"Failed to search groups", @"")];
            }
            else {
                [weakSelf.tableView.pullToRefreshView stopAnimating];
                weakSelf.groupsDataArray = (NSArray*)response;
                [weakSelf.tableView reloadData];
                [[NSUserDefaults standardUserDefaults] setObject:weakSelf.groupsDataArray forKey:kFindGroupsCachedResponse];
            }
        }];
    }];
    
    YAPullToRefreshLoadingView *loadingView = [[YAPullToRefreshLoadingView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/10, 0, VIEW_WIDTH-VIEW_WIDTH/10/2, self.tableView.pullToRefreshView.bounds.size.height)];
    
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateLoading];
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateStopped];
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateTriggered];
}


@end
