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

#import <ClusterPrePermissions.h>

@protocol GridViewControllerDelegate;

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;

@property (nonatomic, assign) BOOL disableScrollHandling;

@property (strong, nonatomic) UILabel *noVideosLabel;

@property (strong, nonatomic) NSMutableDictionary *deleteDictionary;

@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;
@end

static NSString *cellID = @"Cell";

@implementation YACollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat spacing = 1.0f;
    
    self.gridLayout = [[UICollectionViewFlowLayout alloc] init];
    [self.gridLayout setMinimumInteritemSpacing:spacing];
    [self.gridLayout setMinimumLineSpacing:spacing];
    [self.gridLayout setItemSize:CGSizeMake(TILE_WIDTH - 1.0f, TILE_HEIGHT)];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.gridLayout];
    
    self.collectionView.alwaysBounceVertical = YES;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[YAVideoCell class] forCellWithReuseIdentifier:cellID];
    [self.collectionView setAllowsMultipleSelection:NO];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.contentInset = UIEdgeInsetsMake(VIEW_HEIGHT/2 + 2 - CAMERA_MARGIN, 0, 0, 0);
    [self.view addSubview:self.collectionView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertVideos:)    name:VIDEOS_ADDED_NOTIFICATION      object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadVideo:)     name:VIDEO_CHANGED_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteVideo:)  name:VIDEO_DID_DELETE_NOTIFICATION  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willDeleteVideo:) name:VIDEO_WILL_DELETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGroup:)    name:REFRESH_GROUP_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToCell:)    name:SCROLL_TO_CELL_INDEXPATH_NOTIFICATION object:nil];
    //transitions
    self.animationController = [YAAnimatedTransitioningController new];
    
    [self setupPullToRefresh];
}

- (void)scrollToCell:(NSNotification *)notif
{
    YAVideoCell *cell = notif.object;
    
//    YAVideoCell *lastObject = self.collectionView.visibleCells.lastObject;
//    YAVideoCell *objectBeforeLast = self.collectionView.visibleCells[self.collectionView.visibleCells.count - 2];
//    if (cell == lastObject || cell == objectBeforeLast) {
//        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
//        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
//    }

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
        ClusterPrePermissions *permissions = [ClusterPrePermissions sharedPermissions];
        [permissions
         showPushNotificationPermissionsWithType:ClusterPushNotificationTypeAlert | ClusterPushNotificationTypeSound | ClusterPushNotificationTypeBadge
         title:NSLocalizedString(@"Enable push notifications?", nil)
         message:NSLocalizedString(@"Yaga wants to send you push notifications", nil)
         denyButtonTitle:@"Not Now"
         grantButtonTitle:@"Enable"
         completionHandler:nil];
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
    
    NSLog(@"memory warning!!");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEOS_ADDED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_WILL_DELETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DELETE_NOTIFICATION object:nil];
}

- (void)showNoVideosMessageIfNeeded {
    if(![YAUser currentUser].currentGroup.videos.count) {
        CGFloat width = VIEW_WIDTH * .8;
        if(!self.noVideosLabel) {
            self.noVideosLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, 0, width, width)];
            [self.noVideosLabel setText:NSLocalizedString(@"NO VIDOES IN NEW GROUP MESSAGE", @"")];
            [self.noVideosLabel setNumberOfLines:0];
            [self.noVideosLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
            [self.noVideosLabel setTextAlignment:NSTextAlignmentCenter];
            [self.noVideosLabel setTextColor:PRIMARY_COLOR];
        }
        [self.collectionView addSubview:self.noVideosLabel];
    }
    else {
        [self.noVideosLabel removeFromSuperview];
        self.noVideosLabel = nil;
    }
}

- (void)reload {
    BOOL needRefresh = NO;
    if(![YAUser currentUser].currentGroup.videos.count)
        needRefresh = YES;
    
    NSDictionary *groupsUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT];
    NSDate *localGroupUpdateDate = [groupsUpdatedAt objectForKey:[YAUser currentUser].currentGroup.localId];
    if(!localGroupUpdateDate || [[YAUser currentUser].currentGroup.updatedAt compare:localGroupUpdateDate] == NSOrderedDescending) {
        needRefresh = YES;
    }
    
    if(needRefresh)
        [self refreshCurrentGroup];
    else
        [self enqueueAssetsCreationJobsForCurrentGroup];
    
    [self.collectionView reloadData];
    
    [self showNoVideosMessageIfNeeded];
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
    
    NSString *videoId = notif.object;
    if(![self.deleteDictionary objectForKey:videoId])
        return;
    
    NSUInteger videoIndex = [[self.deleteDictionary objectForKey:videoId] integerValue];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:videoIndex inSection:0];
    
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    
    [self.deleteDictionary removeObjectForKey:videoId];
}

- (void)reloadVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    if(![video.group isEqual:[YAUser currentUser].currentGroup])
        return;
    
    NSUInteger index = [[YAUser currentUser].currentGroup.videos indexOfObject:video];
    
    if(index != NSNotFound) {
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]];
    }
    else {
        [NSException raise:@"something is really wrong" format:nil];
    }
}

- (void)insertVideos:(NSNotification*)notif {
    NSArray *videos = notif.object;
    
    if(!videos.count)
        return;
    
    YAVideo *firstVideo = (YAVideo*)[videos firstObject];
    if(![firstVideo.group isEqual:[YAUser currentUser].currentGroup])
        return;
    
    [self.collectionView performBatchUpdates:^{
        for(int i = 0; i < videos.count; i++) {
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        }
    } completion:^(BOOL finished) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    }];
}

- (void)refreshGroup:(NSNotification*)notif {
    YAGroup *groupToRefresh = [notif object];
    if([[YAUser currentUser].currentGroup.localId isEqualToString:groupToRefresh.localId]) {
        [self refreshCurrentGroup];
    }
}

- (void)refreshCurrentGroup {
    __weak typeof (self) weakSelf = self;
    [[YAUser currentUser].currentGroup updateVideosWithCompletion:^(NSError *error, NSArray *newVideos) {
        if(!error) {
            if(newVideos.count) {
                [weakSelf.collectionView performBatchUpdates:^{
                    [weakSelf.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                } completion:^(BOOL finished) {
                }];
            }
        }
        
        [weakSelf.collectionView.pullToRefreshView stopAnimating];
        [weakSelf playVisible:YES];
        [self enqueueAssetsCreationJobsForCurrentGroup];
    }];
}

#pragma mark - UICollectionView
static BOOL welcomeLabelRemoved = NO;
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if([YAUser currentUser].currentGroup.videos.count && self.noVideosLabel && !welcomeLabelRemoved) {
        [self.noVideosLabel removeFromSuperview];
        self.noVideosLabel = nil;
    }
    return [YAUser currentUser].currentGroup.videos.count;
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
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    YASwipingViewController *swipingVC = [[YASwipingViewController alloc] initWithInitialIndex:indexPath.row];
    
    NSLog(@"before transition");
    CGRect initialFrame = attributes.frame;
    initialFrame.origin.y -= self.collectionView.contentOffset.y;
    initialFrame.origin.y += self.view.frame.origin.y;
    
    self.animationController.initialFrame = initialFrame;
    
    swipingVC.transitioningDelegate = self;
    swipingVC.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:swipingVC animated:YES completion:^{
        NSLog(@"after transition");
    }];
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
    [self.delegate collectionViewDidScroll];
    
    if(self.disableScrollHandling) {
        return;
    }
    
    BOOL scrollingFast = [self scrollingFast];
    
    [self playVisible:!scrollingFast];
    
    self.scrolling = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.scrolling = NO;
    
    [self prioritiseDownloadsForVisibleCells];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self playVisible:YES];
        
        [self prioritiseDownloadsForVisibleCells];
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
    for(YAVideoCell *cell in self.collectionView.visibleCells)
        [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVideo:cell.video prioritizeDownload:YES];
}

- (void)enqueueAssetsCreationJobsForCurrentGroup {
    for(YAVideo *video in [YAUser currentUser].currentGroup.videos)
            [[YAAssetsCreator sharedCreator] enqueueAssetsCreationJobForVideo:video prioritizeDownload:NO];
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
@end
