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

- (BLKFlexibleHeightBar *)createNavBar {
    BLKFlexibleHeightBar *bar = [super createNavBar];
    CGRect frame = bar.frame;
    frame.size.height += 30;
    bar.frame = frame;
    bar.maximumBarHeight = frame.size.height;
    
    UILabel *viewCountLabel = [UILabel new];
    viewCountLabel.textColor = [UIColor whiteColor];
    viewCountLabel.font = [UIFont fontWithName:BOLD_FONT size:13];
    viewCountLabel.textAlignment = NSTextAlignmentCenter;
    BLKFlexibleHeightBarSubviewLayoutAttributes *expanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    expanded.frame = CGRectMake(50, bar.frame.size.height - 30, VIEW_WIDTH - 100, 20);
    [viewCountLabel addLayoutAttributes:expanded forProgress:0.0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *collapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:expanded];
    collapsed.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -frame.size.height + 20), 0.2, 0.2);
    collapsed.alpha = 0.0;
    [viewCountLabel addLayoutAttributes:collapsed forProgress:1.0];
    
    [bar addSubview:viewCountLabel];
    self.viewCountLabel = viewCountLabel;
    return bar;
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
