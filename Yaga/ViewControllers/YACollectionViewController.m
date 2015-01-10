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

//Uploading videos
#import "YAServer.h"

@protocol GridViewControllerDelegate;

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;
@property (strong, nonatomic) UICollectionViewFlowLayout *swipeLayout;
@property (weak, nonatomic) UICollectionViewFlowLayout *targetLayout;

@property (nonatomic, assign) BOOL disableScrollHandling;

@property (strong, nonatomic) UILabel *noVideosLabel;
@property (strong, nonatomic) UIRefreshControl *pullToRefresh;
@property (strong, nonatomic) RLMResults *sortedVideos;

@property (strong, nonatomic) NSMutableDictionary *deleteDictionary;
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
    
    self.swipeLayout= [[UICollectionViewFlowLayout alloc] init];
    CGFloat swipeSpacing = 0.0f;
    [self.swipeLayout setSectionInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    [self.swipeLayout setMinimumInteritemSpacing:swipeSpacing];
    [self.swipeLayout setMinimumLineSpacing:swipeSpacing];
    [self.swipeLayout setItemSize:CGSizeMake(VIEW_WIDTH, VIEW_HEIGHT)];
    [self.swipeLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.gridLayout];
    
    self.targetLayout = self.gridLayout;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[YAVideoCell class] forCellWithReuseIdentifier:cellID];
    [self.collectionView setAllowsMultipleSelection:NO];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.collectionView];
    
    //pull down to refresh
    self.pullToRefresh = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0, -30, VIEW_WIDTH, 30)];
    self.pullToRefresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Fetching group videos" attributes:@{NSForegroundColorAttributeName:PRIMARY_COLOR}];
    [self.pullToRefresh addTarget:self action:@selector(fetchVideos) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.pullToRefresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertVideo:)     name:VIDEO_ADDED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadVideo:)     name:VIDEO_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willDeleteVideo:) name:VIDEO_WILL_DELETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteVideo:)  name:VIDEO_DID_DELETE_NOTIFICATION object:nil];

    [self reload];
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
    
    if(!self.sortedVideos.count) {
        [self toggleLayout];
    }
}

- (void)reloadVideo:(NSNotification*)notif {
    YAVideo *video = notif.object;
    if(![video.group isEqual:[YAUser currentUser].currentGroup])
        return;
    
    NSUInteger index = [self.sortedVideos indexOfObject:notif.object];
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
    [self toggleLayout];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(YAVideoCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if(self.collectionView.collectionViewLayout == self.swipeLayout) {
        [cell invalidateVideoPlayer];
    }
}

- (void)toggleLayout {
    UICollectionViewFlowLayout *newLayout = self.collectionView.collectionViewLayout == self.gridLayout ? self.swipeLayout : self.gridLayout;
    
    __weak typeof(self) weakSelf = self;
    self.disableScrollHandling = YES;
    [self.collectionView setPagingEnabled:newLayout == self.swipeLayout];
    
    self.targetLayout = newLayout;
    
    self.collectionView.alwaysBounceVertical = newLayout == self.gridLayout;
    
    if(newLayout == self.gridLayout) {
        [weakSelf.delegate showCamera:YES showPart:NO animated:YES completion:nil];
        
        self.collectionView.collectionViewLayout = newLayout;
        weakSelf.disableScrollHandling = NO;
        [weakSelf reload];
    }
    else {
        [self.delegate showCamera:NO showPart:NO animated:YES completion:nil];
        
        self.collectionView.collectionViewLayout = newLayout;
        [weakSelf reload];
    }
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

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self.delegate enableRecording:YES];
    
    BOOL scrollingFast = fabs(velocity.y) > 1;
    
    BOOL scrollingUp = velocity.y == fabs(velocity.y);
    
    //show/hide camera
//    if(scrollingFast && scrollingUp) {
//        self.disableScrollHandling = YES;
//        [self.delegate showCamera:NO showPart:YES animated:YES completion:^{
//            self.disableScrollHandling = NO;
//            [self playVisible:YES];
//        }];
//    }
//    else if(scrollingFast && !scrollingUp){
//        self.disableScrollHandling = YES;
//        [self.delegate showCamera:YES showPart:NO animated:YES completion:^{
//            self.disableScrollHandling = NO;
//            [self playVisible:YES];
//        }];
//    }
    
    self.scrolling = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if(self.collectionView.collectionViewLayout != self.swipeLayout)
        self.disableScrollHandling = NO;
    
    self.scrolling = NO;
}

- (void)playVisible:(BOOL)playValue {
    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        [videoCell animateGifView:playValue];
    }
}

#pragma mark - Pull down to refresh - Not implemented
- (void)fetchVideos {
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        //self.numberOfItems += 5;
        [self reload];
        [self.pullToRefresh endRefreshing];
    });
    
}

@end
