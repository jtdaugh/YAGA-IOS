//
//  CollectionViewController.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YACollectionViewController.h"
#import "YAAnimatedTransitioningController.h"

#import "YAVideoCell.h"

#import "YAUser.h"
#import "YAUtils.h"
#import "YAServer.h"

#import "UIScrollView+SVPullToRefresh.h"
#import "YAActivityView.h"
#import "YAAssetsCreator.h"

#import "YAPullToRefreshLoadingView.h"

#import "YANotificationView.h"

#import "YAImageCache.h"

@protocol GridViewControllerDelegate;

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;

@property (nonatomic, assign) BOOL disableScrollHandling;

@property (strong, nonatomic) NSMutableDictionary *deleteDictionary;

@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;

@property (nonatomic, assign) NSUInteger paginationThreshold;

@property (assign, nonatomic) BOOL assetsPrioritisationHandled;

@property (strong, nonatomic) UILabel *toolTipLabel;

@property (nonatomic, strong) YAActivityView *activityView;

@property (nonatomic) BOOL hasToolTipOnOneOfTheCells;

//needed to have pull down to refresh shown for at least 1 second
@property (nonatomic, strong) NSDate *willRefreshDate;

@property (nonatomic, strong) UILabel *noVideosLabel;
@end

static NSString *cellID = @"Cell";

#define kPaginationItemsCountToStartLoadingNextPage 10

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupWillRefresh:) name:GROUP_WILL_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidRefresh:) name:GROUP_DID_REFRESH_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDidChange:)  name:GROUP_DID_CHANGE_NOTIFICATION     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadVideo:)     name:VIDEO_CHANGED_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteVideo:)  name:VIDEO_DID_DELETE_NOTIFICATION  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willDeleteVideo:) name:VIDEO_WILL_DELETE_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToCell:)    name:SCROLL_TO_CELL_INDEXPATH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openVideo:)       name:OPEN_VIDEO_NOTIFICATION object:nil];
    
    //transitions
    self.animationController = [YAAnimatedTransitioningController new];
    
    [self setupPullToRefresh];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.collectionView.frame = self.view.bounds;
    
    [self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    DLog(@"memory warning!!");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_WILL_REFRESH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_DID_REFRESH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_DID_CHANGE_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_WILL_DELETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DELETE_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCROLL_TO_CELL_INDEXPATH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_VIDEO_NOTIFICATION object:nil];
}

- (void)reload {
    self.paginationThreshold = kPaginationDefaultThreshold;
    
    BOOL needRefresh = NO;
    if(![YAUser currentUser].currentGroup.videos.count)
        needRefresh = YES;
    
    NSDictionary *groupsUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT];
    NSDate *localGroupUpdateDate = [groupsUpdatedAt objectForKey:[YAUser currentUser].currentGroup.localId];
    if(!localGroupUpdateDate || [[YAUser currentUser].currentGroup.updatedAt compare:localGroupUpdateDate] == NSOrderedDescending) {
        needRefresh = YES;
    }
    
    [self.collectionView reloadData];
    
    if(needRefresh)
        [self refreshCurrentGroup];
    else
        [self enqueueAssetsCreationJobsStartingFromVideoIndex:0];
}

-  (void)willDeleteVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    if(![video.group isEqual:[YAUser currentUser].currentGroup])
        return;
    
    NSUInteger videoIndex = [[YAUser currentUser].currentGroup.videos indexOfObject:video];
    
    if(!self.deleteDictionary)
        self.deleteDictionary = [NSMutableDictionary new];
    
    [self.deleteDictionary setObject:[NSNumber numberWithInteger:videoIndex] forKey:video.localId];
}

- (void)didDeleteVideo:(NSNotification*)notif {
    
    YAVideo *video = notif.object;
    
    if(![video.group isEqual:[YAUser currentUser].currentGroup])
        return;
    
    if(![self.deleteDictionary objectForKey:video.localId])
        return;
    
    NSUInteger videoIndex = [[self.deleteDictionary objectForKey:video.localId] integerValue];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:videoIndex inSection:0];
    
    self.paginationThreshold--;
    
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    
    [self.deleteDictionary removeObjectForKey:video.localId];
}

- (void)reloadVideo:(NSNotification*)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        YAVideo *video = notif.object;
        if(![video.group isEqual:[YAUser currentUser].currentGroup])
            return;
        
        NSUInteger index = [[YAUser currentUser].currentGroup.videos indexOfObject:video];
        
        //the following line will ensure indexPathsForVisibleItems will return correct results
        [self.collectionView layoutIfNeeded];
        
        //invisible? we do not reload then
        if(![[self.collectionView.indexPathsForVisibleItems valueForKey:@"row"] containsObject:[NSNumber numberWithInteger:index]]) {
            return;
        }
        
        NSUInteger countOfItems = [self collectionView:self.collectionView numberOfItemsInSection:0];
        
        if(index != NSNotFound && index <= countOfItems) {
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]];
        }
        else {
            [NSException raise:@"something is really wrong" format:nil];
        }
    });
}

- (void)groupDidChange:(NSNotification*)notif {
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
    
    NSArray *newVideos = notification.userInfo[kVideos];
    
    //the following line will ensure visibleCells will return correct results
    [self.collectionView layoutIfNeeded];
    
    if(newVideos.count) {
        if([self.collectionView visibleCells].count)
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        
        [self.collectionView performBatchUpdates:^{
            //simple workaround to avoid manipulations with paginationThreshold
            if(newVideos.count == 1) {
                self.paginationThreshold++;
                [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
                
                if(![[NSUserDefaults standardUserDefaults] boolForKey:kCellWasAlreadyTapped]
                   && [[NSUserDefaults standardUserDefaults] boolForKey:kFirstVideoRecorded] && !self.toolTipLabel) {
                    //first start tooltips
                    self.toolTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH/2, VIEW_HEIGHT/4)];
                    self.toolTipLabel.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:26];
                    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Tap to \nenlarge"
                                                                                 attributes:@{
                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]
                                                                                              }];
                    
                    self.toolTipLabel.textAlignment = NSTextAlignmentCenter;
                    self.toolTipLabel.attributedText = string;
                    self.toolTipLabel.numberOfLines = 3;
                    self.toolTipLabel.textColor = PRIMARY_COLOR;
                    self.toolTipLabel.alpha = 0.0;
                    [self.collectionView addSubview:self.toolTipLabel];
                    //warning create varible for all screen sizes
                    
                    [UIView animateKeyframesWithDuration:0.6 delay:1.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
                        //
                        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
                            //
                            self.toolTipLabel.alpha = 1.0;
                        }];
                        
                        for(float i = 0; i < 4; i++){
                            [UIView addKeyframeWithRelativeStartTime:i/5.0 relativeDuration:i/(5.0) animations:^{
                                //
                                self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI / 6 + M_PI/36 + (int)i%2 * -1* M_PI/18);
                            }];
                            
                        }
                        
                        [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
                            self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI / 6);
                        }];


                    } completion:^(BOOL finished) {
                        self.toolTipLabel.transform = CGAffineTransformMakeRotation(-M_PI / 6);
                    }];
                    
                    [UIView animateWithDuration:0.3 delay:0.4 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                        //
                        self.toolTipLabel.alpha = 1.0;
                    } completion:^(BOOL finished) {
                        //
                    }];
                }

            }
            
            else {
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            }
        } completion:^(BOOL finished) {
            [self enqueueAssetsCreationJobsStartingFromVideoIndex:0];
            
            [self playVisible:YES];
            
            [self showActivityIndicator:NO];
        }];
    }
    else {
        [self enqueueAssetsCreationJobsStartingFromVideoIndex:0];
        [self showActivityIndicator:NO];
    }
    
    [self.collectionView reloadData];
    
    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:self.willRefreshDate];

    double hidePullToRefreshAfter = 1 - seconds;
    if(hidePullToRefreshAfter < 0)
        hidePullToRefreshAfter = 0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(hidePullToRefreshAfter * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView.pullToRefreshView stopAnimating];
        [self playVisible:YES];
        [self showNoVideosMessageIfNeeded];
    });
}

- (void)showNoVideosMessageIfNeeded {
    if(![YAUser currentUser].currentGroup.videos.count) {
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
        [self.noVideosLabel removeFromSuperview];
        self.noVideosLabel = nil;
    }
}

- (void)showActivityIndicator:(BOOL)show {
    if(show) {
        //don't show spinning monkey if pull down to refresh is shown
        if(self.collectionView.pullToRefreshView.state != SVPullToRefreshStateStopped)
            return;
        
        const CGFloat monkeyWidth  = 50;
        [self.activityView removeFromSuperview];
        if(![YAUser currentUser].currentGroup.videos.count) {
            self.activityView = [[YAActivityView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2-monkeyWidth/2, VIEW_HEIGHT/5, monkeyWidth, monkeyWidth)];
            [self.collectionView addSubview:self.activityView];
            [self.activityView startAnimating];
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
    YAVideo *video = [YAUser currentUser].currentGroup.videos[indexPath.row];
    
    cell.video = video;
    
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
    
    self.animationController.initialFrame = initialFrame;
    
    swipingVC.transitioningDelegate = self;
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
- (BOOL)scrollingFast {
    CGPoint currentOffset = self.collectionView.contentOffset;
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    
    BOOL result = NO;
    
    CGFloat distance = currentOffset.y - lastOffset.y;
    //The multiply by 10, / 1000 isn't really necessary.......
    CGFloat scrollSpeedNotAbs = (distance * 10) / 1000; //in pixels per millisecond
    
    CGFloat scrollSpeed = fabs(scrollSpeedNotAbs);
    if (scrollSpeed > 0.06) {
        result = YES;
    } else {
        result = NO;
    }
    
    lastOffset = currentOffset;
    lastOffsetCapture = currentTime;
    return result;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.delegate collectionViewDidScroll];
    
    [self handlePaging];

    [[YAAssetsCreator sharedCreator] cancelGifOperations];
    
    self.assetsPrioritisationHandled = NO;
    
    if(self.disableScrollHandling) {
        return;
    }
    
    BOOL scrollingFast = [self scrollingFast];
    
    [self playVisible:!scrollingFast];
    
    self.scrolling = YES;

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.scrolling = NO;
    
    if(!self.assetsPrioritisationHandled)
        [self prioritiseDownloadsForVisibleCells];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self playVisible:YES];
        
        [self prioritiseDownloadsForVisibleCells];
        self.assetsPrioritisationHandled = YES;
    }
}

- (void)adjustWhileDraggingWithVelocity:(CGPoint)velocity {
    BOOL draggingFast = fabs(velocity.y) > 1;
    BOOL draggingUp = velocity.y == fabs(velocity.y);
    
    
    //show/hide camera
    if(draggingFast && draggingUp) {
        self.disableScrollHandling = YES;
        [self.delegate showCamera:NO showPart:YES animated:YES completion:^{
            self.disableScrollHandling = NO;
            [self playVisible:YES];
        }];
    }
    else if(draggingFast && !draggingUp){
        self.disableScrollHandling = YES;
        [self.delegate showCamera:YES showPart:NO animated:YES completion:^{
            self.disableScrollHandling = NO;
            [self playVisible:YES];
        }];
    }
}

- (void)playVisible:(BOOL)playValue {
    //the following line will ensure visibleCells will return correct results
    [self.collectionView layoutIfNeeded];

    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        [videoCell animateGifView:playValue];
    }
}

#pragma mark - Assets creation

- (void)prioritiseDownloadsForVisibleCells {

    //sort them fist
    NSArray *visibleVideoIndexes = [[[self.collectionView indexPathsForVisibleItems] valueForKey:@"row"] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    NSMutableArray *videos = [NSMutableArray new];
    for(NSNumber *visibleVideoIndex in visibleVideoIndexes) {
        [videos addObject:[[YAUser currentUser].currentGroup.videos objectAtIndex:[visibleVideoIndex integerValue]]];
    }
    
    [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVisibleVideos:videos invisibleVideos:nil];
    
    [self precacheGifsStartingFromIndex:[visibleVideoIndexes.lastObject integerValue]];
}

- (void)precacheGifsStartingFromIndex:(NSUInteger)startingIndex {
    
    NSUInteger currentIndex = startingIndex + 1;
    
    const NSUInteger defaultPrecacheCount = 30;
    while (currentIndex < [YAUser currentUser].currentGroup.videos.count && (currentIndex - startingIndex <= defaultPrecacheCount)) {
        YAVideo *video = [YAUser currentUser].currentGroup.videos[currentIndex];
        
        NSString *fileName = video.gifFilename;
        if(fileName.length && ![[YAImageCache sharedCache] objectForKey:fileName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                NSURL *dataURL = [YAUtils urlFromFileName:fileName];
                NSData *fileData = [NSData dataWithContentsOfURL:dataURL];
                FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:fileData];
                
                if(image) {
                    [[YAImageCache sharedCache] setObject:image forKey:fileName];
                    DLog(@"gif precached");
                }
            });
        }
        currentIndex++;
    }
}


- (void)enqueueAssetsCreationJobsStartingFromVideoIndex:(NSUInteger)initialIndex {
    NSUInteger maxCount = self.paginationThreshold;
    if(maxCount > [YAUser currentUser].currentGroup.videos.count)
        maxCount = [YAUser currentUser].currentGroup.videos.count;
    
    //the following line will ensure indexPathsForVisibleItems will return correct results
    [self.collectionView layoutIfNeeded];
    
    NSMutableArray *visibleVideos = [NSMutableArray new];
    NSMutableArray *invisibleVideos = [NSMutableArray new];
    for(NSUInteger videoIndex = initialIndex; videoIndex < maxCount; videoIndex++) {
        if([[self.collectionView.indexPathsForVisibleItems valueForKey:@"row"] containsObject:[NSNumber numberWithInteger:videoIndex]]) {
            [visibleVideos addObject:[[YAUser currentUser].currentGroup.videos objectAtIndex:videoIndex]];
        }
        else {
            [invisibleVideos addObject:[[YAUser currentUser].currentGroup.videos objectAtIndex:videoIndex]];
        }
        
    }
    
    [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVisibleVideos:visibleVideos invisibleVideos:invisibleVideos];
}

#pragma mark - Custom transitions
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.animationController.presentingMode = YES;
    
    return self.animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.animationController.presentingMode = NO;
    
    return self.animationController;
}

#pragma mark - Paging
- (void)handlePaging {
    //the following line will ensure indexPathsForVisibleItems will return correct results
    [self.collectionView layoutIfNeeded];
    
    NSArray *visibleIndexes = [[self.collectionView indexPathsForVisibleItems] valueForKey:@"row"];
    if(!visibleIndexes.count)
        return;
    
    NSUInteger max = [[visibleIndexes valueForKeyPath:@"@max.intValue"] integerValue];
    
    if (max > self.paginationThreshold - kPaginationItemsCountToStartLoadingNextPage) {
        //load more
        [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
        [self.collectionView reloadData];
        
        NSUInteger oldPaginationThreshold = self.paginationThreshold;
        
        // update the threshold
        self.paginationThreshold += kPaginationDefaultThreshold;
        
        //enqueue new assets creation jobs
        [self enqueueAssetsCreationJobsStartingFromVideoIndex:oldPaginationThreshold];
    }
}

#pragma mark - YASwipingControllerDelegate
- (void)swipingController:(id)controller scrollToIndex:(NSUInteger)index {
    NSSet *visibleIndexes = [NSSet setWithArray:[[self.collectionView indexPathsForVisibleItems] valueForKey:@"row"]];
    
    //don't do anything if it's visible already
    if([visibleIndexes containsObject:[NSNumber numberWithInteger:index]])
        return;
    
    if(index < [self collectionView:self.collectionView numberOfItemsInSection:0]) {
        UIEdgeInsets tmp = self.collectionView.contentInset;
        
        [self.collectionView setContentInset:UIEdgeInsetsZero];//Make(collectionViewHeight/2, 0, collectionViewHeight/2, 0)];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        
        //even not animated scrollToItemAtIndexPath call takes some time, using hack
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.collectionView.contentInset = tmp;
            
            [self.delegate collectionViewDidScroll];
            
            [self playVisible:YES];
            
            [self prioritiseDownloadsForVisibleCells];
            self.assetsPrioritisationHandled = YES;
        });
    }

}
@end
