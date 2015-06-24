//
//  YAGroupOptionsViewController.m
//  Yaga
//
//  Created by valentinkovalski on 4/14/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGroupOptionsViewController.h"
#import "YAGroupAddMembersViewController.h"
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
@end

#define kCancelledJoins @"kCancelledJoins"

@implementation YAGroupOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    
    [self addNavBarView];
    
    const CGFloat buttonWidth = VIEW_WIDTH - 40;
    CGFloat buttonHeight = 54;
    
    self.muteButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, VIEW_HEIGHT - buttonHeight - 16, buttonWidth/2-5, buttonHeight)];
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
    
    self.leaveButton = [[UIButton alloc] initWithFrame:CGRectMake(self.muteButton.frame.origin.x + self.muteButton.frame.size.width + 16, VIEW_HEIGHT - buttonHeight - 16, buttonWidth/2-5, buttonHeight)];
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
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, VIEW_WIDTH, self.muteButton.frame.origin.y - 64) style:UITableViewStylePlain];

    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [self.view.backgroundColor copy];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self updateMembersPendingJoin];
}

- (void)addNavBarView {
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 64)];
    topBar.backgroundColor = PRIMARY_COLOR;
    self.groupNameButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - 200)/2, 28, 200, 30)];
    self.groupNameButton.tintColor = [UIColor whiteColor];
    self.groupNameButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:20];
    [self.groupNameButton setTitle:self.group.name forState:UIControlStateNormal];
    [self.groupNameButton addTarget:self action:@selector(editTitleTapped:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:self.groupNameButton];
    
    CGFloat addMembersButtonWidth = 100;
    UIButton *addMembersButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    addMembersButton.frame = CGRectMake(VIEW_WIDTH - addMembersButtonWidth - 10, 31, addMembersButtonWidth, 28);
    addMembersButton.tintColor = [UIColor whiteColor];
    addMembersButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [addMembersButton addTarget:self action:@selector(addMembersTapped:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:addMembersButton];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 25, 34, 34)];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [backButton setImage:[[UIImage imageNamed:@"Back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    backButton.tintColor = [UIColor whiteColor];
    [backButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:backButton];
    [self.view addSubview:topBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    self.sortedMembers = [self.group.members sortedResultsUsingProperty:@"registered" ascending:NO];
    NSString *muteTitle = self.group.muted  ?  NSLocalizedString(@"Unmute", @"") : NSLocalizedString(@"Mute", @"");
    [self.muteButton setTitle:muteTitle forState:UIControlStateNormal];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //crash fixed
    //http://stackoverflow.com/questions/19230446/tableviewcaneditrowatindexpath-crash-when-popping-viewcontroller
    self.tableView.editing = NO;
}

#pragma mark - Event handlers

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editTitleTapped:(id)sender {
    UIAlertController *changeTitleAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CHANGE_GROUP_TITLE", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [changeTitleAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"CHANGE_GROUP_PLACEHOLDER", @"");
        textField.text = self.group.name;
        [textField setKeyboardType:UIKeyboardTypeAlphabet];
        [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    }];
    [changeTitleAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *newname = [changeTitleAlert.textFields[0] text];
        if(!newname.length)
            return;
        
        [self.group rename:newname withCompletion:^(NSError *error) {
            if(!error)
                [self.groupNameButton setTitle:newname forState:UIControlStateNormal];
        }];
        
    }]];
    [changeTitleAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
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
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)leaveTapped:(id)sender {
    NSString *muteTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    NSString *muteMessage = [NSLocalizedString(@"Are you sure you would like to leave?", @"") stringByAppendingFormat:@" %@", self.group.name];
    NSString *confirmTitle = [NSLocalizedString(@"Leave", @"") stringByAppendingFormat:@" %@", NSLocalizedString(@"Group", @"")];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:muteTitle message:muteMessage preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
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
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
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
    headerView.backgroundColor = [UIColor clearColor];
    
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
            return 1;
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
    
    YAContact *contact = self.sortedMembers[indexPath.row];
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    NSDictionary *userDict = [[YAUser currentUser].phonebook objectForKey:contact.number];
    cell.textLabel.text = [userDict[@"composite_name"] length] ? userDict[@"composite_name"] : contact.number;
    
    [cell.textLabel setTextColor:[UIColor blackColor]];
    
    if(indexPath.section == 0 && self.membersPendingJoin.count) {
        NSDictionary *pendingMember = self.membersPendingJoin[indexPath.row];
        cell.textLabel.text = pendingMember[@"username"];
        UIView *requestAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
        
        if( [self.pendingMembersInProgress containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            activityView.center = CGPointMake(requestAccessoryView.center.x + 20, requestAccessoryView.center.y);
            [requestAccessoryView addSubview:activityView];
            [activityView startAnimating];
        }
        else {
            UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
            cancelButton.tag = indexPath.row;
            cancelButton.frame = CGRectMake(15, 5, 40, 40);
            cancelButton.layer.borderColor = [[UIColor whiteColor] CGColor];
            cancelButton.layer.borderWidth = 2;
            cancelButton.layer.cornerRadius = cancelButton.frame.size.height/2;
            [cancelButton setTintColor:[UIColor whiteColor]];
            [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [cancelButton setTitle:@"X" forState:UIControlStateNormal];
            [cancelButton addTarget:self action:@selector(cancelJoinButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            cancelButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.2];
            [requestAccessoryView addSubview:cancelButton];
            
            UIButton *allowButton = [UIButton buttonWithType:UIButtonTypeCustom];
            allowButton.tag = indexPath.row;
            allowButton.backgroundColor = [UIColor colorWithRed:55.0/255.0 green:177/255.0 blue:48/255.0 alpha:1.0];
            allowButton.frame = CGRectMake(60, 5, 40, 40);
            allowButton.layer.borderColor = [[UIColor whiteColor] CGColor];
            allowButton.layer.borderWidth = 2;
            allowButton.layer.cornerRadius = cancelButton.frame.size.height/2;
            [allowButton setTintColor:[UIColor whiteColor]];
            [allowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [allowButton setTitle:@"✓" forState:UIControlStateNormal];
            [allowButton addTarget:self action:@selector(allowJoinButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            [requestAccessoryView addSubview:allowButton];
        }
        cell.accessoryView = requestAccessoryView;
    }
    else {
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
        YAContact *contact = self.sortedMembers[indexPath.row];
        
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
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        YAContact *contact = self.sortedMembers[indexPath.row];
        
        if([contact.number isEqualToString:[YAUser currentUser].phoneNumber]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Can't remove self from the group, use 'Leave' option when selecting group options.", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        NSString *title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Remove", @""), contact.name];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you would like to remove %@ from %@?", @""), contact.name, self.group.name];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction *action) {
            [self.group removeMember:contact withCompletion:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
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
    NSSet *cancelledJoins = [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kCancelledJoins]];
    self.membersPendingJoin = [NSMutableArray new];
    
    for(YAContact *member in self.group.pending_members) {
        if(![cancelledJoins containsObject:member.number])
            [self.membersPendingJoin addObject:member];
    }
}

- (void)cancelJoinButtonPressed:(UIButton*)sender {
    NSMutableArray *cancelled = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kCancelledJoins]];
    YAContact *cancelledContact = self.membersPendingJoin[sender.tag];
    [cancelled addObject:cancelledContact.number];
    
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
            [self.tableView reloadData];
        }
        else {
            DLog(@"Can't add members");
        }
    }];
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
    __weak typeof(self) weakSelf = self;
    self.notificationToken = [self.group.realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        if(weakSelf.group.isInvalidated) {
            [self.navigationController popToRootViewControllerAnimated:YES];
            self.notificationToken = nil;
        }
        else {
            [weakSelf.tableView reloadData];
        }
    }];
}
@end
