//
//  CollectionViewController.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YACollectionViewController.h"

#import "YAVideoCell.h"

#import "YAUser.h"
#import "YAUtils.h"
#import "YAServer.h"

#import "UIScrollView+SVPullToRefresh.h"
#import "YAAssetsCreator.h"

#import "YAPullToRefreshLoadingView.h"

#import "YANotificationView.h"

#import "YAEventManager.h"
#import "YAPopoverView.h"

@protocol GridViewControllerDelegate;

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;

@property (nonatomic, assign) BOOL disableScrollHandling;

@property (nonatomic, assign) NSUInteger paginationThreshold;

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

@end

static NSString *cellID = @"Cell";

#define kPaginationItemsCountToStartLoadingNextPage 5

@implementation YACollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hasToolTipOnOneOfTheCells = NO;
    CGFloat spacing = 1.0f;
    
    self.gridLayout = [[UICollectionViewFlowLayout alloc] init];
    [self.gridLayout setMinimumInteritemSpacing:spacing];
    [self.gridLayout setMinimumLineSpacing:spacing];
    [self.gridLayout setItemSize:CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT)];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.gridLayout];
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[YAVideoCell class] forCellWithReuseIdentifier:cellID];
    [self.collectionView setAllowsMultipleSelection:NO];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.contentInset = UIEdgeInsetsMake(VIEW_HEIGHT/2 + 2 - CAMERA_MARGIN, 0, 0, 0);
    [self.view addSubview:self.collectionView];
    self.collectionView.frame = self.view.bounds;
    
    self.lastOffset = self.collectionView.contentOffset;
    
    
    [self reload];

    [YAEventManager sharedManager].eventCountReceiver = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupWillRefresh:) name:GROUP_WILL_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidChange:)  name:GROUP_DID_CHANGE_NOTIFICATION     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidChange:)     name:VIDEO_CHANGED_NOTIFICATION     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToCell:)    name:SCROLL_TO_CELL_INDEXPATH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openVideo:)       name:OPEN_VIDEO_NOTIFICATION object:nil];
    
    [self setupPullToRefresh];
}

- (void)videoWithServerId:(NSString *)serverId
                  localId:(NSString *)localId
        eventCountUpdated:(NSUInteger)eventCount {
    if ((self.scrollingFast) || !eventCount) return; // dont update unless the collection view is still
    __weak YACollectionViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger index = [[YAUser currentUser].currentGroup.videos indexOfObjectWhere:@"(serverId == %@) OR (localId == %@)", serverId, localId];
        if (weakSelf.scrollingFast) return;
        if (index == NSNotFound) {
            return;
        }
        YAVideoCell *cell = (YAVideoCell *)[weakSelf.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        if (cell) {
            DLog(@"Updating comment count for videoID: %@", serverId);
            [cell setEventCount:eventCount];
            
        }
    });

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [YAUtils setVisitedGifGrid];
    [self.delegate swapOutOfOnboardingState];
    [self.delegate updateCameraAccessoriesWithViewIndex:1];

    if ([YAUser currentUser].currentGroup.members.count == 1) {
        if (![YAUtils hasVisitedFriendChat]) {
            [self showFriendChatTooltip];
            [YAUtils setVisitedFriendChat];
        }
    } else {
        if (![YAUtils hasVisitedPrivateGroup]) {
            [self showPrivateGroupTooltip];
            [YAUtils setVisitedPrivateGroup];
        }
    }
}

- (void)scrollToCell:(NSNotification *)notif
{
    YAVideoCell *cell = notif.object;
    
    const CGFloat kKeyboardHeight = 216.f;
    CGFloat offset = cell.frame.origin.y - self.collectionView.contentOffset.y + kKeyboardHeight + cell.frame.size.height;
    CGFloat pullUpHeight = offset - self.collectionView.frame.size.height;
    if (pullUpHeight > 0.f) {
        self.disableScrollHandling = YES;
        [self.collectionView setContentOffset:CGPointMake(0.f, self.collectionView.contentOffset.y + pullUpHeight) animated:YES];
        self.disableScrollHandling = NO;
    }
    
}

- (void)setupPullToRefresh {
    //pull to refresh
    __weak typeof(self) weakSelf = self;
    
    [self.collectionView addPullToRefreshWithActionHandler:^{
        [weakSelf refreshCurrentGroup];
    }];
    
    //    self.collectionView.pullToRefreshView.
    
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCROLL_TO_CELL_INDEXPATH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_VIDEO_NOTIFICATION object:nil];
}

- (void)reload {
    self.paginationThreshold = kPaginationDefaultThreshold;
    
    BOOL needRefresh = NO;
    if(![YAUser currentUser].currentGroup.videos || ![[YAUser currentUser].currentGroup.videos count])
        needRefresh = YES;
    
    if([[YAUser currentUser].currentGroup.updatedAt compare:[YAUser currentUser].currentGroup.refreshedAt] == NSOrderedDescending) {
        needRefresh = YES;
    }
    
    [self.collectionView reloadData];
    
    if(needRefresh) {
        [self refreshCurrentGroup];
    } else {
        [[YAEventManager sharedManager] groupChanged:[YAUser currentUser].currentGroup];
        [self enqueueAssetsCreationJobsStartingFromVideoIndex:0];
    }
}

- (void)videoDidChange:(NSNotification*)notif {

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        YAVideo *video = notif.object;
        
        if(!video.group || [video.group isInvalidated])
            return;
        
        if(![video.group isEqual:[YAUser currentUser].currentGroup])
            return;
        
        if(![notif.userInfo[kShouldReloadVideoCell] boolValue])
            return;
        
        NSUInteger index =[[YAUser currentUser].currentGroup.videos indexOfObject:video];
        
        //the following line will ensure indexPathsForVisibleItems will return correct results
        [weakSelf.collectionView layoutIfNeeded];
        
        //invisible? we do not reload then
        if(![[weakSelf.collectionView.indexPathsForVisibleItems valueForKey:@"row"] containsObject:[NSNumber numberWithInteger:index]]) {
            return;
        }
        
        NSUInteger countOfItems = [weakSelf collectionView:weakSelf.collectionView numberOfItemsInSection:0];
        
        if(index != NSNotFound && index <= countOfItems) {
            [weakSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]];
        }
        else {
            [NSException raise:@"something is really wrong" format:@""];
        }
    });
}

- (void)groupDidChange:(NSNotification*)notif {
    if (![YAUser currentUser].currentGroup) {
        [self.navigationController popViewControllerAnimated:NO];
        return;
    }
    [self.noVideosLabel removeFromSuperview];
    self.noVideosLabel = nil;
    [self.toolTipLabel removeFromSuperview];
    self.toolTipLabel = nil;
    [self reload];
}

- (void)refreshCurrentGroup {
    [self showActivityIndicator:YES];
    
    [[YAUser currentUser].currentGroup refresh];
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
    if(![notification.object isEqual:[YAUser currentUser].currentGroup])
        return;
    
    NSArray *newVideos = notification.userInfo[kNewVideos];
    NSArray *updatedVideos = notification.userInfo[kUpdatedVideos];
    NSArray *deletedVideos = notification.userInfo[kDeletedVideos];
    
    void (^refreshBlock)(void) = ^ {
        [self enqueueAssetsCreationJobsStartingFromVideoIndex:0];
        if([self collectionView:self.collectionView numberOfItemsInSection:0] > 0)
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        
        [self delayedHidePullToRefresh];
    };
    
    if (newVideos.count || deletedVideos.count) {
        [self.collectionView reloadData];
        refreshBlock();
    }
    else if(updatedVideos.count) {
        NSMutableArray *indexPathsToReload = [NSMutableArray new];
        
        for (YAVideo *video in updatedVideos) {
            NSUInteger index = [[YAUser currentUser].currentGroup.videos indexOfObject:video];
            if(index != NSNotFound && index < [self.collectionView numberOfItemsInSection:0]) {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
        }
        if(indexPathsToReload.count) {
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
        [weakSelf showNoVideosMessageIfNeeded];
    });
}

- (void)showCellTooltipIfNeeded {
//    if(![[NSUserDefaults standardUserDefaults] boolForKey:kCellWasAlreadyTapped]
//       && [[NSUserDefaults standardUserDefaults] boolForKey:kFirstVideoRecorded] && !self.toolTipLabel) {
//        //first start tooltips
//        self.toolTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH/2, VIEW_HEIGHT/4)];
//        self.toolTipLabel.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:26];
//        NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Tap to \nenlarge"
//                                                                     attributes:@{
//                                                                                  NSStrokeColorAttributeName:[UIColor whiteColor],
//                                                                                  NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]
//                                                                                  }];
//        
//        self.toolTipLabel.textAlignment = NSTextAlignmentCenter;
//        self.toolTipLabel.attributedText = string;
//        self.toolTipLabel.numberOfLines = 3;
//        self.toolTipLabel.textColor = PRIMARY_COLOR;
//        self.toolTipLabel.alpha = 0.0;
//        [self.collectionView addSubview:self.toolTipLabel];
//        //warning create varible for all screen sizes
//        
//        [UIView animateKeyframesWithDuration:0.6 delay:1.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
//            //
//            [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
//                //
//                self.toolTipLabel.alpha = 1.0;
//            }];
//            
//            for(float i = 0; i < 4; i++){
//                [UIView addKeyframeWithRelativeStartTime:i/5.0 relativeDuration:i/(5.0) animations:^{
//                    //
//                    self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI / 6 + M_PI/36 + (int)i%2 * -1* M_PI/18);
//                }];
//                
//            }
//            
//            [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
//                self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI / 6);
//            }];
//            
//            
//        } completion:^(BOOL finished) {
//            self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI / 6);
//        }];
//        
//        [UIView animateWithDuration:0.3 delay:0.4 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
//            //
//            self.toolTipLabel.alpha = 1.0;
//        } completion:^(BOOL finished) {
//            //
//        }];
//    }
}

- (void)showNoVideosMessageIfNeeded {
    if(![YAUser currentUser].currentGroup.videos.count) {
        //group was sucessfully refreshed
        if([[YAUser currentUser].currentGroup.refreshedAt compare:[NSDate dateWithTimeIntervalSince1970:0]] != NSOrderedSame) {
            //hide spinning monkey and show "no videos" label
            [self showActivityIndicator:NO];

            if(!self.noVideosLabel) {
                self.noVideosLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2)];
                self.noVideosLabel.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:24];
                NSAttributedString *string = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Things are a bit quiet in here. Hold the big red button to record a video.", @"") attributes:@{NSStrokeColorAttributeName:[UIColor whiteColor],NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]}];
                
                self.noVideosLabel.textAlignment = NSTextAlignmentCenter;
                self.noVideosLabel.attributedText = string;
                self.noVideosLabel.numberOfLines = 3;
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
        if(![YAUser currentUser].currentGroup.videos.count) {
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
    NSUInteger videosCount = [YAUser currentUser].currentGroup.videos.count;
    
    NSUInteger result = videosCount < self.paginationThreshold ? videosCount : self.paginationThreshold;
    return result;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    YAVideo *video = [[YAUser currentUser].currentGroup.videos objectAtIndex:indexPath.row];
    NSString *serverId = [video.serverId copy];
    NSString *localId = [video.localId copy];
    YAVideoServerIdStatus status = [YAVideo serverIdStatusForVideo:video];
    NSString *groupId = [[YAUser currentUser].currentGroup.serverId copy];
    
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
    
    cell.video = video;

    
    if (!self.scrolling) {
        [cell renderLightweightContent];
        [cell renderHeavyWeightContent];
    } else if (!self.scrollingFast) {
        [cell renderLightweightContent];
    }

    [self handlePagingForIndexPath:indexPath];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(YAVideoCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [cell animateGifView:NO];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kCellWasAlreadyTapped]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCellWasAlreadyTapped];
        if(self.toolTipLabel){
            [self.toolTipLabel removeFromSuperview];
        }
    }
    
    [self openVideoAtIndexPath:indexPath];
}

- (void)openVideoAtIndexPath:(NSIndexPath*)indexPath {
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    YASwipingViewController *swipingVC = [[YASwipingViewController alloc] initWithInitialIndex:indexPath.row];
    swipingVC.delegate = self;
    
    CGRect initialFrame = attributes.frame;
    initialFrame.origin.y -= self.collectionView.contentOffset.y;
    initialFrame.origin.y += self.view.frame.origin.y;
    
    [self.delegate setInitialAnimationFrame:initialFrame];
    
    swipingVC.transitioningDelegate = self.delegate;
    swipingVC.modalPresentationStyle = UIModalPresentationCustom;
    
    [self presentViewController:swipingVC animated:YES completion:nil];
}

- (void)openVideo:(NSNotification*)notif {
    YAVideo *video = notif.userInfo[@"video"];
    NSUInteger videoIndex = [[YAUser currentUser].currentGroup.videos indexOfObject:video];
    
    if(videoIndex == NSNotFound) {
        DLog(@"can't find video index in current group");
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:videoIndex inSection:0];
    [self openVideoAtIndexPath:indexPath];
}

#pragma mark - UIScrollView

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
    [self.delegate scrollViewDidScroll];

    if (scrollView.contentSize.height == 0) return;
    if(self.disableScrollHandling) {
        return;
    }
    
    [[YAAssetsCreator sharedCreator] cancelGifOperations];
    
    self.assetsPrioritisationHandled = NO;
    
    BOOL fast = [self calculateScrollingFast];
    if (!fast && scrollView.contentOffset.y == -self.collectionView.pullToRefreshView.originalTopInset) {
        // Animated back to top to hide pull to refresh
        [self scrollingDidStop];
    } else if (self.scrollingFast && !fast) {
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

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self scrollingDidStop];
}

// Show the cell gifs & event counts
- (void)scrollingDidSlowDown {
    [self.collectionView layoutIfNeeded]; // Ensure visibleCells returns correct cells
    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        if ([videoCell isKindOfClass:[YAVideoCell class]]) {
            [videoCell renderLightweightContent];
        }
    }
}

// Show the captions
- (void)scrollingDidStop {
    self.scrolling = NO;
    
    [self.collectionView layoutIfNeeded]; // Ensure visibleCells returns correct cells
    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        if ([videoCell isKindOfClass:[YAVideoCell class]]) {
            [videoCell renderLightweightContent]; // Will know if its already been rendered
            [videoCell renderHeavyWeightContent];
        }
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
    NSUInteger endIndex = MIN([YAUser currentUser].currentGroup.videos.count, initialIndex + kNumberOfItemsBelowToDownload);
    
    for(NSUInteger videoIndex = beginIndex; videoIndex < endIndex; videoIndex++) {
        if([[self.collectionView.indexPathsForVisibleItems valueForKey:@"item"] containsObject:[NSNumber numberWithInteger:videoIndex]]) {
            [visibleVideos addObject:[[YAUser currentUser].currentGroup.videos objectAtIndex:videoIndex]];
        }
        else {
            [invisibleVideos addObject:[[YAUser currentUser].currentGroup.videos objectAtIndex:videoIndex]];
        }
    }
    
    [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVisibleVideos:visibleVideos invisibleVideos:invisibleVideos killExistingJobs:killExisting];
}

#pragma mark - YASwipingControllerDelegate
- (void)swipingController:(id)controller didScrollToIndex:(NSUInteger)index {
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

#pragma mark - Paging
- (void)handlePagingForIndexPath:(NSIndexPath*)indexPath {
    if(indexPath.row > self.paginationThreshold - kPaginationItemsCountToStartLoadingNextPage) {
        NSUInteger oldPaginationThreshold = self.paginationThreshold;
        self.paginationThreshold += kPaginationDefaultThreshold;
        
        //can't call reloadData methods when called from cellForRowAtIndexPath, using delay
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.collectionView reloadData];
            
            //enqueue new assets creation jobs
            [weakSelf enqueueAssetsCreationJobsStartingFromVideoIndex:oldPaginationThreshold];
            
            DLog(@"Page %lu loaded", (unsigned long)self.paginationThreshold / kPaginationDefaultThreshold);
        });
    }
}

#pragma mark - tooltips


- (void)showPrivateGroupTooltip {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_GROUP_VISIT_TITLE", @"") bodyText:[NSString stringWithFormat:NSLocalizedString(@"FIRST_GROUP_VISIT_BODY", @""), [YAUser currentUser].currentGroup.name, [[YAUser currentUser].currentGroup.members count]] dismissText:@"Got it" addToView:self.parentViewController.parentViewController.view] show];
}

- (void)showFriendChatTooltip {
    NSString *name = [((YAContact *)[[YAUser currentUser].currentGroup.members firstObject]) displayName];
    [[[YAPopoverView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"FIRST_FRIEND_CHAT_VISIT_TITLE", @""), name] bodyText:[NSString stringWithFormat:NSLocalizedString(@"FIRST_FRIEND_CHAT_VISIT_BODY", @""), name] dismissText:@"Got it" addToView:self.parentViewController.parentViewController.view] show];
}

@end
