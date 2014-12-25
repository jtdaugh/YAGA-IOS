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
#import "AVPlayer+AVPlayer_Async.h"
#import "AVPlaybackViewController.h"

@protocol GridViewControllerDelegate;

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;
@property (strong, nonatomic) UICollectionViewFlowLayout *swipeLayout;
@property (weak, nonatomic) UICollectionViewFlowLayout *targetLayout;

@property (nonatomic, assign) BOOL disableScrollHandling;

@property (strong, nonatomic) UILabel *noVideosLabel;
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
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[YAVideoCell class] forCellWithReuseIdentifier:cellID];
    [self.collectionView setAllowsMultipleSelection:NO];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.collectionView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newVideoTaken) name:@"new_video_taken" object:nil];
    
    if([YAUser currentUser].currentGroup.videos.count) {
        CGFloat width = VIEW_WIDTH * .8;
        self.noVideosLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, self.collectionView.frame.origin.y + 50, width, width)];
        [self.noVideosLabel setText:@"You have no videos yet, touch the button to take one"];
        [self.noVideosLabel setNumberOfLines:1];
        [self.noVideosLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
        [self.noVideosLabel setTextAlignment:NSTextAlignmentCenter];
        [self.noVideosLabel setTextColor:[UIColor whiteColor]];
        [self.collectionView addSubview:self.noVideosLabel];
    }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self.collectionView name:@"new_video_taken" object:nil];
}

- (void)newVideoTaken {
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
        self.collectionView.contentOffset = CGPointMake(0, 0);
    } completion:nil];
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
    
    if(self.targetLayout == self.gridLayout) {
        cell.gifView.animatedImage = nil;
        NSString *gifFilename = [[YAUser currentUser].currentGroup.videos[indexPath.row] gifFilename];
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            
            NSURL *gifURL = [YAUtils urlFromFileName:gifFilename];
            
            NSData *gifData = [NSData dataWithContentsOfURL:gifURL];
            
            FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:gifData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.playerVC = nil;
                cell.gifView.animatedImage = image;
            });
        });
    } else if(self.targetLayout == self.swipeLayout) {
        AVPlaybackViewController* vc = [[AVPlaybackViewController alloc] init];
        
        NSString *movFileName = [[YAUser currentUser].currentGroup.videos[indexPath.row] movFilename];
        
        [vc setURL:[YAUtils urlFromFileName:movFileName]];
        cell.playerVC = vc;
        
        [cell.playerVC playWhenReady];
    }
    else {
        cell.playerVC = nil;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *newLayout = self.collectionView.collectionViewLayout == self.gridLayout ? self.swipeLayout : self.gridLayout;
    
    __weak typeof(self) weakSelf = self;
    self.disableScrollHandling = YES;
    [self.collectionView setPagingEnabled:newLayout == self.swipeLayout];
    
    self.targetLayout = newLayout;
    
    self.collectionView.alwaysBounceVertical = newLayout == self.gridLayout;
    
    if(newLayout == self.gridLayout) {
        for (YAVideoCell *videoCell in self.collectionView.visibleCells) {
            videoCell.playerVC = nil;
        }
        
        [self.collectionView setCollectionViewLayout:newLayout animated:YES completion:^(BOOL finished) {
            [weakSelf.delegate showCamera:YES showPart:NO completion:^{
                if(finished) {
                    weakSelf.disableScrollHandling = NO;
                    [weakSelf.collectionView reloadData];
                }
            }];
        }];
    }
    else {
        [self.delegate showCamera:NO showPart:NO completion:^{
            
        }];
        
        [self.collectionView setCollectionViewLayout:newLayout animated:YES completion:^(BOOL finished) {
            if (finished) {
                
                [weakSelf.collectionView reloadData];
            }
            
        }];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(YAVideoCell*)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    cell.playerVC = nil;
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(self.disableScrollHandling) {
        return;
    }
    
    BOOL scrollingFast = [self scrollingFast];
    
    [self playPauseOnScroll:scrollingFast];
    
    self.scrolling = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    BOOL scrollingFast = fabs(velocity.y) > 1;

    BOOL scrollingUp = velocity.y == fabs(velocity.y);//targetContentOffset->y < self.collectionView.contentOffset.y;
    
    NSLog(@"dragged with velocity:%f %@", fabs(velocity.y), scrollingUp ? @"up" : @"down");
    //show/hide camera
    if(scrollingFast && scrollingUp) {
        self.disableScrollHandling = YES;
        [self.delegate showCamera:NO showPart:YES completion:^{
            self.disableScrollHandling = NO;
            [self playVisible:YES];
        }];
    }
    else if(scrollingFast && !scrollingUp){
        self.disableScrollHandling = YES;
        [self.delegate showCamera:YES showPart:NO completion:^{
            self.disableScrollHandling = NO;
            [self playVisible:YES];
        }];
    }
    
    self.scrolling = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if(self.collectionView.collectionViewLayout != self.swipeLayout)
        self.disableScrollHandling = NO;
    
    self.scrolling = NO;
}

- (void)playVisible:(BOOL)playValue {
    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        if(playValue) {
            if(!videoCell.gifView.isAnimating) {
                [videoCell.gifView startAnimating];
            }
        }
        else {
            if(videoCell.gifView.isAnimating) {
                [videoCell.gifView stopAnimating];
            }
        }
    }
}

#pragma mark - Pull down to refresh - Not implemented
//- (void) triggerRemoteLoad:(NSString *)uid {
//    //val TODO
//    //    [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
//    //        if(dataSnapshot.value != [NSNull null]){
//    //            NSError *error = nil;
//    //
//    //            NSData *videoData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value[@"video"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
//    //
//    //            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value[@"thumb"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
//    //
//    //            if(videoData != nil && imageData != nil){
//    //                NSURL *movieURL = [uid movieUrl];
//    //                [videoData writeToURL:movieURL options:NSDataWritingAtomic error:&error];
//    //
//    //                NSURL *imageURL = [uid imageUrl];
//    //                [imageData writeToURL:imageURL options:NSDataWritingAtomic error:&error];
//    //            }
//    //
//    //            [self finishedLoading:uid];
//    //
//    //        }
//    //    }];
//}
//
//- (void)finishedLoading:(NSString *)uid {
//    for(YAVideoCell *cell in [self.collectionViewController.collectionView visibleCells]){
//        if([cell.uid isEqualToString:uid]){
//            NSLog(@"finished loading?");
//            [[self.collectionViewController.collectionView reloadItemsAtIndexPaths:@[[[self.collectionViewController.collectionViewindexPathForCell:tile]]];
//              }
//              }
//              }
//
//              - (void) refreshTable {
//                  [self.pull endRefreshing];
//              }

@end
