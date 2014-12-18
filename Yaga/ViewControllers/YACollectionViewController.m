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

@interface YACollectionViewController ()

@property (strong, nonatomic) UICollectionViewFlowLayout *gridLayout;
@property (strong, nonatomic) UICollectionViewFlowLayout *swipeLayout;

@property (strong, nonatomic) NSMutableArray *vidControllers;

@end

static NSString *cellID = @"Cell";
//static NSUInteger times = 0;

@implementation YACollectionViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startoverFinishedVids) name:@"startoverFinishedVids" object:nil];
    
    CGFloat spacing = 1.0f;
    
    self.gridLayout= [[UICollectionViewFlowLayout alloc] init];
    //[self.gridLayout setSectionInset:UIEdgeInsetsMake(VIEW_HEIGHT/2 + spacing, 0, 0, 0)];
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 100;///[YAUser currentUser].currentGroup.videos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YAVideoCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    if(!cell.videoPlayer)
        cell.videoPlayer = [self createRandomVideoController];
    
    cell.videoPlayer.view.frame = cell.bounds;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *newLayout = self.collectionView.collectionViewLayout == self.gridLayout ? self.swipeLayout : self.gridLayout;
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView setCollectionViewLayout:newLayout animated:YES completion:^(BOOL finished) {
        weakSelf.scrolling = NO;
        [weakSelf.collectionView setPagingEnabled:newLayout == weakSelf.swipeLayout];
    }];
}

#pragma mark -
- (NSURL*)rndVideoURL {
    NSString *filename = [NSString stringWithFormat:@"%d", arc4random() % 6];
    NSURL *url = [[NSBundle mainBundle] URLForResource:filename withExtension:@"mp4"];
    return url;
}

- (VideoPlayerViewController*)createRandomVideoController {
    
    VideoPlayerViewController *vc = [[VideoPlayerViewController alloc] init];
    vc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    vc.URL = [self rndVideoURL];
    NSLog(@"%@ started playing", vc.URL.absoluteString);
    
    @synchronized(self) {
        if(!self.vidControllers)
            self.vidControllers = [@[] mutableCopy];
        
      //  NSLog(@"createRandomVideoController called %lu times", (unsigned long)++times);
        [self.vidControllers addObject:vc];
    }
    return vc;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    @synchronized(self) {
        self.scrolling = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    @synchronized(self) {
        self.scrolling = NO;
    }
    [self startoverFinishedVids];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(!decelerate){
        @synchronized(self) {
            self.scrolling = NO;
        }
        
        [self performSelector:@selector(startoverFinishedVids) withObject:self afterDelay:0.1];
    }
}

- (void)startoverFinishedVids {
    @synchronized(self) {
        for (VideoPlayerViewController *videoVC in [self.vidControllers copy]) {
            if(self.scrolling)
                return;
            
            if(videoVC.pendingReplay) {
                [videoVC.playerItem seekToTime:kCMTimeZero];
                [videoVC.player play];
                videoVC.pendingReplay = NO;
            }
            if(!videoVC.view.superview)
                [self.vidControllers removeObject:videoVC];
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
