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

@protocol GridViewControllerDelegate;

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;

@property (nonatomic, assign) BOOL disableScrollHandling;

@property (strong, nonatomic) UILabel *noVideosLabel;
@property (strong, nonatomic) RLMResults *sortedVideos;

@property (strong, nonatomic) NSMutableDictionary *deleteDictionary;

@property (strong, nonatomic) YAAnimatedTransitioningController *animationController;
@end

static NSString *cellID = @"Cell";

@implementation YACollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat spacing = 1.0f;
    
    self.gridLayout = [[UICollectionViewFlowLayout alloc] init];
    [self.gridLayout setSectionInset:UIEdgeInsetsMake(0, 0, 0, 0)];
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
    
    [self.view addSubview:self.collectionView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertVideo:)     name:VIDEO_ADDED_NOTIFICATION       object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadVideo:)     name:VIDEO_CHANGED_NOTIFICATION     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteVideo:)  name:VIDEO_DID_DELETE_NOTIFICATION  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willDeleteVideo:) name:VIDEO_WILL_DELETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGroup:)    name:REFRESH_GROUP_NOTIFICATION object:nil];
    
    [self reload];
    
    //transitions
    self.animationController = [YAAnimatedTransitioningController new];
    
    [self setupPullToRefresh];
}

- (void)setupPullToRefresh {
    //pull to refresh
    __weak typeof(self) weakSelf = self;
    [self.collectionView addPullToRefreshWithActionHandler:^{
        [weakSelf.delegate enableRecording:NO];
        [[YAUser currentUser].currentGroup updateVideosWithCompletion:^(NSError *error) {
            [weakSelf reload];
            [weakSelf.collectionView.pullToRefreshView stopAnimating];
            [weakSelf.delegate enableRecording:YES];
        }];
    }];
    
    YAActivityView *loadinView = [[YAActivityView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH/10, VIEW_WIDTH/10)];
    loadinView.animateAtOnce = YES;
    
    UILabel *stoppedView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 20)];
    stoppedView.font = [UIFont fontWithName:THIN_FONT size:14];
    stoppedView.textAlignment = NSTextAlignmentCenter;
    stoppedView.text = @"Pull to refresh";

    UILabel *triggeredView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 20)];
    triggeredView.font = [UIFont fontWithName:THIN_FONT size:14];
    triggeredView.textAlignment = NSTextAlignmentCenter;
    triggeredView.text = @"Release to refresh";
    
    [self.collectionView.pullToRefreshView setCustomView:loadinView forState:SVPullToRefreshStateLoading];
    [self.collectionView.pullToRefreshView setCustomView:stoppedView forState:SVPullToRefreshStateStopped];
    [self.collectionView.pullToRefreshView setCustomView:triggeredView forState:SVPullToRefreshStateTriggered];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.collectionView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"memory warning!!");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_ADDED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_WILL_DELETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DELETE_NOTIFICATION object:nil];
}

- (void)showNoVideosMessageIfNeeded {
    if(!self.sortedVideos.count) {
        CGFloat width = VIEW_WIDTH * .8;
        if(!self.noVideosLabel) {
            self.noVideosLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, self.collectionView.frame.origin.y + 20, width, width)];
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

- (void)updateSortedVideos {
    self.sortedVideos = [[YAUser currentUser].currentGroup sortedVideos];
}

- (void)reload {
    [self updateSortedVideos];
    
    [self.collectionView reloadData];
    [self showNoVideosMessageIfNeeded];
}

-  (void)willDeleteVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    if(![video.group isEqual:[YAUser currentUser].currentGroup])
        return;
    
    NSUInteger videoIndex = [self.sortedVideos indexOfObject:video];
    
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
    
    [self updateSortedVideos];
    
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    
    [self.deleteDictionary removeObjectForKey:videoId];
}

- (void)reloadVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    NSLog(@"%@", video.serverId);
    if(![video.group isEqual:[YAUser currentUser].currentGroup])
        return;
    
    NSUInteger index = [self.sortedVideos indexOfObject:video];
    NSLog(@"%lu", (unsigned long)index);
    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]];
}

- (void)insertVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    if(![video.group isEqual:[YAUser currentUser].currentGroup])
        return;
    
    [self updateSortedVideos];
    
    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    
    if(self.collectionView.contentOffset.y != 0)
        [self.collectionView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (void)refreshGroup:(NSNotification*)notif {
    YAGroup *groupToRefresh = [notif object];
    if([[YAUser currentUser].currentGroup.localId isEqualToString:groupToRefresh.localId]) {
        self.collectionView.contentOffset = CGPointMake(0, 0);
        [self.collectionView triggerPullToRefresh];
    }
}

#pragma mark - UICollectionView
static BOOL welcomeLabelRemoved = NO;
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if(self.sortedVideos.count && self.noVideosLabel && !welcomeLabelRemoved) {
        [self.noVideosLabel removeFromSuperview];
        self.noVideosLabel = nil;
    }
    return self.sortedVideos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    YAVideo *video = self.sortedVideos[indexPath.row];
    cell.video = video;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    YASwipingViewController *swipingVC = [[YASwipingViewController alloc] initWithVideos:self.sortedVideos andInitialIndex:indexPath.row];

    CGRect initialFrame = attributes.frame;
    initialFrame.origin.y -= self.collectionView.contentOffset.y;
    initialFrame.origin.y += self.view.frame.origin.y;
    
    self.animationController.initialFrame = initialFrame;
    
    swipingVC.transitioningDelegate = self;
    swipingVC.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:swipingVC animated:YES completion:nil];
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

- (void)playPauseOnScroll:(BOOL)scrollingFast {
    [self playVisible:!scrollingFast];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGRect cameraFrame = self.cameraView.view.frame;
    CGRect gridFrame = self.view.frame;
    
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGFloat offset = 0;
    
    NSLog(@"scrolling: %f", scrollOffset);
    
    if(scrollOffset < 0){
        offset = 0;
        cameraFrame.origin.y = 0;
    } else if(scrollOffset > cameraFrame.size.height - 100){
        offset = cameraFrame.size.height - 100;
        cameraFrame.origin.y = -cameraFrame.size.height*2 + 100;
    } else {
        offset = scrollOffset;
        cameraFrame.origin.y = -2*offset;
    }
    
    
    gridFrame.origin.y = VIEW_HEIGHT/2 + 2 - offset;
    gridFrame.size.height = VIEW_HEIGHT/2 + 2 + offset;
    
//    self.cameraView.view.frame = cameraFrame;
//    self.view.frame = gridFrame;
    
    if(self.disableScrollHandling) {
        return;
    }
    
    BOOL scrollingFast = [self scrollingFast];
    
    [self playPauseOnScroll:scrollingFast];
    
    self.scrolling = YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.delegate enableRecording:NO];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self.delegate enableRecording:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.scrolling = NO;
    [self.delegate enableRecording:self.collectionView.pullToRefreshView.state != SVPullToRefreshStateLoading];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self playVisible:YES];
        [self.delegate enableRecording:self.collectionView.pullToRefreshView.state != SVPullToRefreshStateLoading];
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
