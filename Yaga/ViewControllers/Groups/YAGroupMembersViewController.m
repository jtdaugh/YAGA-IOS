//
//  YAGroupMembersViewController.m
//  Yaga
//
//  Created by valentinkovalski on 12/29/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupMembersViewController.h"
#import "YAGroupAddMembersViewController.h"

@interface YAGroupMembersViewController ()
@property (nonatomic, strong) YAGroup *group;
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;;
}

#pragma mark - Navigation bar buttons

- (void)adjustNavigationControls {

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:self.editing ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit target:self action:@selector(changeEditingModeTapped)];
    
    if(self.tableView.editing) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMembersTapped)];
    }
    else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStylePlain target:self action:@selector(backTapped)];
    }
    
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{
                                                                     NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18],
                                                                     } forState:UIControlStateNormal];
    [self.navigationItem.rightBarButtonItem setTintColor:PRIMARY_COLOR];
    
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{
                                                                    NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18],
                                                                    } forState:UIControlStateNormal];
    [self.navigationItem.leftBarButtonItem setTintColor:PRIMARY_COLOR];// : [UIColor lightGrayColor]];
}

- (void)changeEditingModeTapped {
    [self setEditing:!self.editing animated:YES];
}

- (void)addMembersTapped {
    YAGroupAddMembersViewController *addMembersVC = [YAGroupAddMembersViewController new];
    addMembersVC.selectedContacts = [[NSMutableArray alloc] initWithCapacity:self.group.members.count];
    
    for(YAContact *contact in self.group.members) {
        [addMembersVC.selectedContacts addObject:[contact dictionaryRepresentation]];
    }
    
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
    
    YAContact *contact = self.group.members[indexPath.row];
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName];
    
    cell.detailTextLabel.text = contact.readableNumber;
    
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
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
        NSString *title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Remove", @""), contact.name];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you would like to remove %@ from %@?", @""), contact.name, self.group.name];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction *action) {
            [[RLMRealm defaultRealm] beginWriteTransaction];
            [self.group.members removeObjectAtIndex:indexPath.row];
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
