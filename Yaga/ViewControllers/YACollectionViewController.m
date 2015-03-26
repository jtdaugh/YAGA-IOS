//
//  CollectionViewController.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YACollectionViewController.h"
#import "YASwipingViewController.h"
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
@end

static NSString *cellID = @"Cell";

#define kPaginationItemsCountToStartLoadingNextPage 10
#define kPaginationDefaultThreshold 100

@implementation YACollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.hasToolTipOnOneOfTheCells = NO;
    CGFloat spacing = 1.0f;
    
    self.gridLayout = [[UICollectionViewFlowLayout alloc] init];
    [self.gridLayout setMinimumInteritemSpacing:spacing];
    [self.gridLayout setMinimumLineSpacing:spacing];
    [self.gridLayout setItemSize:CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT)];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:self.gridLayout];
    
    self.collectionView.alwaysBounceVertical = YES;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[YAVideoCell class] forCellWithReuseIdentifier:cellID];
    [self.collectionView setAllowsMultipleSelection:NO];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.contentInset = UIEdgeInsetsMake(VIEW_HEIGHT/2 + 2 - CAMERA_MARGIN, 0, 0, 0);
    self.collectionView.layoutMargins = UIEdgeInsetsMake(0, 1.0f, 0, 1.0f);
    [self.view addSubview:self.collectionView];

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
    
    YAPullToRefreshLoadingView *loadingView = [[YAPullToRefreshLoadingView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/10, 0, VIEW_WIDTH-VIEW_WIDTH/10/2, self.collectionView.pullToRefreshView.bounds.size.height)];
    
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateLoading];
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateStopped];
    [self.collectionView.pullToRefreshView setCustomView:loadingView forState:SVPullToRefreshStateTriggered];
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
    if(!self.controllersGroup.videos.count)
        needRefresh = YES;
    
    NSDictionary *groupsUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT];
    NSDate *localGroupUpdateDate = [groupsUpdatedAt objectForKey:self.controllersGroup.localId];
    if(!localGroupUpdateDate || [self.controllersGroup.updatedAt compare:localGroupUpdateDate] == NSOrderedDescending) {
        needRefresh = YES;
    }
    
    if(needRefresh)
        [self refreshCurrentGroup];
    else
        [self enqueueAssetsCreationJobsStartingFromVideoIndex:0];
    
    [self.collectionView reloadData];
}

-  (void)willDeleteVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    if(![video.group isEqual:self.controllersGroup])
        return;
    
    NSUInteger videoIndex = [self.controllersGroup.videos indexOfObject:video];
    
    if(!self.deleteDictionary)
        self.deleteDictionary = [NSMutableDictionary new];
    
    [self.deleteDictionary setObject:[NSNumber numberWithInteger:videoIndex] forKey:video.localId];
}

- (void)didDeleteVideo:(NSNotification*)notif {
    
    NSString *videoId = notif.object;
    if(![self.deleteDictionary objectForKey:videoId])
        return;
    
    NSUInteger videoIndex = [[self.deleteDictionary objectForKey:videoId] integerValue];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:videoIndex inSection:0];
    
    self.paginationThreshold--;
    
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    
    [self.deleteDictionary removeObjectForKey:videoId];
}

- (void)reloadVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    if(![video.group isEqual:self.controllersGroup])
        return;
    
    NSUInteger index = [self.controllersGroup.videos indexOfObject:video];
    
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
}

- (void)groupDidChange:(NSNotification*)notif {
    [self reload];
}

- (void)refreshCurrentGroup {
    [self showActivityIndicator:YES];
    
    [self.controllersGroup refresh];
}

- (void)groupDidRefresh:(NSNotification*)notification {
    if(![notification.object isEqual:self.controllersGroup])
        return;
    
    NSArray *newVideos = notification.userInfo[kVideos];
    
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
                    
                    [UIView animateKeyframesWithDuration:0.6 delay:0.6 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
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
        [self showActivityIndicator:NO];
    }
    
    [self.collectionView.pullToRefreshView stopAnimating];
    [self playVisible:YES];
}

- (void)showActivityIndicator:(BOOL)show {
    if(show) {
        //don't show spinning monkey if pull down to refresh is shown
        if(self.collectionView.pullToRefreshView.state != SVPullToRefreshStateStopped)
            return;
        
        const CGFloat monkeyWidth  = 50;
        [self.activityView removeFromSuperview];
        if(!self.controllersGroup.videos.count) {
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
    NSUInteger videosCount = self.controllersGroup.videos.count;
    
    NSUInteger result = videosCount < self.paginationThreshold ? videosCount : self.paginationThreshold;
    return result;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    YAVideo *video = self.controllersGroup.videos[indexPath.row];
    
    cell.video = video;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
//    for (YAVideoCell *cell in self.collectionView.visibleCells) {
//        NSIndexPath *idx = [self.collectionView indexPathForCell:cell];
//        if (idx.row != 0) {
//            cell.toolTipLabel.hidden = YES;
//        }
//    }
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
    
    DLog(@"before transition");
    CGRect initialFrame = attributes.frame;
    initialFrame.origin.y -= self.collectionView.contentOffset.y;
    initialFrame.origin.y += self.view.frame.origin.y;
    
    self.animationController.initialFrame = initialFrame;
    
    swipingVC.transitioningDelegate = self;
    swipingVC.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:swipingVC animated:YES completion:^{
        DLog(@"after transition");
    }];
}

- (void)openVideo:(NSNotification*)notif {
    YAVideo *video = notif.userInfo[@"video"];
    NSUInteger videoIndex = [self.controllersGroup.videos indexOfObject:video];
    
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
    
    CGFloat scrollSpeed = fabsf(scrollSpeedNotAbs);
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
    [self handlePaging];

    [[YAAssetsCreator sharedCreator] cancelGifOperations];
    
    self.assetsPrioritisationHandled = NO;
    
    if(self.disableScrollHandling) {
        return;
    }
    
    BOOL scrollingFast = [self scrollingFast];
    
    [self playVisible:!scrollingFast];
    
    self.scrolling = YES;
    [self.delegate collectionViewDidScroll];
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
    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        [videoCell animateGifView:playValue];
    }
}

#pragma mark - Assets creation

- (void)prioritiseDownloadsForVisibleCells {
    NSMutableArray *videos = [NSMutableArray new];
    for(YAVideoCell *cell in self.collectionView.visibleCells)
        [videos addObject:cell.video];
    
    [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVideos:videos prioritizeDownload:YES];
}

- (void)enqueueAssetsCreationJobsStartingFromVideoIndex:(NSUInteger)initialIndex {
    NSUInteger maxCount = self.paginationThreshold;
    if(maxCount > self.controllersGroup.videos.count)
        maxCount = self.controllersGroup.videos.count;
    
    NSMutableArray *visibleVideos = [NSMutableArray new];
    NSMutableArray *invisibleVideos = [NSMutableArray new];
    for(NSUInteger videoIndex = initialIndex; videoIndex < maxCount; videoIndex++) {
        if([[self.collectionView.indexPathsForVisibleItems valueForKey:@"row"] containsObject:[NSNumber numberWithInteger:videoIndex]]) {
            [visibleVideos addObject:[self.controllersGroup.videos objectAtIndex:videoIndex]];
        }
        else {
            [invisibleVideos addObject:[self.controllersGroup.videos objectAtIndex:videoIndex]];
        }
        
    }
    
    [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVideos:visibleVideos prioritizeDownload:YES];
    [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVideos:invisibleVideos prioritizeDownload:NO];
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

#pragma mark - Gesture recognizers
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (indexPath) {
        YAVideo *video = [self.controllersGroup.videos objectAtIndex:indexPath.row];
        BOOL myVideo = [video.creator isEqualToString:[[YAUser currentUser] username]];
        
        if(myVideo)
            [YAUtils showVideoOptionsForVideo:video];
    }
}

#pragma mark - Paging
- (void)handlePaging {
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
@end
