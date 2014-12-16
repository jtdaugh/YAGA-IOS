//
//  ElevatorTableView.m
//  Pic6
//
//  Created by Raj Vir on 9/22/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupListTableView.h"
#import "GroupListCell.h"
#import "YAUser.h"

@interface GroupListTableView ()
@property (nonatomic, strong) RLMResults *groups;
@end

@implementation GroupListTableView

static NSString *CellIdentifier = @"ElevatorCell";

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.dataSource = self;
        [self setContentInset:UIEdgeInsetsZero];
        self.groups = [YAGroup allObjects];
        [self registerClass:[GroupListCell class] forCellReuseIdentifier:CellIdentifier];
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    GroupListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    YAGroup *group = [self.groups objectAtIndex:indexPath.row];
    [cell.title setText:group.name];
    [cell.subtitle setText:group.membersString];
    
    cell.icon = nil;
    return cell;
}

@end
