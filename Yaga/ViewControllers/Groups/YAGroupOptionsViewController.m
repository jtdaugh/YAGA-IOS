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
@property (nonatomic, strong) UIButton *addMembersButton;
@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UIButton *leaveButton;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) RLMResults *sortedMembers;

@property (nonatomic, strong) RLMNotificationToken *notificationToken;
@property (nonatomic, strong) NSMutableArray *membersPendingJoin;
@end

#define kCancelledJoins @"kCancelledJoins"

@implementation YAGroupOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit Title", @"") style:UIBarButtonItemStylePlain target:self action:@selector(editTitleTapped:)];
    
    self.view.backgroundColor = PRIMARY_COLOR;
    
    const CGFloat buttonWidth = VIEW_WIDTH - 40;
    CGFloat buttonHeight = 54;
    
    self.addMembersButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, 60, buttonWidth, VIEW_HEIGHT*.08)];
    [self.addMembersButton setBackgroundColor:[UIColor whiteColor]];
    [self.addMembersButton setTitle:NSLocalizedString(@"Invite Members", @"") forState:UIControlStateNormal];
    [self.addMembersButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:20]];
    [self.addMembersButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.addMembersButton.layer.cornerRadius = 8.0;
    self.addMembersButton.layer.masksToBounds = YES;
    [self.addMembersButton addTarget:self action:@selector(addMembersTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addMembersButton];
    
    self.muteButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, VIEW_HEIGHT - buttonHeight - 16, buttonWidth/2-5, buttonHeight)];
    [self.muteButton setBackgroundColor:[UIColor whiteColor]];
    [self.muteButton setTitle:NSLocalizedString(@"Mute", @"") forState:UIControlStateNormal];
    [self.muteButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:16]];
    [self.muteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.muteButton.layer.cornerRadius = 8.0;
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
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.addMembersButton.frame.origin.y + self.addMembersButton.frame.size.height + 10, VIEW_WIDTH, self.muteButton.frame.origin.y - (self.addMembersButton.frame.origin.y + self.addMembersButton.frame.size.height) - 20) style:UITableViewStylePlain];
                                                                   
    self.tableView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = PRIMARY_COLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self updateMembersPendingJoin];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.translucent = YES;
    
    self.title = self.group.name;
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
                self.title = newname;
        }];

    }]];
    [changeTitleAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:changeTitleAlert animated:YES completion:nil];
}

- (void)addMembersTapped:(id)sender {
    [self performSegueWithIdentifier:@"AddMembersFromGroupOptions" sender:self];
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
        
        BOOL groupWasActive = [[YAUser currentUser].currentGroup isEqual:self.group];
        
        [self.group leaveWithCompletion:^(NSError *error) {
            if(!error) {
                
                [self.navigationController popViewControllerAnimated:YES];
                
                if(groupWasActive) {
                    if([YAGroup allObjects].count) {
                        [YAUser currentUser].currentGroup = [YAGroup allObjects][0];
                    }
                    else
                        [YAUser currentUser].currentGroup = nil;
                    
                    if([YAUser currentUser].currentGroup) {
                        NSString *notificationMessage = [NSString stringWithFormat:@"You have left %@. Current group is %@.", groupToLeave, [YAUser currentUser].currentGroup.name];
                        [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
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
                    [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
                }
                
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
    headerView.backgroundColor = PRIMARY_COLOR;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.tableView.frame.size.width - 10, 40)];
    label.text = name;
    label.textColor = [UIColor whiteColor];
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
    
    if(indexPath.section == 0 && self.membersPendingJoin.count) {
        NSDictionary *pendingMember = self.membersPendingJoin[indexPath.row];
        cell.textLabel.text = pendingMember[@"username"];
        UIView *requestAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
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
        [requestAccessoryView addSubview:cancelButton];
        
        UIButton *allowButton = [UIButton buttonWithType:UIButtonTypeCustom];
        allowButton.tag = indexPath.row;
        allowButton.backgroundColor = [UIColor greenColor];
        allowButton.frame = CGRectMake(60, 5, 40, 40);
        allowButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        allowButton.layer.borderWidth = 2;
        allowButton.layer.cornerRadius = cancelButton.frame.size.height/2;
        [allowButton setTintColor:[UIColor whiteColor]];
        [allowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [allowButton setTitle:@"V" forState:UIControlStateNormal];
        [allowButton addTarget:self action:@selector(allowJoinButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [requestAccessoryView addSubview:allowButton];
        
        cell.accessoryView = requestAccessoryView;
    }
    else {
        CGRect frame = cell.contentView.frame;
        frame.origin.x = 0;
        [cell setFrame:frame];
        
        YAContact *contact = self.sortedMembers[indexPath.row];
        
        cell.indentationLevel = 0;
        cell.indentationWidth = 0.0f;
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        NSDictionary *phonebookItem = [YAUser currentUser].phonebook[contact.number];
        if (contact.registered || [phonebookItem[nYagaUser] boolValue])
        {
            cell.textLabel.text = [contact displayName];
            [cell.textLabel setTextColor:[UIColor blackColor]];
            
            [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
            UIView *accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Monkey"]];
            [accessoryView setFrame:CGRectMake(0, 0, 36, 36)];
            cell.accessoryView = accessoryView;
            
        } else {
            NSDictionary *userDict = [[YAUser currentUser].phonebook objectForKey:contact.number];
            cell.textLabel.text = [userDict[@"composite_name"] length] ? userDict[@"composite_name"] : contact.number;
            
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            
            [cell.detailTextLabel setTextColor:[UIColor blackColor]];
            
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            UIButton *inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            inviteButton.tag = indexPath.row;
            [inviteButton setImage:[UIImage imageNamed:@"Envelope"] forState:UIControlStateNormal];
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
    inviteVC.inOnboardingFlow = NO;
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
    
    [[YAServer sharedServer] addGroupMembersByPhones:@[allowedContact.number] andUsernames:@[] toGroupWithId:self.group.serverId withCompletion:^(id response, NSError *error) {
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
        ((YAGroupAddMembersViewController*)segue.destinationViewController).embeddedMode = YES;
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
