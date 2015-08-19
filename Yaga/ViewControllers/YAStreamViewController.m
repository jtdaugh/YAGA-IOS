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
#import "YAVideoCell.h"
#import "YAGroupGridViewController.h"
#import "FacebookStyleBarBehaviorDefiner.h"

#define GROUP_LABEL_PROP 0.25

@interface YAStreamViewController () <YAOpenGroupFromVideoCell>
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

- (void)initStreamGroup {
    [NSException raise:@"AbstractMethodCall" format:@"YAStreamViewController must be subclassed"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.gridLayout setItemSize:CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT * (1.0 + GROUP_LABEL_PROP))];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT * (1.0 + GROUP_LABEL_PROP));
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = (YAVideoCell *) [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    cell.groupLabelHeightProportion = GROUP_LABEL_PROP;
    cell.showsGroupLabel = YES;
    cell.groupOpener = self;
    return cell;
}

- (BLKFlexibleHeightBar *)createNavBar {
    YAStandardFlexibleHeightBar *bar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
    bar.titleLabel.text = self.group.name;
    bar.behaviorDefiner = [FacebookStyleBarBehaviorDefiner new];
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

- (void)openGroupForVideo:(YAVideo *)video {
    YAGroupGridViewController *vc = [YAGroupGridViewController new];
    vc.group = video.group;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.collectionView triggerPullToRefresh];
}

@end
