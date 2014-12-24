//
//  MyCrewsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MyGroupsViewController.h"
#import "YAUser.h"
#import "GroupsTableViewCell.h"
#import "AddMembersViewController.h"

@interface MyGroupsViewController ()
@property (nonatomic, strong) RLMResults *groups;
@property (nonatomic, strong) UIButton *createGroupButton;
@end

static NSString *CellIdentifier = @"GroupsCell";
static NSString *CellCreateIdentifier = @"GroupsCellCreate";

@implementation MyGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.showCreateGroupButton) {
        UITapGestureRecognizer *tapToClose = [[UITapGestureRecognizer alloc] initWithTarget:self.delegate action:@selector(closeGroups)];
        tapToClose.delegate = self;
        [self.view addGestureRecognizer:tapToClose];
    }
    
    self.groups = [YAGroup allObjects];
    self.view.backgroundColor = self.backgroundColor;
    
    CGFloat width = VIEW_WIDTH * .8;
    
    CGFloat origin = VIEW_HEIGHT *.025;
    if(self.titleText) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
        [titleLabel setText:@"Looks like you're already a part of a group. Pick which one you'd like to go to now."];
        [titleLabel setNumberOfLines:4];
        [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setTextColor:[UIColor whiteColor]];
        [self.view addSubview:titleLabel];
        origin = titleLabel.frame.origin.y + titleLabel.frame.size.height;
    }
    
    self.tableView.backgroundColor = [UIColor yellowColor];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, self.view.bounds.size.height - origin - 1)];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = self.backgroundColor;
    
    [self.tableView setSeparatorColor:PRIMARY_COLOR];
    [self.tableView registerClass:[GroupsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellCreateIdentifier];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //ios8 fix for separatorInset
    if ([self.tableView respondsToSelector:@selector(layoutMargins)])
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kYACloseGroupsNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self close:nil];
                                                  }];
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

- (void)close:(id)sender {
     [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count + (self.showCreateGroupButton ? 1 : 0);
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
    
    if(self.showCreateGroupButton && indexPath.row == self.groups.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellCreateIdentifier forIndexPath:indexPath];
        cell.textLabel.text = @"Create Group  〉";
        cell.textLabel.font = [UIFont fontWithName:BIG_FONT size:18];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = PRIMARY_COLOR;
    }
    else {
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
    }
    
    //ios8 fix
    if ([cell respondsToSelector:@selector(layoutMargins)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    
    cell.selectedBackgroundView = [self createBackgroundViewForCell:cell];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.showCreateGroupButton && indexPath.row == self.groups.count) {
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
    if(self.showCreateGroupButton && indexPath.row == self.groups.count) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
        [self performSegueWithIdentifier:@"CreateNewGroup" sender:self];
        editingIndex = NSUIntegerMax;
    }
    else {
        YAGroup *group = self.groups[indexPath.row];
        [YAUser currentUser].currentGroup = group;
        
        if(self.showCreateGroupButton) {
            [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
        }
        else
            [self performSegueWithIdentifier:@"SelectExistingGroupAndCompleteOnboarding" sender:self];
    }
}

#pragma mark - Editing
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !(self.showCreateGroupButton && indexPath.row == self.groups.count);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        YAGroup *group = self.groups[indexPath.row];
        [[RLMRealm defaultRealm] beginWriteTransaction];
        [[RLMRealm defaultRealm] deleteObject:group];
        [[RLMRealm defaultRealm] commitWriteTransaction];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (IBAction)unwindFromViewController:(id)source {}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    editingIndex = indexPath.row;
    [self performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
    [self performSegueWithIdentifier:@"CreateNewGroup" sender:self];
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
    if([segue.destinationViewController isKindOfClass:[AddMembersViewController class]]) {
        if(editingIndex != NSUIntegerMax)
            ((AddMembersViewController*)segue.destinationViewController).existingGroup = self.groups[editingIndex];
    }
}

@end
