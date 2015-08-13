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

@interface YAStreamViewController ()
@property (nonatomic, assign) NSUInteger videosCountBeforeRefresh;
@end

@implementation YAStreamViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        [self initStreamGroup];
        
        return self;
    }
    else
        return nil;
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
        self.group.name = NSLocalizedString(@"Feed", @"");
        self.group.streamGroup = YES;
        [[RLMRealm defaultRealm] addObject:self.group];
        [[RLMRealm defaultRealm] commitWriteTransaction];
    }

}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    [YAUser currentUser].currentGroup = self.group;
//}

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

@end
