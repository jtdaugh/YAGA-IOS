//
//  YAAllVideosViewController.m
//
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAStreamViewController.h"
#import "UIScrollView+SVInfiniteScrolling.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "YAGroup.h"
#import "YAUser.h"
//DEBUG
#import "YAVideo.h"

@interface YAStreamViewController ()
@property (nonatomic, assign) NSUInteger videosCountBeforeRefresh;
@end

@implementation YAStreamViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"name = '%@'", kPublicStreamGroupName]];
        if(groups.count == 1) {
            self.group = [groups objectAtIndex:0];
#warning DEBUG
//            NSMutableArray *a = [NSMutableArray new];
//            for(YAVideo *video in self.group.videos) {
//                [a addObject:video];
//            }
//            for(YAVideo *video in a) {
//                [video removeFromCurrentGroupWithCompletion:nil removeFromServer:NO];
//            }
            [[self.group realm] beginWriteTransaction];
            self.group.nextPageIndex = 0;
            [[self.group realm] commitWriteTransaction];

        }
        else {
            [[RLMRealm defaultRealm] beginWriteTransaction];
            self.group = [YAGroup group];
            self.group.serverId = kPublicStreamGroupName;
            self.group.name = kPublicStreamGroupName;
            [[RLMRealm defaultRealm] addObject:self.group];
            [[RLMRealm defaultRealm] commitWriteTransaction];
            

            
        }
        return self;
    }
    else
        return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)dealloc {
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.group.videos.count;
}

#pragma mark - Private

- (void)setupPullToRefresh {
    [super setupPullToRefresh];
    
    __weak typeof(self) weakSelf = self;
    
    // setup infinite scrolling
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        weakSelf.videosCountBeforeRefresh = weakSelf.group.videos.count;
        [weakSelf.group refresh];
    }];
}

- (void)reloadCollectionView {
    
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSUInteger i = self.videosCountBeforeRefresh; i < self.group.videos.count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:self.videosCountBeforeRefresh++ inSection:0]];
    }
    
    if(indexPaths.count) {
        __weak typeof(self) weakSelf = self;
        [self.collectionView performBatchUpdates:^{
            [weakSelf.collectionView insertItemsAtIndexPaths:(NSArray*)indexPaths];
        } completion:nil];
    }
}
@end
