//
//  YAAllVideosViewController.m
//
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAStreamViewController.h"

//DEBUG
#import "YAVideo.h"
#import "YAStandardFlexibleHeightBar.h"

@interface YAStreamViewController ()
@property (nonatomic, assign) NSUInteger videosCountBeforeRefresh;
@end

@implementation YAStreamViewController

- (id)init {
    if(self = [super init]) {
        [self initStreamGroup];

        return self;
    }
    else
        return nil;
}

- (BOOL)cellsShouldShowGroupName {
    return YES;
}

#pragma mark - To Override
- (void)initStreamGroup {
    RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", kPublicStreamGroupId]];
    if(groups.count == 1) {
        self.group = [groups objectAtIndex:0];
    }
    else {
        [[RLMRealm defaultRealm] beginWriteTransaction];
        self.group = [YAGroup group];
        self.group.serverId = kPublicStreamGroupId;
        self.group.name = NSLocalizedString(@"Latest Videos", @"");
        self.group.streamGroup = YES;
        [[RLMRealm defaultRealm] addObject:self.group];
        [[RLMRealm defaultRealm] commitWriteTransaction];
    }
}
- (BLKFlexibleHeightBar *)createNavBar {
    YAStandardFlexibleHeightBar *bar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
    bar.titleLabel.text = self.group.name;
    return bar;
}

#pragma mark - Overriden

- (void)setupPullToRefresh {
    [super setupPullToRefresh];
    
    __weak typeof(self) weakSelf = self;
    
    // setup infinite scrolling
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        weakSelf.videosCountBeforeRefresh = weakSelf.group.videos.count;
        [weakSelf.group refresh];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.collectionView triggerPullToRefresh];
}

@end
