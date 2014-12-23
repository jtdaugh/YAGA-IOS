//
//  CollectionViewController.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YACollectionViewController.h"
#import "VideoPlayerViewController.h"
#import "YaVideoCell.h"
#import "YAVideoCell.h"
#import "UIImage+Sprite.h"

static NSString *YAVideoImagesAtlas = @"YAVideoImagesAtlas";

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;
@property (strong, nonatomic) UICollectionViewFlowLayout *swipeLayout;

@property (strong, nonatomic) NSMutableArray *vidControllers;

@property (nonatomic, strong) AssetBrowserSource *assetSource;

@property (nonatomic, strong) UIView *fastScrollingIndicatorView;
@property (nonatomic, assign) BOOL disablePlayPause;
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
    
    //fast image cache
    const NSUInteger atlasFramesCount = 49;
    
    FICImageFormat *imageFormatVideoThumbnail = [[FICImageFormat alloc] init];
    imageFormatVideoThumbnail.name = YAVideoImagesAtlas;
    imageFormatVideoThumbnail.family = YAVideoImagesAtlas;
    imageFormatVideoThumbnail.style = FICImageFormatStyle32BitBGR;
    imageFormatVideoThumbnail.imageSize = CGSizeMake(TILE_HEIGHT * sqrt(atlasFramesCount), TILE_HEIGHT * sqrt(atlasFramesCount));
    imageFormatVideoThumbnail.maximumCount = 50;
    imageFormatVideoThumbnail.devices = FICImageFormatDevicePhone;
    imageFormatVideoThumbnail.protectionMode = FICImageFormatProtectionModeNone;
    
    [FICImageCache sharedImageCache].delegate = self;
    [FICImageCache sharedImageCache].formats = @[imageFormatVideoThumbnail];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"memory warning!!");
}

#pragma mark - UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 250;//self.cameraRollItems.count; //[YAUser currentUser].currentGroup.videos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    [[FICImageCache sharedImageCache] asynchronouslyRetrieveImageForEntity:self.cameraRollItems[indexPath.row] withFormatName:YAVideoImagesAtlas completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
        CGSize atlasSize = [[FICImageCache sharedImageCache] formatWithName:YAVideoImagesAtlas].imageSize;
        NSArray *animationImages = [image spritesWithSpriteSheetImage:image spriteSize:atlasSize];
        cell.gifView.animationImages = animationImages;
    }];
        
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
    if (scrollSpeed > 0.1) {
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
    [self.collectionView reloadData];
    NSLog(@"assets loaded, count: %d", self.cameraRollItems.count);

    //dispatch_async(dispatch_get_main_queue(), ^{

    //    if(!self.vidControllers)
    //        self.vidControllers = [@[] mutableCopy];
    //
    //        for(id item in self.cameraRollItems) {
    //            VideoPlayerViewController *vc = [[VideoPlayerViewController alloc] init];
    //            vc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //            vc.URL = [item URL];
    //
    //
    //
    //            [self.vidControllers addObject:vc];
    //        }
    //

    // });
    // [[NSNotificationCenter defaultCenter] postNotificationName:@"didReadCameraRoll" object:nil];
}

#pragma mark - FICImageCacheDelegate
- (void)imageCache:(FICImageCache *)imageCache wantsSourceImageForEntity:(id <FICEntity>)entity withFormatName:(NSString *)formatName completionBlock:(FICImageRequestCompletionBlock)completionBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        AssetBrowserItem *browserItem = (AssetBrowserItem*)entity;
        [browserItem generateGifAtlasWithompletionHandler:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(image);
            });
        }];
    });
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
