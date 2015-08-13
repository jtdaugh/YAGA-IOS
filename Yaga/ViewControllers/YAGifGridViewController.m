//
//  CollectionViewController.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YAGifGridViewController.h"

#import "YAVideoCell.h"

#import "YAUtils.h"
#import "YAServer.h"
#import "YAAssetsCreator.h"

#import "YAPullToRefreshLoadingView.h"
#import "YAGroupsNavigationController.h"
#import "YAGroupOptionsViewController.h"

#import "YANotificationView.h"

#import "YAEventManager.h"
#import "YAPopoverView.h"
#import "BLKDelegateSplitter.h"
#import "BLKFlexibleHeightBar.h"
#import "FacebookStyleBarBehaviorDefiner.h"

@protocol GridViewControllerDelegate;

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YAGifGridViewController ()

@property (nonatomic, assign) BOOL disableScrollHandling;

@property (assign, nonatomic) BOOL assetsPrioritisationHandled;
@property (nonatomic, assign) NSUInteger lastDownloadPrioritizationIndex;

@property (strong, nonatomic) UILabel *toolTipLabel;

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@property (nonatomic) BOOL hasToolTipOnOneOfTheCells;

//needed to have pull down to refresh shown for at least 1 second
@property (nonatomic, strong) NSDate *willRefreshDate;

@property (nonatomic, strong) UILabel *noVideosLabel;

@property (nonatomic) CGPoint lastOffset;
@property (nonatomic) BOOL scrollingFast;
@property (nonatomic) NSTimeInterval lastScrollingSpeedTime;

@property (nonatomic, strong) RLMResults *sortedVideos;

@property (nonatomic, strong) BLKDelegateSplitter *delegateSplitter;
@end

static NSString *cellID = @"Cell";

@implementation YAGifGridViewController

- (void)setGroup:(YAGroup *)group {
    _group = group;
    [self reloadSortedVideos];
}

- (void)reloadSortedVideos {
    if ([self.group.videos count]) {
        self.sortedVideos = [self.group.videos sortedResultsUsingProperty:@"createdAt" ascending:NO];
    } else {
        self.sortedVideos = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.hasToolTipOnOneOfTheCells = NO;
    
    CGFloat spacing = 1.0f;
    
    self.gridLayout = [[UICollectionViewFlowLayout alloc] init];
    [self.gridLayout setMinimumInteritemSpacing:spacing];
    [self.gridLayout setMinimumLineSpacing:spacing];
    [self.gridLayout setItemSize:CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT)];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.gridLayout];
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[YAVideoCell class] forCellWithReuseIdentifier:cellID];
    
    self.flexibleNavBar = [self createNavBar];
    self.delegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.flexibleNavBar.behaviorDefiner];
    self.collectionView.delegate = (id<UICollectionViewDelegate>)self.delegateSplitter;


    [self.collectionView setAllowsMultipleSelection:NO];
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.contentInset = UIEdgeInsetsMake(self.flexibleNavBar.frame.size.height, 0, 0, 0);

    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.flexibleNavBar];
    self.lastOffset = self.collectionView.contentOffset;

    self.lastDownloadPrioritizationIndex = 0;
    
    [self reload];

    [YAEventManager sharedManager].eventCountReceiver = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupWillRefresh:) name:GROUP_WILL_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidChange:)  name:GROUP_DID_CHANGE_NOTIFICATION     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidChange:)     name:VIDEO_CHANGED_NOTIFICATION     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openVideo:)       name:OPEN_VIDEO_NOTIFICATION object:nil];
    
    [self setupPullToRefresh];
    
    [self setupBarButtons];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}


- (BLKFlexibleHeightBar *)createNavBar {
    BLKFlexibleHeightBar *bar = [[BLKFlexibleHeightBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 66)];
    bar.minimumBarHeight = 20;
    bar.behaviorDefiner = [FacebookStyleBarBehaviorDefiner new];
    
    bar.backgroundColor = PRIMARY_COLOR;
    return bar;
}

- (void)setupBarButtons {
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"InfoBar"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(infoPressed)];
    self.navigationItem.rightBarButtonItem = infoButton;
}

- (void)infoPressed {
    if(self.group.publicGroup) {
        [self showHumanityTooltip];
    } else {
        [(YAGroupsNavigationController *)self.navigationController openGroupOptions];
    }
}

- (void)videoWithServerId:(NSString *)serverId
                  localId:(NSString *)localId
        eventCountUpdated:(NSUInteger)eventCount {
    if ((self.scrollingFast) || !eventCount) return; // dont update unless the collection view is still
    __weak YAGifGridViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger index = [self.sortedVideos indexOfObjectWhere:@"(serverId == %@) OR (localId == %@)", serverId, localId];
        if (weakSelf.scrollingFast) return;
        if (index == NSNotFound) {
            return;
        }
        YAVideoCell *cell = (YAVideoCell *)[weakSelf.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        if (cell) {
            DLog(@"Updating comment count to %ld for videoID: %@", eventCount, serverId);
            [cell setEventCount:eventCount];
            
        }
    });

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (YAVideoCell *cell in [self.collectionView visibleCells]) {
        [cell animateGifView:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [YAUtils setVisitedGifGrid];

    if(self.group.publicGroup) {
        if (![YAUtils hasVisitedHumanity]) {
            [self showHumanityTooltip];
            [YAUtils setVisitedHumanity];
        }
    } else {
        if (![YAUtils hasVisitedPrivateGroup]) {
            [self showPrivateGroupTooltip];
            [YAUtils setVisitedPrivateGroup];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    for (YAVideoCell *cell in [self.collectionView visibleCells]) {
        [cell animateGifView:NO];
    }
}

- (void)setupPullToRefresh {
    //pull to refresh
    __weak typeof(self) weakSelf = self;
    
    [self.collectionView addPullToRefreshWithActionHandler:^{
        [weakSelf refreshCurrentGroup];
    }];
    
    YAPullToRefreshLoadingView *loadingView = [[YAPullToRefreshLoadingView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/10, 0, VIEW_WIDTH-VIEW_WIDTH/10/2, self.collectionView.pullToRefreshView.bounds.size.height)];
    
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateLoading];
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateStopped];
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateTriggered];
    
}

- (void)manualTriggerPullToRefresh {
    self.collectionView.contentOffset = CGPointMake(0, -(self.collectionView.contentInset.top + self.collectionView.pullToRefreshView.bounds.size.height));
    [self.collectionView triggerPullToRefresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    DLog(@"memory warning!!");
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_WILL_REFRESH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_DID_REFRESH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_DID_CHANGE_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_VIDEO_NOTIFICATION object:nil];
}

- (void)reload {
    self.navigationItem.title = self.group.name;

    BOOL needRefresh = NO;
    if(!self.sortedVideos || ![self.sortedVideos count])
        needRefresh = YES;
    
    if([self.group.updatedAt compare:self.group.refreshedAt] == NSOrderedDescending) {
        needRefresh = YES;
    }
    
    [self.collectionView reloadData];
    
    if(needRefresh) {
        [self refreshCurrentGroup];
    } else {
        [[YAEventManager sharedManager] groupChanged];
        [self enqueueAssetsCreationJobsStartingFromVideoIndex:0];
    }
}

- (void)videoDidChange:(NSNotification*)notif {

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        YAVideo *video = notif.object;
        
        if(!video.group || [video.group isInvalidated])
            return;
        
        if(![video.group isEqual:self.group])
            return;
        
        if(![notif.userInfo[kShouldReloadVideoCell] boolValue])
            return;
        
        NSUInteger index =[self.sortedVideos indexOfObject:video];
        
        //the following line will ensure indexPathsForVisibleItems will return correct results
        [weakSelf.collectionView layoutIfNeeded];
        
        //invisible? we do not reload then
        if(![[weakSelf.collectionView.indexPathsForVisibleItems valueForKey:@"item"] containsObject:[NSNumber numberWithInteger:index]]) {
            return;
        }
        
        NSUInteger countOfItems = [weakSelf collectionView:weakSelf.collectionView numberOfItemsInSection:0];
        
        if(index != NSNotFound && index <= countOfItems) {
            [weakSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
        }
        else {
            [NSException raise:@"something is really wrong" format:@""];
        }
    });
}

#warning refactor, GifGridController shouldn't pop itself when group is changed
- (void)groupDidChange:(NSNotification*)notif {
//    if (!self.group) {
//        [self.navigationController popViewControllerAnimated:NO];
//        return;
//    }
//    [self.noVideosLabel removeFromSuperview];
//    self.noVideosLabel = nil;
//    [self.toolTipLabel removeFromSuperview];
//    self.toolTipLabel = nil;
//    [self reload];
}

- (void)refreshCurrentGroup {
    [self showActivityIndicator:YES];
    
    [self.group refresh];
}

- (void)groupWillRefresh:(NSNotification*)notification {
    BOOL showPullDownToRefresh = [notification.userInfo[kShowPullDownToRefreshWhileRefreshingGroup] boolValue];
    if(showPullDownToRefresh)
        [self manualTriggerPullToRefresh];
    
    self.willRefreshDate = [NSDate date];
    
    if(showPullDownToRefresh) {
        [self.noVideosLabel removeFromSuperview];
        self.noVideosLabel = nil;
    }
}

- (void)groupDidRefresh:(NSNotification*)notification {
    if(![notification.object isEqual:self.group])
        return;
    
    NSArray *newVideos = notification.userInfo[kNewVideos];
    NSArray *updatedVideos = notification.userInfo[kUpdatedVideos];
    NSArray *deletedVideos = notification.userInfo[kDeletedVideos];
    
    void (^refreshBlock)(void) = ^ {
        
        //do not scroll to the top if infinite scrolling is used
        if(!self.collectionView.infiniteScrollingView && [self collectionView:self.collectionView numberOfItemsInSection:0] > 0) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            [self scrollingDidStop];
        }
        
        [self delayedHidePullToRefresh];
        [self enqueueAssetsCreationJobsStartingFromVideoIndex:0];
    };
    
    if (newVideos.count || deletedVideos.count) {
        [self reloadSortedVideos];
        [self.collectionView reloadData];
        
        refreshBlock();
    }
    else if(updatedVideos.count) {
        NSMutableArray *indexPathsToReload = [NSMutableArray new];
        
        for (YAVideo *video in updatedVideos) {
            NSUInteger index = [self.sortedVideos indexOfObject:video];
            if (index != NSNotFound) {
                if([[self.collectionView.indexPathsForVisibleItems valueForKey:@"item"] containsObject:[NSNumber numberWithInteger:index]]) {
                    [indexPathsToReload addObject:[NSIndexPath indexPathForItem:index inSection:0]];
                }
            }
        }
        if(indexPathsToReload && indexPathsToReload.count) {
            [self.collectionView performBatchUpdates:^{
                [self.collectionView reloadItemsAtIndexPaths:indexPathsToReload];
            } completion:^(BOOL finished) {
                refreshBlock();
            }];
        }
        else {
            [self delayedHidePullToRefresh];
        }
    }
    else {
        [self delayedHidePullToRefresh];
    }
}

- (void)delayedHidePullToRefresh {
    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:self.willRefreshDate];
    
    double hidePullToRefreshAfter = 1 - seconds;
    if(hidePullToRefreshAfter < 0)
        hidePullToRefreshAfter = 0;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(hidePullToRefreshAfter * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.collectionView.pullToRefreshView stopAnimating];
        [weakSelf.collectionView.infiniteScrollingView stopAnimating];
        [weakSelf showNoVideosMessageIfNeeded];
    });
}

- (void)showNoVideosMessageIfNeeded {
    if(!self.sortedVideos.count) {
        //group was sucessfully refreshed
        if([self.group.refreshedAt compare:[NSDate dateWithTimeIntervalSince1970:0]] != NSOrderedSame) {
            //hide spinning monkey and show "no videos" label
            [self showActivityIndicator:NO];

            if(!self.noVideosLabel) {
                self.noVideosLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, self.view.bounds.size.height/2)];
                self.noVideosLabel.font = [UIFont fontWithName:BIG_FONT size:24];
                self.noVideosLabel.text = NSLocalizedString(@"THINGS_ARE_QUIET", @"");
                self.noVideosLabel.textAlignment = NSTextAlignmentCenter;
                self.noVideosLabel.numberOfLines = 0;
                self.noVideosLabel.textColor = PRIMARY_COLOR;
                [self.collectionView addSubview:self.noVideosLabel];
            }
        }
        else {
            [self showActivityIndicator:YES];
        }
    }
    else {
        [self showActivityIndicator:NO];
        [self.noVideosLabel removeFromSuperview];
        self.noVideosLabel = nil;
    }
}

- (void)showActivityIndicator:(BOOL)show {
    if(show) {
        [self.noVideosLabel removeFromSuperview];
        self.noVideosLabel = nil;
        
        //don't show spinning monkey if pull down to refresh is shown
        if(self.collectionView.pullToRefreshView.state != SVPullToRefreshStateStopped) {
            [self.activityView removeFromSuperview];
            self.activityView = nil;
            return;
        }
        
        const CGFloat indicatorWidth  = 50;
        [self.activityView removeFromSuperview];
        if(!self.sortedVideos.count) {
            self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            self.activityView.color = PRIMARY_COLOR;
            self.activityView.frame = CGRectMake(VIEW_WIDTH/2-indicatorWidth/2, VIEW_HEIGHT/5, indicatorWidth, indicatorWidth);
            [self.collectionView addSubview:self.activityView];
            [self.activityView startAnimating];
            
            [self.noVideosLabel removeFromSuperview];
            self.noVideosLabel = nil;
        }
    }
    else {
        if(self.activityView) {
            [self.activityView removeFromSuperview];
            self.activityView = nil;
        }
    }
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.sortedVideos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    YAVideo *video = [self.sortedVideos objectAtIndex:indexPath.item];
    CGFloat randomAlpha = indexPath.row * 13 % 10;
    UIColor *shadeOfPinkBasedOnIndex = [PRIMARY_COLOR colorWithAlphaComponent:(.2 + randomAlpha*.05)];
    [cell setBackgroundColor:shadeOfPinkBasedOnIndex];

    cell.video = video;
    [self setupEventCountForCell:cell];
    
    if (!self.scrolling) {
        [cell renderLightweightContent];
        [cell renderHeavyWeightContent];
    } else {
        if (!self.scrollingFast) {
            [cell renderLightweightContent];
        }
    }
    
    return cell;
}

- (void)setupEventCountForCell:(YAVideoCell *)cell {
    NSString *serverId = [cell.video.serverId copy];
    NSString *localId = [cell.video.localId copy];
    YAVideoServerIdStatus status = [YAVideo serverIdStatusForVideo:cell.video];
    NSString *groupId = [self.group.serverId copy];
    
    NSUInteger eventCount = [[YAEventManager sharedManager] getEventCountForVideoWithServerId:serverId localId:localId serverIdStatus:status];
    [cell setEventCount:eventCount];
    if (!eventCount) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [[YAEventManager sharedManager] fetchEventsForVideoWithServerId:serverId
                                                                    localId:localId
                                                                    inGroup:groupId
                                                         withServerIdStatus:status];
        });
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(YAVideoCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [cell animateGifView:NO];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] boolForKey:kCellWasAlreadyTapped]) {
        [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setBool:YES forKey:kCellWasAlreadyTapped];
        if(self.toolTipLabel){
            [self.toolTipLabel removeFromSuperview];
        }
    }
    
    [self openVideoAtIndexPath:indexPath];
}

- (void)openVideoAtIndexPath:(NSIndexPath*)indexPath {
    
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];

    NSMutableArray *array = [NSMutableArray new];
    for (YAVideo *video in self.sortedVideos) {
        [array addObject:video];
    }
    YASwipingViewController *swipingVC = [[YASwipingViewController alloc] initWithVideos:array initialIndex:indexPath.item];
    swipingVC.delegate = self;
    
    swipingVC.transitioningDelegate = (YAGroupsNavigationController *)self.navigationController;
    swipingVC.modalPresentationStyle = UIModalPresentationCustom;
    
    swipingVC.showsStatusBarOnDismiss = YES;
    
    CGRect initialFrame = attributes.frame;
    initialFrame.origin.y -= self.collectionView.contentOffset.y;
    initialFrame.origin.y += self.view.frame.origin.y;
    
    [((YAGroupsNavigationController *)self.navigationController) setInitialAnimationFrame:initialFrame];
    [((YAGroupsNavigationController *)self.navigationController) setInitialAnimationTransform:CGAffineTransformIdentity];
    
//    [self setInitialAnimationFrame:initialFrame];
    
    [self presentViewController:swipingVC animated:YES completion:nil];
}

- (void)openVideo:(NSNotification*)notif {
    YAVideo *video = notif.userInfo[@"video"];
    NSUInteger videoIndex = [self.sortedVideos indexOfObject:video];
    
    if(videoIndex == NSNotFound) {
        DLog(@"can't find video index in current group");
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:videoIndex inSection:0];
    [self openVideoAtIndexPath:indexPath];
}

#pragma mark - UIScrollView
- (BOOL)calculateScrollingFast {
    if(!self.collectionView.superview) {
        return NO;
    }
    
    CGPoint currentOffset = self.collectionView.contentOffset;
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];

    NSTimeInterval timeDiff = currentTime - self.lastScrollingSpeedTime;
    CGFloat pointsTravelled = currentOffset.y - self.lastOffset.y;
    
    CGFloat pointsPerSecond = fabs(pointsTravelled / timeDiff);
    
    self.lastOffset = currentOffset;
    self.lastScrollingSpeedTime = currentTime;
    
//    DLog(@"SCROLLING FAST: %@. diffY: %f , time: %f", (pointsPerSecond > VIEW_HEIGHT) ? @"YES" : @"NO", pointsTravelled, timeDiff);
    return (pointsPerSecond > VIEW_HEIGHT);
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height == 0) return;
    if(self.disableScrollHandling) {
        return;
    }

    [[YAAssetsCreator sharedCreator] cancelGifOperations];
    
    self.assetsPrioritisationHandled = NO;
    
    
    BOOL fast = [self calculateScrollingFast];
    if (self.scrollingFast && !fast) {
        [self scrollingDidSlowDown];
    }
    self.scrollingFast = fast;
    self.scrolling = YES;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollingDidStop];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollingDidStop];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self scrollingDidStop];
    }
}

// Show the cell gifs & event counts
- (void)scrollingDidSlowDown {
    [self.collectionView layoutIfNeeded]; // Ensure visibleCells returns correct cells
    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        [videoCell renderLightweightContent];
    }
}

// Show the captions
- (void)scrollingDidStop {
    self.scrolling = NO;
    
    [self.collectionView layoutIfNeeded]; // Ensure visibleCells returns correct cells
    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        [videoCell renderLightweightContent]; // Will know if its already been rendered
        [videoCell renderHeavyWeightContent];
    }

    if (!self.assetsPrioritisationHandled) {
        NSNumber *firstVisibleIndex = [[[[self.collectionView indexPathsForVisibleItems] valueForKey:@"item"] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }] firstObject];

        [self enqueueAssetsCreationJobsStartingFromVideoIndex:[firstVisibleIndex integerValue]];
        self.assetsPrioritisationHandled = YES;
    }
    
}

#pragma mark - Assets creation

- (void)enqueueAssetsCreationJobsStartingFromVideoIndex:(NSUInteger)initialIndex {
    BOOL killExisting = NO;
    if (ABS(self.lastDownloadPrioritizationIndex - initialIndex) > kNumberOfItemsBelowToDownload) {
        killExisting = YES;
    }
    self.lastDownloadPrioritizationIndex = initialIndex;
    
    //the following line will ensure indexPathsForVisibleItems will return correct results
    [self.collectionView layoutIfNeeded];
    
    NSMutableArray *visibleVideos = [NSMutableArray new];
    NSMutableArray *invisibleVideos = [NSMutableArray new];
    
    NSUInteger beginIndex = initialIndex;
    if (initialIndex >= kNumberOfItemsBelowToDownload) beginIndex -= kNumberOfItemsBelowToDownload; // Cant always subtract cuz overflow
    NSUInteger endIndex = MIN(self.sortedVideos.count, initialIndex + kNumberOfItemsBelowToDownload);
    
    for(NSUInteger videoIndex = beginIndex; videoIndex < endIndex; videoIndex++) {
        if([[self.collectionView.indexPathsForVisibleItems valueForKey:@"item"] containsObject:[NSNumber numberWithInteger:videoIndex]]) {
            [visibleVideos addObject:[self.sortedVideos objectAtIndex:videoIndex]];
        }
        else {
            [invisibleVideos addObject:[self.sortedVideos objectAtIndex:videoIndex]];
        }
    }
    
    [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVisibleVideos:visibleVideos invisibleVideos:invisibleVideos killExistingJobs:killExisting];
}

#pragma mark - YASwipingControllerDelegate
- (void)swipingController:(id)controller scrollToIndex:(NSUInteger)index {
    NSSet *visibleIndexes = [NSSet setWithArray:[[self.collectionView indexPathsForVisibleItems] valueForKey:@"item"]];
    
    //don't do anything if it's visible already
    if([visibleIndexes containsObject:[NSNumber numberWithInteger:index]]) {
        return;
    }
    
    if(index < [self collectionView:self.collectionView numberOfItemsInSection:0]) {
        UIEdgeInsets tmp = self.collectionView.contentInset;
        
        [self.collectionView setContentInset:UIEdgeInsetsZero];//Make(collectionViewHeight/2, 0, collectionViewHeight/2, 0)];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        
        //even not animated scrollToItemAtIndexPath call takes some time, using hack
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.collectionView.contentInset = tmp;
            
            [weakSelf scrollingDidStop];
        });
    }
}

#pragma mark - tooltips


- (void)showPrivateGroupTooltip {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_GROUP_VISIT_TITLE", @"") bodyText:[NSString stringWithFormat:NSLocalizedString(@"FIRST_GROUP_VISIT_BODY", @""), self.group.name, [self.group.members count]] dismissText:@"Got it" addToView:self.navigationController.view] show];
}


- (void)showHumanityTooltip {
    
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_HUMANITY_VISIT_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_HUMANITY_VISIT_BODY", @"") dismissText:@"Got it" addToView:self.navigationController.view] show];
    
}

@end
