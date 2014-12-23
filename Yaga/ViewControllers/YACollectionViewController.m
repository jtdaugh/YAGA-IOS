//
//  CollectionViewController.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YACollectionViewController.h"
#import "YAGifGenerator.h"
#import "VideoPlayerViewController.h"
#import "YaVideoCell.h"
#import "YAVideoCell.h"

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;
@property (strong, nonatomic) UICollectionViewFlowLayout *swipeLayout;

@property (strong, nonatomic) NSMutableArray *vidControllers;

@property (nonatomic, strong) AssetBrowserSource *assetSource;

@property (nonatomic, strong) UIView *fastScrollingIndicatorView;
@property (nonatomic, assign) BOOL disablePlayPause;

@property (nonatomic, strong) NSMapTable *animationImagesMap;

@end

static NSString *cellID = @"Cell";

@implementation YACollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat spacing = 1.0f;
    
    self.gridLayout= [[UICollectionViewFlowLayout alloc] init];
    [self.gridLayout setSectionInset:UIEdgeInsetsMake(VIEW_HEIGHT/2 + spacing, 0, 0, 0)];
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
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[YAVideoCell class] forCellWithReuseIdentifier:cellID];
    [self.collectionView setAllowsMultipleSelection:NO];
    //    [self.gridTiles setBounces:NO];
    [self.view addSubview:self.collectionView];
    
    self.assetSource = [[AssetBrowserSource alloc] initWithSourceType:AssetBrowserSourceTypeCameraRoll];
    self.assetSource.delegate = self;
    [self.assetSource buildSourceLibrary];
    
    self.fastScrollingIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.fastScrollingIndicatorView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:self.fastScrollingIndicatorView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"memory warning!!");
}

#pragma mark - UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    //--- TEST 1 (local gifs)
//    return 200;
    
    return self.animationImagesMap.count; //[YAUser currentUser].currentGroup.videos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    cell.backgroundColor = [UIColor yellowColor];
    
    cell.gifView.animatedImage = nil;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
//--- TEST 1 (local gifs)
//        NSUInteger gifIndex = indexPath.row;
//        NSUInteger localGifsCount = 25;
//        if(gifIndex > localGifsCount) {
//            NSUInteger n = indexPath.row / localGifsCount;
//            gifIndex = indexPath.row - n * localGifsCount;
//        }
//        
//        NSURL *gifUrl = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"200 (%lu)", (unsigned long)gifIndex] withExtension:@"gif"];
//        NSData *gifData = [NSData dataWithContentsOfURL:gifUrl];
//        FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:gifData];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            cell.gifView.animatedImage = image;
//        });
        
// GENERATED GIFS
        dispatch_async(dispatch_get_main_queue(), ^{
            AVURLAsset *asset = (AVURLAsset*)[self.cameraRollItems[indexPath.row] asset];
            NSArray *images = [self.animationImagesMap objectForKey:asset][@"imagesArray"];
            NSNumber *duration = [self.animationImagesMap objectForKey:asset][@"duration"];
            cell.gifView.animationImages = images;
            cell.gifView.animationDuration = duration.floatValue;
            [cell.gifView startAnimating];
        });
    });
   
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *newLayout = self.collectionView.collectionViewLayout == self.gridLayout ? self.swipeLayout : self.gridLayout;
    
    __weak typeof(self) weakSelf = self;
    self.disablePlayPause = YES;
    [self.collectionView setCollectionViewLayout:newLayout animated:YES completion:^(BOOL finished) {
        [weakSelf.collectionView setPagingEnabled:newLayout == weakSelf.swipeLayout];
        weakSelf.disablePlayPause = NO;
    }];
}

#pragma mark -
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
        // NSLog(@"Fast");
    } else {
        result = NO;
        // NSLog(@"Slow");
    }
    
    lastOffset = currentOffset;
    lastOffsetCapture = currentTime;
    return result;
}

- (void)playPauseOnScroll {
    if(self.disablePlayPause)
        return;
    
    BOOL scrollingFast = [self scrollingFast];
    self.fastScrollingIndicatorView.backgroundColor = scrollingFast ? [UIColor redColor] : [UIColor greenColor];
    [self playVisible:[NSNumber numberWithBool:!scrollingFast]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self playPauseOnScroll];
    
    self.scrolling = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self playPauseOnScroll];
    
    self.scrolling = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.scrolling = NO;
}

- (void)playVisible:(NSNumber*)playValue {
    for(YAVideoCell *videoCell in self.collectionView.visibleCells) {
        if([playValue boolValue]) {
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

- (void)assetBrowserSourceItemsDidChange:(AssetBrowserSource*)source {
    self.cameraRollItems = source.items;
    //[self.collectionView reloadData];
    NSLog(@"assets loaded, count: %lu", (unsigned long)self.cameraRollItems.count);
    
    
    for (AssetBrowserItem* item in self.cameraRollItems)
    {
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            YAGifGenerator *gen = [YAGifGenerator new];
            AVURLAsset *asset = (AVURLAsset*)item.asset;
            [gen crateImagesArrayFromAsset:asset ofSize:10 completionHandler:^(NSArray *array, Float64 duration) {
                NSLog(@"%@", array);
                if (!self.animationImagesMap) {
                    self.animationImagesMap = [NSMapTable new];
                }

                [self.animationImagesMap setObject:@{@"imagesArray":array, @"duration":[NSNumber numberWithFloat:duration]} forKey:asset];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                });
                
                //test for just one item
                
            }];
        });
        
        //test for just one item
        break;
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
