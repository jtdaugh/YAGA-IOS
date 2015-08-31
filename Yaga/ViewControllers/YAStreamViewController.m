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
#import "YAStreamFlexibleNavBar.h"
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
    
    
    //viewWilllApper won't be called if camera is presented on start
    [self setupFlexibleNavBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupFlexibleNavBar];
}


- (void)setupFlexibleNavBar {
    
    self.flexibleNavBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [self.flexibleNavBar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];

    [self.view bringSubviewToFront:self.flexibleNavBar];
    
    self.navigationController.navigationBar.translucent = NO;
    
    self.delegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.flexibleNavBar.behaviorDefiner];
    self.collectionView.delegate = (id<UICollectionViewDelegate>)self.delegateSplitter;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.flexibleNavBar.maximumBarHeight, 0, 0, 0);
    self.collectionView.alwaysBounceVertical = YES;
    
    self.collectionView.pullToRefreshView.originalTopInset = self.collectionView.contentInset.top;
    self.collectionView.contentOffset = CGPointMake(0, -self.flexibleNavBar.maximumBarHeight);
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
