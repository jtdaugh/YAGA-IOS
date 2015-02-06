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
@property (nonatomic, strong) NSDictionary *groupsUpdatedAt;
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
    
    self.view.backgroundColor = self.embeddedMode ? [UIColor whiteColor] : [UIColor blackColor];
    
    CGFloat width = VIEW_WIDTH * 1.0;
    
    CGFloat origin = VIEW_HEIGHT * 0.1;
    
    CGFloat buttonHeight = ELEVATOR_MARGIN * 1.5;
    
    if(!self.embeddedMode) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2 + 15, origin, width - 30, VIEW_HEIGHT*.3)];
        [titleLabel setText:NSLocalizedString(@"Looks like you're already a part of a group", @"")];
        [titleLabel setNumberOfLines:4];
        [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setTextColor:[UIColor whiteColor]];
        [self.view addSubview:titleLabel];
        origin = titleLabel.frame.origin.y + titleLabel.frame.size.height;
    }
    else {
        origin = 0;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(22, origin, VIEW_WIDTH-22, self.view.bounds.size.height - (self.embeddedMode ? buttonHeight : origin + 10))];

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
//        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height+1, VIEW_WIDTH, 1)];
//        separatorView.backgroundColor = [UIColor lightGrayColor];
//        separatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
//        [self.view addSubview:separatorView];
        
        UIButton *createGroupButton = [[UIButton alloc] initWithFrame:
                                       CGRectMake(0,
                                                  self.tableView.frame.size.height,
                                                  VIEW_WIDTH,
                                                  VIEW_HEIGHT - self.tableView.frame.size.height)
                                       ];
        createGroupButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [createGroupButton setTitle:@"Create Group" forState:UIControlStateNormal];
        [createGroupButton.titleLabel setFont:[UIFont fontWithName:@"Avenir-Black" size:24]];
        [createGroupButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [createGroupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [createGroupButton setBackgroundColor:PRIMARY_COLOR];
        createGroupButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [createGroupButton addTarget:self action:@selector(createGroup) forControlEvents:UIControlEventTouchUpInside];
        [createGroupButton setBackgroundImage:[YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:0.3]] forState:UIControlStateHighlighted];
        [self.view addSubview:createGroupButton];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.groups = [[YAGroup allObjects] sortedResultsUsingProperty:@"updatedAt" ascending:NO];
    
    self.groupsUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    //size to fit table view
    if(!self.embeddedMode) {
        [self.tableView reloadData];
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
    cell.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:cell.bounds alpha:0.3];
    
    NSDate *localGroupUpdateDate = [self.groupsUpdatedAt objectForKey:group.localId];
    if(self.embeddedMode) {
        if(!localGroupUpdateDate || [group.updatedAt compare:localGroupUpdateDate] == NSOrderedDescending) {
            UIImage *img = [YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:0.3]];
            cell.imageView.image = img;
        }
        else {
            UIImage *img = [YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:0.0]];
            cell.imageView.image = img;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.embeddedMode && indexPath.row == self.groups.count) {
        return 60;
    }
    
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
        [self leaveGroupAtIndexPath:indexPath];
    }
}

- (void)close {
    [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
}

- (void)createGroup {
        [self close];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"ShowAddMembers" sender:self];
    });

}

- (IBAction)unwindToGrid:(id)source {}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self showGroupOptionsForGroupAtIndex:indexPath];
    
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[YAGroupAddMembersViewController class]]) {
        ((YAGroupAddMembersViewController*)segue.destinationViewController).embeddedMode = self.embeddedMode;
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
            textField.text = group.name;
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
    
    NSString *muteTitle = group.muted  ?  NSLocalizedString(@"Unmute", @"") : NSLocalizedString(@"Mute", @"");
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
    
    NSString *muteTitle = group.muted  ?  NSLocalizedString(@"Unmute", @"") : NSLocalizedString(@"Mute", @"");
    muteTitle = [muteTitle stringByAppendingFormat:@" %@", group.name];
    NSString *muteMessage = group.muted  ?  NSLocalizedString(@"Recieve notifications from this group", @"") : NSLocalizedString(@"Stop receiving notifications from this group", @"");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
        
        [group muteUnmute];
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        //just for now
        NSString *notificationMessage = [NSString stringWithFormat:@"%@ '%@' %@", NSLocalizedString(@"Group", @""), group.name, group.muted ? NSLocalizedString(@"Muted", @"") : NSLocalizedString(@"Unmuted", @"")];
        [YAUtils showNotification:notificationMessage type:AZNotificationTypeSuccess];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)leaveGroupAtIndexPath:(NSIndexPath*)indexPath {
    YAGroup *group = self.groups[indexPath.row];
    
    NSString *muteTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    NSString *muteMessage = [NSLocalizedString(@"Are you sure you would like to leave?", @"") stringByAppendingFormat:@" %@", group.name];
    NSString *confirmTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
        
        NSString *groupToLeave = group.name;
        
        BOOL groupWasActive = [[YAUser currentUser].currentGroup isEqual:group];
        
        [group leave];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if(groupWasActive) {
            if(self.groups.count)
                [YAUser currentUser].currentGroup = self.groups[0];
            else
                [YAUser currentUser].currentGroup = nil;
            
            if([YAUser currentUser].currentGroup) {
                NSString *notificationMessage = [NSString stringWithFormat:@"You have left %@. Current group is %@.", groupToLeave, [YAUser currentUser].currentGroup.name];
                [YAUtils showNotification:notificationMessage type:AZNotificationTypeSuccess];
                [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            }
            else {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"OnboardingNoGroupsNavigationController"];
                
                [UIView transitionWithView:[UIApplication sharedApplication].keyWindow
                                  duration:0.4
                                   options:UIViewAnimationOptionTransitionFlipFromLeft
                                animations:^{ [UIApplication sharedApplication].keyWindow.rootViewController = viewController; }
                                completion:nil];
            }
        }
        else {
            NSString *notificationMessage = [NSString stringWithFormat:@"You have left %@", groupToLeave];
            [YAUtils showNotification:notificationMessage type:AZNotificationTypeSuccess];
        }
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
