//
//  YAPostToGroupsViewController.m
//  Yaga
//
//  Created by valentinkovalski on 8/14/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAPostToGroupsViewController.h"
#import "UIImage+Color.h"
#import "NameGroupViewController.h"
#import "YAGroup.h"
#import "YAPostGroupCell.h"
#import "YAAssetsCreator.h"

@interface YAPostToGroupsViewController ()
@property (nonatomic, strong) RLMResults *groups;
@property (nonatomic, strong) NSArray *pendingGroups;

@property (nonatomic, strong) NSMutableArray *selectedGroups;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) UITableView *tableView;
@end

#define kGroupRowHeight 60
#define kSendButtonHeight 70

#define kCellId @"groupCell"
@implementation YAPostToGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"Post To Channel", @"");
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]]
                                                 forBarPosition:UIBarPositionAny
                                                     barMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-1000, -1000) forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.tintColor = SECONDARY_COLOR;
    
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     SECONDARY_COLOR,
                                                                     NSForegroundColorAttributeName,nil]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewGroup)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[YAPostGroupCell class] forCellReuseIdentifier:kCellId];
    self.tableView.rowHeight = 60;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.editing = NO;
    [self.view addSubview:self.tableView];
    
    //replace this code
    RLMResults *groups = [[YAGroup allObjects] objectsWhere:@"streamGroup = 0 && publicGroup == 0 && name != 'EmptyGroup'"];
    
    
    self.groups = [groups sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"publicGroup" ascending:NO], [RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    
    //mocking server code
    self.pendingGroups = @[@{@"name" : @"Dummy"}];
    
    self.selectedGroups = [NSMutableArray new];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, kSendButtonHeight);
    [self.sendButton setBackgroundColor:[UIColor colorWithRed:0 green:113.0/255.0 blue:185.0/255.0 alpha:1.0]];

    [self.view addSubview:self.sendButton];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:30];
    //[self.sendButton setImage:[UIImage imageNamed:@"Disclosure"] forState:UIControlStateNormal];
    //[self.sendButton setImageEdgeInsets:UIEdgeInsetsMake(0, self.view.bounds.size.width - 50, 0, 0)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger result = self.groups.count ? 1 : 0;
    
    result += self.pendingGroups.count ? 1 : 0;
    
    DLog(@"numberOfSectionsInTableView: %lu", result);
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger result = section == 0 ? self.groups.count : self.pendingGroups.count;
    
    DLog(@"numberOfRows: %lu inSection: %lu", result, section);
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *result = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 40)];
    result.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 15, VIEW_WIDTH - 5, 20)];
    label.font = [UIFont fontWithName:BOLD_FONT size:14];
    label.textColor = SECONDARY_COLOR;
    label.text = section == 0 ? @"HOSTING" : @"ALL (Pending approval from Host)";
    [result addSubview:label];
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YAPostGroupCell *cell = (YAPostGroupCell*)[tableView dequeueReusableCellWithIdentifier:kCellId forIndexPath:indexPath];
    
    if(indexPath.section == 0) {
        YAGroup *group = self.groups[indexPath.item];
        
        cell.textLabel.text = group.name;
        [cell setSelectionColor:[UIColor colorWithRed:46.0f/255.0f green:175.0f/255.0f blue:99.0f/255.0f alpha:1.0]];
    }
    else {
        cell.textLabel.text = [self.pendingGroups[indexPath.item] objectForKey:@"name"];
        [cell setSelectionColor:[UIColor lightGrayColor]];
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showHidePostMessage];
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showHidePostMessage];
}

#pragma mark - Table View Delegate


#pragma mark - Private
- (void)addNewGroup {
    NameGroupViewController *nameGroupVC = [NameGroupViewController new];
    [self.navigationController pushViewController:nameGroupVC animated:YES];
}

- (void)showHidePostMessage {
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];

    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        
        if(selectedIndexPaths.count > 0) {
            NSString *pluralSuffix = selectedIndexPaths.count == 1 ? @" >" : @"s >";
            NSString *sendTitle = [NSString stringWithFormat:@"Send to %lu channel%@", selectedIndexPaths.count, pluralSuffix];
            
            [self.sendButton setTitle:sendTitle forState:UIControlStateNormal];
            self.sendButton.frame = CGRectMake(0, self.view.bounds.size.height - kSendButtonHeight, self.view.bounds.size.width, kSendButtonHeight);
        }
        else {
            self.sendButton.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, kSendButtonHeight);
        }
        
    }completion:^(BOOL finished) {
        
    }];
}

- (void)sendButtonTapped {
    NSMutableArray *groups = [NSMutableArray new];
    
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        //works only for my groups for now
        if(indexPath.section == 0){
            YAGroup *group = self.groups[indexPath.item];
            [groups addObject:group];
        }
    }
    if(groups.count) {
        [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:
                                                    self.settings[@"videoUrl"]
                                                    withCaptionText:self.settings[@"captionText"]
                                                                  x:[self.settings[@"captionX"] floatValue]
                                                                  y:[self.settings[@"captionY"]  floatValue]
                                                              scale:[self.settings[@"captionScale"] floatValue] rotation:[self.settings[@"captionRotation"] floatValue]
                                                        addToGroups:groups];
        
        [[Mixpanel sharedInstance] track:@"Video posted"];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }
    
}

@end
