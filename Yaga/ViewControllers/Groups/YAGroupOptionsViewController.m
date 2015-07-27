//
//  YAGroupOptionsViewController.m
//  Yaga
//
//  Created by valentinkovalski on 4/14/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGroupOptionsViewController.h"
#import "YAGroupAddMembersViewController.h"
#import "YAGroupsNavigationController.h"
#import "YAInviteViewController.h"
#import "YAServer.h"

@interface YAGroupOptionsViewController ()

@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UIButton *leaveButton;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) RLMResults *sortedMembers;

@property (nonatomic, strong) RLMNotificationToken *notificationToken;
@property (nonatomic, strong) NSMutableArray *membersPendingJoin;
@property (nonatomic, strong) NSMutableSet *pendingMembersInProgress;

@property (nonatomic, strong) UIButton *groupNameButton;
@property (nonatomic, strong) YANotificationView *notificationView;

@end

@implementation YAGroupOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMembersTapped:)];
    self.navigationItem.rightBarButtonItem = addButton;
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    const CGFloat buttonWidth = VIEW_WIDTH - 40;
    CGFloat buttonHeight = 54;
    
    self.muteButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, VIEW_HEIGHT - NAV_BAR_HEIGHT - buttonHeight - 16, buttonWidth/2-5, buttonHeight)];
    [self.muteButton setBackgroundColor:[UIColor whiteColor]];
    [self.muteButton setTitle:NSLocalizedString(@"Mute", @"") forState:UIControlStateNormal];
    [self.muteButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:16]];
    [self.muteButton setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
    self.muteButton.layer.cornerRadius = 8.0;
    self.muteButton.layer.borderWidth = 3.f;
    self.muteButton.layer.borderColor = [PRIMARY_COLOR CGColor];
    self.muteButton.layer.masksToBounds = YES;
    [self.muteButton addTarget:self action:@selector(muteTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.muteButton];
    
    self.leaveButton = [[UIButton alloc] initWithFrame:CGRectMake(self.muteButton.frame.origin.x + self.muteButton.frame.size.width + 16, VIEW_HEIGHT - NAV_BAR_HEIGHT - buttonHeight - 16, buttonWidth/2-5, buttonHeight)];
    [self.leaveButton setBackgroundColor:PRIMARY_COLOR];
    [self.leaveButton setTitle:NSLocalizedString(@"Leave", @"") forState:UIControlStateNormal];
    [self.leaveButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:16]];
    [self.leaveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.leaveButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.leaveButton.layer.borderWidth = 2;
    self.leaveButton.layer.cornerRadius = 8.0;
    self.leaveButton.layer.masksToBounds = YES;
    [self.leaveButton addTarget:self action:@selector(leaveTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.leaveButton];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, self.muteButton.frame.origin.y) style:UITableViewStylePlain];

    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [self.view.backgroundColor copy];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self updateMembersPendingJoin];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(groupDidRefresh:)
                                                 name:GROUP_DID_REFRESH_NOTIFICATION
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(groupsDidRefresh:)
                                                 name:GROUPS_REFRESHED_NOTIFICATION
                                               object:nil];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Back"]]];
}

- (void)dealloc {
    [self.group.realm removeNotification:self.notificationToken];
    self.notificationToken = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_DID_REFRESH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUPS_REFRESHED_NOTIFICATION object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = [YAUser currentUser].currentGroup.name;

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    self.sortedMembers = [self.group.members sortedResultsUsingProperty:@"registered" ascending:NO];
    NSString *muteTitle = self.group.muted  ?  NSLocalizedString(@"Unmute", @"") : NSLocalizedString(@"Mute", @"");
    [self.muteButton setTitle:muteTitle forState:UIControlStateNormal];
    
    [self.tableView reloadData];
    
    self.muteButton.hidden = self.leaveButton.hidden = self.group.publicGroup;
    
    [(YAGroupsNavigationController *)self.navigationController showCameraButton:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [(YAGroupsNavigationController *)self.navigationController showCameraButton:YES];

    //crash fixed
    //http://stackoverflow.com/questions/19230446/tableviewcaneditrowatindexpath-crash-when-popping-viewcontroller
    self.tableView.editing = NO;
}

#pragma mark - Event handlers

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editTitleTapped:(id)sender {
    MSAlertController *changeTitleAlert = [MSAlertController alertControllerWithTitle:NSLocalizedString(@"CHANGE_GROUP_TITLE", @"") message:nil preferredStyle:MSAlertControllerStyleAlert];
    
    [changeTitleAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"CHANGE_GROUP_PLACEHOLDER", @"");
        textField.text = self.group.name;
        [textField setKeyboardType:UIKeyboardTypeDefault];
        [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    }];
    [changeTitleAlert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:MSAlertActionStyleDefault handler:^(MSAlertAction *action) {
        NSString *newname = [changeTitleAlert.textFields[0] text];
        if(!newname.length)
            return;
        
        [self.group rename:newname withCompletion:^(NSError *error) {
            if(!error)
                [self.groupNameButton setTitle:newname forState:UIControlStateNormal];
        }];
        
    }]];
    [changeTitleAlert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:MSAlertActionStyleCancel handler:^(MSAlertAction *action) {
    }]];
    [self presentViewController:changeTitleAlert animated:YES completion:nil];
}

- (void)addMembersTapped:(id)sender {
    YAGroupAddMembersViewController *vc = [YAGroupAddMembersViewController new];
    vc.inCreateGroupFlow = NO;
    vc.existingGroup = self.group;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)muteTapped:(id)sender {
    NSString *muteTitle = self.group.muted  ?  NSLocalizedString(@"Unmute", @"") : NSLocalizedString(@"Mute", @"");
    muteTitle = [muteTitle stringByAppendingFormat:@" %@", self.group.name];
    NSString *muteMessage = self.group.muted  ?  NSLocalizedString(@"Recieve notifications from this group", @"") : NSLocalizedString(@"Stop receiving notifications from this group", @"");
    
    MSAlertController *alert = [MSAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:MSAlertControllerStyleAlert];
    
    [alert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:MSAlertActionStyleDefault handler:^(MSAlertAction *action) {
//        [self.navigationController popViewControllerAnimated:YES];        
        
        [self.group muteUnmuteWithCompletion:^(NSError *error) {
            if(!error) {
                //just for now
                //        NSString *notificationMessage = [NSString stringWithFormat:@"%@ '%@' %@", NSLocalizedString(@"Group", @""), self.group.name, self.group.muted ? NSLocalizedString(@"Muted", @"") : NSLocalizedString(@"Unmuted", @"")];
                //        [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
                
                NSString *muteTitle = self.group.muted  ?  NSLocalizedString(@"Unmute", @"") : NSLocalizedString(@"Mute", @"");
                [self.muteButton setTitle:muteTitle forState:UIControlStateNormal];
            }
        }];
    }]];
    
    [alert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:MSAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)leaveTapped:(id)sender {
    NSString *muteTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    NSString *muteMessage = [NSLocalizedString(@"Are you sure you would like to leave?", @"") stringByAppendingFormat:@" %@", self.group.name];
    NSString *confirmTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    
    MSAlertController*alert = [MSAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:MSAlertControllerStyleAlert];
    
    [alert addAction:[MSAlertAction actionWithTitle:confirmTitle style:MSAlertActionStyleDestructive handler:^(MSAlertAction *action) {
        NSString *groupToLeave = self.group.name;
        [self.group leaveWithCompletion:^(NSError *error) {
            if(!error) {
                [YAUser currentUser].currentGroup = nil;
                [self.navigationController popToRootViewControllerAnimated:YES];
                NSString *notificationMessage = [NSString stringWithFormat:@"You have left %@", groupToLeave];
                [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
            }
        }];
    }]];
    
    [alert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:MSAlertActionStyleCancel handler:^(MSAlertAction *action) {
        
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - TableView datasource and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.membersPendingJoin.count > 0 ? 2 : 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.membersPendingJoin.count > 0 ? 40 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *name = @"";
    switch (section) {
        case 0:
            name = NSLocalizedString(@"Requests", @"");;
            break;
        case 1:
            name = NSLocalizedString(@"Members", @"");
            break;
        default:
            name = @"";
            break;
    }
    
    UIView *headerView = [UIView.alloc initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    headerView.backgroundColor = tableView.backgroundColor;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.tableView.frame.size.width - 10, 40)];
    label.text = name;
    label.textColor = PRIMARY_COLOR;
    label.font = [UIFont fontWithName:BOLD_FONT size:20];
    [headerView addSubview:label];
    
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(!self.membersPendingJoin.count)
        return self.sortedMembers.count;
    
    switch (section) {
        case 0:
            return self.membersPendingJoin.count;
            break;
        case 1:
            return self.sortedMembers.count;
            break;
        default:
            return 0;
            break;
    }
}

static NSString *CellID = @"CellID";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
    }
    
    CGRect frame = cell.contentView.frame;
    frame.origin.x = 0;
    [cell setFrame:frame];
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [cell.textLabel setTextColor:[UIColor blackColor]];
    
    if(indexPath.section == 0 && self.membersPendingJoin.count) {
        NSDictionary *pendingMember = self.membersPendingJoin[indexPath.row];
        cell.textLabel.text = pendingMember[@"username"];
        UIView *requestAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 110, 50)];
        
        if( [self.pendingMembersInProgress containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            activityView.center = CGPointMake(requestAccessoryView.center.x + 30, requestAccessoryView.center.y);
            [requestAccessoryView addSubview:activityView];
            [activityView startAnimating];
        }
        else {
            UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
            cancelButton.tag = indexPath.row;
            cancelButton.frame = CGRectMake(0, 8, 50, 34);
            cancelButton.layer.borderWidth = 1.5f;
            cancelButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            cancelButton.layer.cornerRadius = 4;
            [cancelButton setTintColor:[UIColor whiteColor]];
            [cancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [cancelButton setTitle:@"x" forState:UIControlStateNormal];
            cancelButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:26];
            [cancelButton addTarget:self action:@selector(cancelJoinButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            cancelButton.backgroundColor = [UIColor clearColor];
            cancelButton.titleEdgeInsets = UIEdgeInsetsMake(-2, 0, 0, 0);

            [requestAccessoryView addSubview:cancelButton];
            
            UIButton *allowButton = [UIButton buttonWithType:UIButtonTypeCustom];
            allowButton.tag = indexPath.row;
            allowButton.backgroundColor = [UIColor clearColor];
            allowButton.frame = CGRectMake(60, 8, 50, 34);
            allowButton.layer.borderWidth = 1.5f;
            allowButton.layer.borderColor = [PRIMARY_COLOR CGColor];
            allowButton.layer.cornerRadius = 4;
            allowButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:26];
            [allowButton setTintColor:PRIMARY_COLOR];
            [allowButton setTitleColor:PRIMARY_COLOR forState:UIControlStateNormal];
            [allowButton setTitle:@"✓" forState:UIControlStateNormal];
            [allowButton addTarget:self action:@selector(allowJoinButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            allowButton.titleEdgeInsets = UIEdgeInsetsMake(6, 0, 0, 0);
            
            [requestAccessoryView addSubview:allowButton];
        }
        cell.accessoryView = requestAccessoryView;
    }
    else {
        YAContact *contact = self.sortedMembers[indexPath.row];
        NSDictionary *userDict = [[YAUser currentUser].phonebook objectForKey:contact.number];
        cell.textLabel.text = [userDict[@"composite_name"] length] ? userDict[@"composite_name"] : contact.number;
        
        CGRect frame = cell.contentView.frame;
        frame.origin.x = 0;
        [cell setFrame:frame];
        
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        UIButton *inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        inviteButton.tag = indexPath.row;
        [inviteButton.imageView setTintColor:[UIColor blackColor]];
        [inviteButton setImage:[[UIImage imageNamed:@"Envelope"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [inviteButton setFrame:CGRectMake(0, 0, 36, 36)];
        cell.accessoryView = inviteButton;
        [inviteButton addTarget:self action:@selector(inviteTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.indentationLevel = 0;
        cell.indentationWidth = 0.0f;
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        NSDictionary *phonebookItem = [YAUser currentUser].phonebook[contact.number];
        
        if (contact.registered || [phonebookItem[nYagaUser] boolValue])
        {
            cell.textLabel.text = [contact displayName];
            [cell.textLabel setTextColor:PRIMARY_COLOR];
            
            [cell.detailTextLabel setTextColor:PRIMARY_COLOR];
            UIView *accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Monkey_Pink"]];
            [accessoryView setFrame:CGRectMake(0, 0, 36, 36)];
            cell.accessoryView = accessoryView;
            
        } else {
            NSDictionary *userDict = [[YAUser currentUser].phonebook objectForKey:contact.number];
            cell.textLabel.text = [userDict[@"composite_name"] length] ? userDict[@"composite_name"] : contact.number;
            
            [cell.textLabel setTextColor:[UIColor blackColor]];
            
            [cell.detailTextLabel setTextColor:[UIColor blackColor]];
            
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            UIButton *inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            inviteButton.tag = indexPath.row;
            [inviteButton setImage:[[UIImage imageNamed:@"Envelope"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [inviteButton setTintColor:[UIColor blackColor]];
            [inviteButton setFrame:CGRectMake(0, 0, 36, 36)];
            cell.accessoryView = inviteButton;
            [inviteButton addTarget:self action:@selector(inviteTapped:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    [cell setBackgroundColor:[UIColor clearColor]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.group.publicGroup)
        return NO;
    
    if (indexPath.section == 0 && self.membersPendingJoin.count) {
        return NO;
    }
    else {
        return YES;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        YAContact *contact = self.sortedMembers[indexPath.row];
        
        if([contact.number isEqualToString:[YAUser currentUser].phoneNumber]) {
            MSAlertController*alert = [MSAlertController alertControllerWithTitle:NSLocalizedString(@"Can't remove self from the group, use 'Leave' option when selecting group options.", @"") message:nil preferredStyle:MSAlertControllerStyleAlert];
            [alert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:MSAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        NSString *title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Remove", @""), contact.name];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you would like to remove %@ from %@?", @""), contact.name, self.group.name];
        
        MSAlertController*alert = [MSAlertController alertControllerWithTitle:title message:message preferredStyle:MSAlertControllerStyleAlert];
        [alert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"Remove", @"") style:(MSAlertActionStyleDefault) handler:^(MSAlertAction *action) {
            [self.group removeMember:contact withCompletion:nil];
        }]];
        [alert addAction:[MSAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:MSAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Remove";
}

- (void)inviteTapped:(UIButton*)sender {
    YAContact *contactToInvite = self.sortedMembers[sender.tag];
    
    YAInviteViewController *inviteVC = [YAInviteViewController new];
    inviteVC.canNavigateBack = YES;
    inviteVC.inCreateGroupFlow = NO;
    inviteVC.contactsThatNeedInvite = @[[contactToInvite dictionaryRepresentation]];
    [self.navigationController pushViewController:inviteVC animated:YES];
}

- (void)updateMembersPendingJoin {
    NSSet *cancelledJoins = [NSSet setWithArray:[[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] objectForKey:kCancelledJoins]];
    self.membersPendingJoin = [NSMutableArray new];
    
    if([self.group isInvalidated])
        return;
    
    for(YAContact *member in self.group.pending_members) {
        if([member isInvalidated])
            continue;
        
        if(![cancelledJoins containsObject:member.number])
            [self.membersPendingJoin addObject:member];
    }
}

- (void)cancelJoinButtonPressed:(UIButton*)sender {
    NSMutableArray *cancelled = [NSMutableArray arrayWithArray:[[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] objectForKey:kCancelledJoins]];
    YAContact *cancelledContact = self.membersPendingJoin[sender.tag];
    [cancelled addObject:cancelledContact.number];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setObject:cancelled forKey:kCancelledJoins];
    
    [self.membersPendingJoin removeObject:cancelledContact];
    [self.tableView reloadData];
}

- (void)allowJoinButtonPressed:(UIButton*)sender {
    YAContact *allowedContact = self.membersPendingJoin[sender.tag];
    
    if(!self.pendingMembersInProgress)
        self.pendingMembersInProgress = [NSMutableSet set];
    
    [self.pendingMembersInProgress addObject:[NSNumber numberWithInteger:sender.tag]];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];

    [[YAServer sharedServer] addGroupMembersByPhones:@[allowedContact.number] andUsernames:@[] toGroupWithId:self.group.serverId withCompletion:^(id response, NSError *error) {
        
        [self.pendingMembersInProgress removeObject:[NSNumber numberWithInteger:sender.tag]];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if(!error) {
            [self.membersPendingJoin removeObject:allowedContact];
            [self.group refresh];
        }
        else {
            DLog(@"Can't add members");
        }
    }];
}

#pragma mark Group Notifications
- (void)groupDidRefresh:(NSNotification*)notification {
    if([self.group isEqual:notification.object]) {
        [self updateMembersPendingJoin];
        [self.tableView reloadData];
    }
}

- (void)groupsDidRefresh:(NSNotification*)notification {
    if([self.group isInvalidated]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        return;
    }
    
    [self updateMembersPendingJoin];
    [self.tableView reloadData];
}


#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[YAGroupAddMembersViewController class]]) {
//        ((YAGroupAddMembersViewController*)segue.destinationViewController).embeddedMode = YES;
        ((YAGroupAddMembersViewController*)segue.destinationViewController).existingGroup = self.group;
    }
}

- (void)setGroup:(YAGroup *)group {
    _group = group;
    
    self.muteButton.hidden = self.leaveButton.hidden = self.group.publicGroup;
    
    __weak typeof(self) weakSelf = self;
    self.notificationToken = [self.group.realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        if(weakSelf.group.isInvalidated) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
            weakSelf.notificationToken = nil;
        }
        else {
            [weakSelf.tableView reloadData];
        }
    }];
}
@end
