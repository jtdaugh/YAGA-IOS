//
//  YAGroupMembersViewController.m
//  Yaga
//
//  Created by valentinkovalski on 12/29/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupMembersViewController.h"
#import "YAGroupAddMembersViewController.h"
#import <ClusterPrePermissions.h>

@interface YAGroupMembersViewController ()
@property (nonatomic, strong) YAGroup *group;
@property (nonatomic, strong) RLMResults *filteredMembers;
@end

static NSString *CellID = @"CellID";

@implementation YAGroupMembersViewController

- (id)initWithGroup:(YAGroup*)group {
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        self.group = group;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - view lifetime
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(30, 0, 0, 0);
    
    [self adjustNavigationControls];
    
    self.title = self.group.name;
    self.filteredMembers = [self.group.members sortedResultsUsingProperty:@"registered" ascending:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;;
    
    if(!self.group.members.count)
        [self setEditing:YES animated:YES];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - Navigation bar buttons

- (void)adjustNavigationControls {
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                              target:self
                                                                                              action:@selector(addMembersTapped)];
}

- (void)changeEditingModeTapped {
    ClusterPrePermissions *permissions = [ClusterPrePermissions sharedPermissions];
    [permissions showContactsPermissionsWithTitle:NSLocalizedString(@"Contacts access", nil)
                                          message:NSLocalizedString(@"Grant Yaga access to your contacts list", nil)
                                  denyButtonTitle:NSLocalizedString(@"Deny", nil)
                                 grantButtonTitle:NSLocalizedString(@"Grant", nil)
                                completionHandler:^(BOOL hasPermission, ClusterDialogResult userDialogResult, ClusterDialogResult systemDialogResult) {
                                    if (hasPermission) {
                                        [self setEditing:!self.editing animated:YES];
                                    } else if (!hasPermission
                                               && userDialogResult == ClusterDialogResultNoActionTaken
                                               && systemDialogResult == ClusterDialogResultNoActionTaken) {
                                        NSString *title = NSLocalizedString(@"No contacts list access", nil);
                                        NSString *message = NSLocalizedString(@"Yaga needs acces to your contacts, to add new people.\nPlease, grant access in Settings.app", nil);
                                        NSString *buttonTitle = NSLocalizedString(@"OK", nil);
                                        
                                        [YAUtils showAlertViewWithTitle:title
                                                                message:message
                                                      forViewController:self
                                                          accepthButton:buttonTitle
                                                           cancelButton:nil
                                                           acceptAction:nil
                                                           cancelAction:nil];
                                    }
                                }];
}

- (void)addMembersTapped {
    YAGroupAddMembersViewController *addMembersVC = [YAGroupAddMembersViewController new];
    
    addMembersVC.existingGroup = self.group;
    [self.navigationController pushViewController:addMembersVC animated:YES];
}

- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    // Make sure you call super first
    [super setEditing:editing animated:animated];
    
    [self adjustNavigationControls];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.group.members.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
    }
    
    CGRect frame = cell.contentView.frame;
    frame.origin.x = 0;
    [cell setFrame:frame];
    
    YAContact *contact = self.filteredMembers[indexPath.row];
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if (contact.name.length) {
        cell.textLabel.text = [contact displayName];
    } else {
        cell.textLabel.text = [YAUtils readableNumberFromString:contact.number];
    }
    
    if([[YAUser currentUser].phonebook objectForKey:contact.number]) {
        NSDictionary *userDict = [[YAUser currentUser].phonebook objectForKey:contact.number];
        cell.detailTextLabel.text = userDict[@"composite_name"];
    }
    else
        cell.detailTextLabel.text = @"";
    
    
    if (contact.registered)
    {
        [cell.textLabel setTextColor:PRIMARY_COLOR];
        [cell.detailTextLabel setTextColor:PRIMARY_COLOR];
    } else {
        [cell.textLabel setTextColor:[UIColor whiteColor]];
        [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
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
        YAContact *contact = self.group.members[indexPath.row];
        
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
            [[RLMRealm defaultRealm] beginWriteTransaction];
            [self.group removeMember:contact];
            [[RLMRealm defaultRealm] commitWriteTransaction];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
