//
//  MyCrewsViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MyGroupsViewController.h"
#import "YAUser.h"
#import "CreateViewController.h"
#import "GroupsTableViewCell.h"

@interface MyGroupsViewController ()
@property (nonatomic, strong) RLMResults *groups;
@property (nonatomic, strong) UITableView *tableView;
@end

static NSString *CellIdentifier = @"GroupsCell";

@implementation MyGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.groups = [YAGroup allObjects];
    self.view.backgroundColor = self.backgroundColor;
    
    CGFloat width = VIEW_WIDTH * .8;
    
    CGFloat origin = VIEW_HEIGHT *.025;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.3)];
    [titleLabel setText:@"Looks like you're already a part of a group. Pick which one you'd like to go to now."];
    [titleLabel setNumberOfLines:4];
    [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:titleLabel];

    origin = titleLabel.frame.origin.y + titleLabel.frame.size.height + (VIEW_HEIGHT*.04);
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, self.view.bounds.size.height - origin)];
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = self.backgroundColor;

    [self.tableView setSeparatorColor:PRIMARY_COLOR];
    [self.tableView registerClass:[GroupsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    YAGroup *group = [self.groups objectAtIndex:indexPath.row];
    
    cell.textLabel.text = group.name;
    cell.detailTextLabel.text = group.membersString;
    
    cell.selectedBackgroundView = [self createBackgroundViewForCell:cell];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group = self.groups[indexPath.row];
    [[YAUser currentUser] saveUserData:group.groupId forKey:nCurrentGroupId];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    YAGroup *group = self.groups[indexPath.row];
    
    UILabel *tmpLabel = [UILabel new];
    tmpLabel.text = group.membersString;
    tmpLabel.numberOfLines = 0;
    [tmpLabel sizeToFit];
    
    return tmpLabel.bounds.size.height + 70;
}

- (UIView*)createBackgroundViewForCell:(UITableViewCell*)cell {
    UIView *bkgView = [[UIView alloc] initWithFrame:cell.bounds];
    bkgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //inversing color
    CGFloat r,g,b,a;
    [PRIMARY_COLOR getRed:&r green:&g blue:&b alpha:&a];
    
    bkgView.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:0.3];
    return bkgView;
}

@end
