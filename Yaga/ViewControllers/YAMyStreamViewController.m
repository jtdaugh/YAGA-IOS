//
//  YAMeViewController.m
//
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAMyStreamViewController.h"
#import "BLKFlexibleHeightBar.h"
#import "YAViewCountManager.h"

@interface YAMyStreamViewController () <YAUserViewCountDelegate>

@property (nonatomic) NSUInteger viewCount;
@property (nonatomic, strong) UILabel *viewCountLabel;

@end

@implementation YAMyStreamViewController

- (void)initStreamGroup {
    RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", kMyStreamGroupId]];
    if(groups.count == 1) {
        self.group = [groups objectAtIndex:0];        
    }
    else {
        [[RLMRealm defaultRealm] beginWriteTransaction];
        self.group = [YAGroup group];
        self.group.serverId = kMyStreamGroupId;
        self.group.name = NSLocalizedString(@"My Videos", @"");
        self.group.streamGroup = YES;
        [[RLMRealm defaultRealm] addObject:self.group];
        [[RLMRealm defaultRealm] commitWriteTransaction];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewCount = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateViewCount];
    [YAViewCountManager sharedManager].userViewCountDelegate = self;
    [[YAViewCountManager sharedManager] monitorUser:[YAUser currentUser].username];
    
    [[Mixpanel sharedInstance] track:@"Viewed My Videos"];

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [YAViewCountManager sharedManager].userViewCountDelegate = nil;
    [[YAViewCountManager sharedManager] monitorUser:nil];
}

- (void)updateViewCount {
    self.viewCountLabel.text = [NSString stringWithFormat:@"%lu Total Views", self.viewCount];
}

#pragma mark - YAUserViewCountDelegate

- (void)userUpdatedWithMyViewCount:(NSUInteger)myViewCount otherViewCount:(NSUInteger)othersViewCount {
    self.viewCount = myViewCount + othersViewCount;
    [self updateViewCount];
}

@end
