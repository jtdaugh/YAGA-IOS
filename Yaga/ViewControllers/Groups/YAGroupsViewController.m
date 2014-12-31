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
#import "YAGroupMembersViewController.h"

@interface YAGroupsViewController ()
@property (nonatomic, strong) RLMResults *groups;
@property (nonatomic, strong) UIButton *createGroupButton;
@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation YAGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.embeddedMode) {
        UITapGestureRecognizer *tapToClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
        tapToClose.delegate = self;
        [self.view addGestureRecognizer:tapToClose];
    }
    
    self.groups = [YAGroup allObjects];
    self.view.backgroundColor = self.embeddedMode ? [UIColor whiteColor] : [UIColor blackColor];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    CGFloat origin = VIEW_HEIGHT *.025;
    
    
    if(!self.embeddedMode) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
        [titleLabel setText:NSLocalizedString(@"Looks like you're already a part of a group", @"")];
        [titleLabel setNumberOfLines:4];
        [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setTextColor:[UIColor whiteColor]];
        [self.view addSubview:titleLabel];
        origin = titleLabel.frame.origin.y + titleLabel.frame.size.height;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, self.view.bounds.size.height - (VIEW_WIDTH - width)/2 - (self.embeddedMode ? ELEVATOR_MARGIN : 0))];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [self.view.backgroundColor copy];
    
    //    [self.tableView setSeparatorColor:PRIMARY_COLOR];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView registerClass:[GroupsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //ios8 fix for separatorInset
    if ([self.tableView respondsToSelector:@selector(layoutMargins)])
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    if(self.embeddedMode) {
        //create group button
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height+1, VIEW_WIDTH, 1)];
        separatorView.backgroundColor = [UIColor lightGrayColor];
        separatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:separatorView];
        
        
        UIButton *createGroupButton = [[UIButton alloc] initWithFrame:
                                       CGRectMake(44,
                                                  self.tableView.frame.size.height+2,
                                                  VIEW_WIDTH - 44,
                                                  self.view.bounds.size.height - self.tableView.frame.size.height)
                                       ];
        createGroupButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [createGroupButton setTitle:@"Create Group  〉" forState:UIControlStateNormal];
        [createGroupButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
        [createGroupButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [createGroupButton setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
        [createGroupButton addTarget:self action:@selector(createGroup) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:createGroupButton];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    //size to fit table view
    if(!self.embeddedMode) {
        CGFloat rowHeight = [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        CGFloat rowsCount = [self tableView:self.tableView numberOfRowsInSection:0];
        CGFloat contentHeight = rowHeight * rowsCount;
        if(self.tableView.frame.size.height > contentHeight) {
            self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, contentHeight);
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    //center content with header view
    return (self.tableView.frame.size.height - self.tableView.contentSize.height)/2;
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
    
    if(!self.embeddedMode)
        cell.accessoryView = nil;
    
    
    cell.textLabel.textColor = group.muted ? [UIColor lightGrayColor] : PRIMARY_COLOR;
    cell.detailTextLabel.textColor = group.muted ? [UIColor lightGrayColor] : PRIMARY_COLOR;
    cell.selectedBackgroundView = [self createBackgroundViewForCell:cell];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.embeddedMode && indexPath.row == self.groups.count) {
        return 60;
    }
    
    YAGroup *group = self.groups[indexPath.row];
    
    UILabel *tmpLabel = [UILabel new];
    tmpLabel.text = group.membersString;
    tmpLabel.numberOfLines = 0;
    [tmpLabel sizeToFit];
    
    return tmpLabel.bounds.size.height + 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YAGroup *group = self.groups[indexPath.row];
    [YAUser currentUser].currentGroup = group;
    
    if(self.embeddedMode) {
        [self close];
    }
    else
        [self performSegueWithIdentifier:@"SelectExistingGroupAndCompleteOnboarding" sender:self];
    
}

#pragma mark - Editing
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !(self.embeddedMode && indexPath.row == self.groups.count);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        YAGroup *group = self.groups[indexPath.row];
        [[YAServer sharedServer] removeGroup:group
                              withCompletion:^(NSDictionary *response, NSError *error) {
                                  
                                  [[RLMRealm defaultRealm] beginWriteTransaction];
                                  [[RLMRealm defaultRealm] deleteObject:group];
                                  [[RLMRealm defaultRealm] commitWriteTransaction];
                                  [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                              }];
    }
}

- (void)close {
    [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
}

- (void)createGroup {
    [self performSegueWithIdentifier:@"CreateNewGroup" sender:self];
    
    [self close];
}

- (IBAction)unwindFromViewController:(id)source {}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self showGroupOptionsForGroupAtIndex:indexPath];
    
}

#pragma mark - Utils
- (UIView*)createBackgroundViewForCell:(UITableViewCell*)cell {
    UIView *bkgView = [[UIView alloc] initWithFrame:cell.bounds];
    bkgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //get 0.3 alpha from main color
    CGFloat r,g,b,a;
    [PRIMARY_COLOR getRed:&r green:&g blue:&b alpha:&a];
    bkgView.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:0.3];
    return bkgView;
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[YAGroupAddMembersViewController class]]) {
    }
}

#pragma  mark - Alerts
- (void)showGroupOptionsForGroupAtIndex:(NSIndexPath*)indexPath {
    __block YAGroup *group = self.groups[indexPath.row];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:group.name message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit Title", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIAlertController *changeTitleAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CHANGE_GROUP_TITLE", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [changeTitleAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"CHANGE_GROUP_PLACEHOLDER", @"");
            textField.text = [YAUser currentUser].currentGroup.name;
        }];
        [changeTitleAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *newname = [changeTitleAlert.textFields[0] text];
            if(!newname.length)
                return;
            
            [group rename:newname];
            
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }]];
        
        [changeTitleAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        
        [self presentViewController:changeTitleAlert animated:YES completion:nil];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"View/Edit Members", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        YAGroupMembersViewController *membersVC = [[YAGroupMembersViewController alloc] initWithGroup:group];
        [self.navigationController pushViewController:membersVC animated:YES];
        [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
    }]];
    
    NSString *muteTitle = [YAUser currentUser].currentGroup.muted  ?  NSLocalizedString(@"Unmute", @"") : NSLocalizedString(@"Mute", @"");
    muteTitle = [muteTitle stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    
    [alert addAction:[UIAlertAction actionWithTitle:muteTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self muteUnmuteGroupAtIndexPath:indexPath];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:[NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self leaveGroupAtIndexPath:indexPath];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
}
- (void)muteUnmuteGroupAtIndexPath:(NSIndexPath*)indexPath {
    __block YAGroup *group = self.groups[indexPath.row];
    
    NSString *muteTitle = [YAUser currentUser].currentGroup.muted  ?  NSLocalizedString(@"Unmute", @"") : NSLocalizedString(@"Mute", @"");
    muteTitle = [muteTitle stringByAppendingFormat:@" %@", group.name];
    NSString *muteMessage = [YAUser currentUser].currentGroup.muted  ?  NSLocalizedString(@"Recieve notifications from this group", @"") : NSLocalizedString(@"Stop receiving notifications from this group", @"");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
        
        [[RLMRealm defaultRealm] beginWriteTransaction];
        group.muted = !group.muted;
        [[RLMRealm defaultRealm] commitWriteTransaction];
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        //just for now
        NSString *notificationMessage = [NSString stringWithFormat:@"%@ '%@' %@", NSLocalizedString(@"Group", @""), group.name, group.muted ? NSLocalizedString(@"Muted", @"") : NSLocalizedString(@"Unmuted", @"")];
        [YAUtils showNotification:notificationMessage type:AZNotificationTypeSuccess];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)leaveGroupAtIndexPath:(NSIndexPath*)indexPath {
    __block YAGroup *group = self.groups[indexPath.row];
    
    NSString *muteTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    NSString *muteMessage = [NSLocalizedString(@"Are you sure you would like to leave?", @"") stringByAppendingFormat:@" %@", group.name];
    NSString *confirmTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
        
        [[YAServer sharedServer] removeGroup:group withCompletion:^(id response, NSError *error) {
            if(!error) {
                NSString *notificationMessage = [NSString stringWithFormat:@"You have left %@ %@", NSLocalizedString(@"Group", @""), group.name];
                [YAUtils showNotification:notificationMessage type:AZNotificationTypeSuccess];
            }
            else {
                
            }
        }];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
