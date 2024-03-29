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
#import "YAVideoCell.h"
#import "YAGroupGridViewController.h"
#import "YABarBehaviorDefiner.h"
#import "BLKDelegateSplitter.h"

@interface YAStreamViewController () <YAOpenGroupFromVideoCell>
@property (nonatomic, assign) NSUInteger videosCountBeforeRefresh;
@property (nonatomic, strong) BLKDelegateSplitter *delegateSplitter;
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

- (void)initStreamGroup {
    [NSException raise:@"AbstractMethodCall" format:@"YAStreamViewController must be subclassed"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.gridLayout setItemSize:CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT - 1)];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT - 1);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = (YAVideoCell *) [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    cell.showsGroupLabel = YES;
    cell.groupOpener = self;
    return cell;
}

#pragma mark - Overriden

- (void)setupPullToRefresh {
    [super setupPullToRefresh];
    
    __weak typeof(self) weakSelf = self;
    
    // setup infinite scrolling
    
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        if ([[NSDate date] timeIntervalSinceDate:weakSelf.group.lastInfiniteScrollEmptyResponseTime] > 10) {
            weakSelf.videosCountBeforeRefresh = weakSelf.group.videos.count;
            [weakSelf.group loadNextPageWithCompletion:nil];
        } else {
            [weakSelf.collectionView.infiniteScrollingView stopAnimating];
        }
    }];
}

- (void)openGroupForVideo:(YAVideo *)video {
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = video.group;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
