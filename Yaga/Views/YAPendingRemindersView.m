//
//  YAPendingRemindersView.m
//  Yaga
//
//  Created by valentinkovalski on 8/18/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAPendingRemindersView.h"
#import "YAUser.h"
#import "YAGroupGridViewController.h"

@interface YAPendingRemindersView ()
@property (nonatomic, strong) NSMutableArray *pendingGroupNames;
@end

static NSString *CellIdentifier = @"Cell";

#define kReminderCellHeight 50
#define kReminderMaxCountToShow 4

@implementation YAPendingRemindersView


- (id)init {
    if(self = [super init]) {
        self.dataSource = self;
        self.delegate = self;
        self.separatorColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
        [self registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
        
        //remove extra separators
        self.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)reload {
#warning remove hardcoded pending reminders
    self.pendingGroupNames = [@[@"warriors", @"TMZ", @"warriors", @"TMZ", @"warriors", @"TMZ", @"warriors", @"TMZ"] mutableCopy];
    [self reloadData];
    return;
    self.pendingGroupNames = [NSMutableArray new];
    RLMResults *pendingVideos = [YAVideo objectsWhere:@"pending = 1"];
    for(YAVideo *video in pendingVideos) {
        if(!video.group)
            continue;
        
        //my group?
        NSArray *memberPhones = [video.group.members valueForKey:@"number"];
        if(![memberPhones containsObject:[YAUser currentUser].phoneNumber])
            continue;
        
        //added already
        if([self.pendingGroupNames containsObject:video.group.name])
            continue;
        
        [self.pendingGroupNames addObject:video.group.name];
    }
    [self reloadData];
}

- (CGFloat)maxHeight {
    [self reload];
    
    NSUInteger maxCount = self.pendingGroupNames.count > kReminderMaxCountToShow ? kReminderMaxCountToShow : self.pendingGroupNames.count;
    return maxCount * kReminderCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pendingGroupNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Pending videos in %@", self.pendingGroupNames[indexPath.row]];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Disclosure"]];
    cell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = PRIMARY_COLOR;
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[YAUtils imageWithColor:[UIColor colorWithWhite:1.0 alpha:0.3]]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kReminderCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    [self deselectRowAtIndexPath:indexPath animated:YES];
    
    UINavigationController *navController = [(UITabBarController*)[[[UIApplication sharedApplication] keyWindow] rootViewController] selectedViewController];
    
    RLMResults *results = [YAGroup objectsWhere:[NSString stringWithFormat:@"name = '%@'", self.pendingGroupNames[indexPath.row]]];
    if(results.count) {
        YAGroup *group = results[0];

        YAGroupGridViewController *vc = [YAGroupGridViewController new];
        vc.group = group;
        [navController pushViewController:vc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    // To "clear" the footer view
    return [UIView new];
}
@end
