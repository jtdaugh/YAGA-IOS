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

#import "GroupsTableViewCell.h"
#import "YAServer.h"
#import "UIImage+Color.h"
#import "YAServer.h"

#import "YAGroupAddMembersViewController.h"
#import "YAGroupOptionsViewController.h"

#import "UIScrollView+SVPullToRefresh.h"
#import "YAPullToRefreshLoadingView.h"

#import "YAUserPermissions.h"

@interface YAGroupsViewController ()
@property (nonatomic, strong) RLMResults *groups;
@property (nonatomic, strong) UIButton *createGroupButton;
@property (nonatomic, strong) NSDictionary *groupsUpdatedAt;
@property (nonatomic, strong) YAGroup *editingGroup;
@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation YAGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController setNavigationBarHidden:NO];

    
    CGFloat origin = 12;
    CGFloat leftMargin = 0;
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2 + 15, origin, width - 30, VIEW_HEIGHT*.3)];
//    [titleLabel setText:NSLocalizedString(@"My Groups", @"")];
//    [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
//    [titleLabel setTextColor:PRIMARY_COLOR];
//    [self.view addSubview:titleLabel];
//    origin = titleLabel.frame.origin.y + titleLabel.frame.size.height;
    
    CGSize segSize = CGSizeMake(200, 30);
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithFrame:CGRectMake((VIEW_WIDTH - segSize.width)/2, origin, segSize.width, segSize.height)];
    [segmentedControl insertSegmentWithTitle:@"My Groups" atIndex:0 animated:NO];
    [segmentedControl insertSegmentWithTitle:@"Find Groups" atIndex:1 animated:NO];
    segmentedControl.tintColor = PRIMARY_COLOR;
    segmentedControl.selectedSegmentIndex = 0;
    
    [self.view addSubview:segmentedControl];
    
    origin += segSize.height + 10;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(leftMargin, origin, VIEW_WIDTH - leftMargin, self.view.bounds.size.height - origin)];

    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [self.view.backgroundColor copy];
//    self.tableView.contentInset = UIEdgeInsetsMake(44,0,0,0);

    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView registerClass:[GroupsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //ios8 fix for separatorInset
    if ([self.tableView respondsToSelector:@selector(layoutMargins)])
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    [self setupPullToRefresh];
    
    //notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.barTintColor = PRIMARY_COLOR;
    
//    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
    UIImageView *yagaLogo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 46)];
    yagaLogo.image = [UIImage imageNamed:@"Logo"];
    yagaLogo.contentMode = UIViewContentModeScaleAspectFit;
//    [titleView addSubview:yagaLogo];
    self.navigationItem.titleView = yagaLogo;
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:nil];
    rightItem.tintColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:nil];
    leftItem.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    [self updateState];
    
    [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
        [self updateState];
    }];
    
}

- (void)setupPullToRefresh {
    //pull to refresh
    __weak typeof(self) weakSelf = self;
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
            [weakSelf updateState];
            [weakSelf.tableView.pullToRefreshView stopAnimating];
        }];
    }];
    
    //    self.collectionView.pullToRefreshView.
    
    YAPullToRefreshLoadingView *loadingView = [[YAPullToRefreshLoadingView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/10, 0, VIEW_WIDTH-VIEW_WIDTH/10/2, self.tableView.pullToRefreshView.bounds.size.height)];
    
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateLoading];
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateStopped];
    [self.tableView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateTriggered];
}

- (void)groupDidRefresh:(NSNotification*)notif {
    [self updateState];
}

- (void)updateState {
    
    self.groups = [[YAGroup allObjects] sortedResultsUsingProperty:@"updatedAt" ascending:NO];
    
    self.groupsUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT];

    [self.tableView reloadData];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(![YAUserPermissions pushPermissionsRequestedBefore])
        [YAUserPermissions registerUserNotificationSettings];
    
    //load phonebook if it wasn't done before
    if(![YAUser currentUser].phonebook.count) {
        [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSArray *contacts) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }
        } excludingPhoneNumbers:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //crash fixed
    //http://stackoverflow.com/questions/19230446/tableviewcaneditrowatindexpath-crash-when-popping-viewcontroller
    self.tableView.editing = NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if([touch.view isKindOfClass:[UITableViewCell class]])
        return NO;
    // UITableViewCellContentView => UITableViewCell
    if([touch.view.superview isKindOfClass:[UITableViewCell class]])
        return NO;
    // UITableViewCellContentView => UITableViewCellScrollView => UITableViewCell
    if([touch.view.superview.superview isKindOfClass:[UITableViewCell class]])
        return NO;
    
    if([touch.view isKindOfClass:[UIButton class]])
        return NO;
    
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    YAGroup *group = [self.groups objectAtIndex:indexPath.row];
    
    cell.textLabel.text = group.name;
    cell.detailTextLabel.text = group.membersString;
    
    if(indexPath.row == self.groups.count - 1)
        cell.separatorInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, cell.bounds.size.width);
    
    __weak typeof(self) weakSelf = self;
    ((GroupsTableViewCell*)cell).editBlock = ^{
        [weakSelf tableView:weakSelf.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    };
    
    //ios8 fix
    if ([cell respondsToSelector:@selector(layoutMargins)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    
    cell.textLabel.textColor = group.muted ? [UIColor lightGrayColor] : PRIMARY_COLOR;
    cell.detailTextLabel.textColor = group.muted ? [UIColor lightGrayColor] : PRIMARY_COLOR;
    cell.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:cell.bounds alpha:0.3];
    
    NSDate *localGroupUpdateDate = [self.groupsUpdatedAt objectForKey:group.localId];
    if(!localGroupUpdateDate || [group.updatedAt compare:localGroupUpdateDate] == NSOrderedDescending) {
        UIImage *img = [YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:0.3]];
        cell.imageView.image = img;
    }
    else {
        UIImage *img = [YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:0.0]];
        cell.imageView.image = img;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    YAGroup *group = self.groups[indexPath.row];
    
    NSDictionary *attributes = @{NSFontAttributeName:[GroupsTableViewCell defaultDetailedLabelFont]};
    CGRect rect = [group.membersString boundingRectWithSize:CGSizeMake([GroupsTableViewCell contentWidth], CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:attributes
                                                    context:nil];
    
    return rect.size.height + 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group = self.groups[indexPath.row];
    
    [YAUser currentUser].currentGroup = group;
    
    [self performSegueWithIdentifier:@"GroupsToGrid" sender:self];
    
}

#pragma mark - Editing
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self leaveGroupAtIndexPath:indexPath];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Leave";
}

- (void)close {
    [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
}

- (void)createGroup {
    [self close];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"NameGroup" sender:self];
    });

}

- (IBAction)unwindToGrid:(id)source {}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.editingGroup = self.groups[indexPath.row];

    [self performSegueWithIdentifier:@"ShowGroupOptions" sender:self];
//    [self close];    
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[YAGroupAddMembersViewController class]]) {
        ((YAGroupAddMembersViewController*)segue.destinationViewController).embeddedMode = self.embeddedMode;
    }
    else if([segue.destinationViewController isKindOfClass:[YAGroupOptionsViewController class]]) {
        ((YAGroupOptionsViewController*)segue.destinationViewController).group = self.editingGroup;
    }
}

- (void)leaveGroupAtIndexPath:(NSIndexPath*)indexPath {
    YAGroup *group = self.groups[indexPath.row];
    
    NSString *muteTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    NSString *muteMessage = [NSLocalizedString(@"Are you sure you would like to leave?", @"") stringByAppendingFormat:@" %@", group.name];
    NSString *confirmTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
        
        BOOL groupWasActive = [[YAUser currentUser].currentGroup isEqual:group];
        
        [group leaveWithCompletion:^(NSError *error) {
            if(!error) {
                if(groupWasActive) {
                    if(self.groups.count) {
                        [YAUser currentUser].currentGroup = self.groups[0];
                    }
                    else
                        [YAUser currentUser].currentGroup = nil;
                    
                    if(![YAUser currentUser].currentGroup) {
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"OnboardingNoGroupsNavigationController"];
                        
                        [UIView transitionWithView:[UIApplication sharedApplication].keyWindow
                                          duration:0.4
                                           options:UIViewAnimationOptionTransitionFlipFromLeft
                                        animations:^{ [UIApplication sharedApplication].keyWindow.rootViewController = viewController; }
                                        completion:nil];
                    }
                }
            }
        }];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}
@end
