//
//  ViewController.m
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import "YASwipingViewController.h"
#import "YAVideoPlayerView.h"
#import "YAVideoPage.h"
#import "YAUtils.h"
#import "YAVideo.h"
#import "YAUser.h"
#import "YADownloadManager.h"
#import "YAViewCountManager.h"
#import "MSAlertController.h"

@interface YASwipingViewController ()

@property (nonatomic, strong) NSMutableArray *videos;

@property (nonatomic, strong) NSMutableArray *pages;

@property (nonatomic, assign) NSUInteger currentPageIndex;
@property (nonatomic, assign) NSUInteger previousPageIndex;
@property (nonatomic, assign) NSUInteger visibleTileIndex;

@property (nonatomic, assign) NSUInteger initialIndex;

@property (nonatomic, strong) UIImageView *jpgImageView;

@property (nonatomic) BOOL alreadyAppeared;

@end

#define kSeparator 2

@implementation YASwipingViewController

- (id)initWithVideos:(NSArray *)videos initialIndex:(NSUInteger)initialIndex {
    self = [super init];
    if(self) {
        self.videos = [videos mutableCopy];
        self.initialIndex = initialIndex;
        self.currentPageIndex = self.initialIndex;
        self.previousPageIndex = self.initialIndex;
    }
    return self;
}

- (UIColor*)rndColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    
    CGRect rect = self.view.bounds;
    rect.size.width += kSeparator;
    
    
    self.jpgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.jpgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.jpgImageView.contentMode = UIViewContentModeScaleAspectFill;

    self.scrollView = [[UIScrollView alloc] initWithFrame:rect];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    self.scrollView.pagingEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteVideo:)  name:VIDEO_DID_DELETE_NOTIFICATION  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidChange:) name:VIDEO_CHANGED_NOTIFICATION object:nil];

    //show selected video fullscreen jpg preview
    [self showJpgPreview:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //hide selected video fullscreen jpg preview
    if(animated && !self.alreadyAppeared){
        [self showJpgPreview:NO];
        
        [self initPages];        
    }
    self.alreadyAppeared = YES;
}

- (void)videoDidChange:(NSNotification *)notification {
    // Only act if this notification is for video on visible page
    YAVideoPage *visiblePage = self.pages[self.visibleTileIndex];
    YAVideo *visibleVideo = visiblePage ? visiblePage.video : nil;

    if([notification.object isEqual:visibleVideo]) {
        if ([YAVideo serverIdStatusForVideo:visibleVideo] == YAVideoServerIdStatusConfirmed) {
            [[YAViewCountManager sharedManager] monitorVideoWithId:visibleVideo.serverId];
        } else {
            [[YAViewCountManager sharedManager] monitorVideoWithId:nil];
        }
        
        // Reload comments, which will initialize with firebase if serverID just became ready.
        [[YAEventManager sharedManager] setCurrentVideoServerId:visibleVideo.serverId localId:visibleVideo.localId serverIdStatus:[YAVideo serverIdStatusForVideo:visibleVideo]];
        [[YAEventManager sharedManager] fetchEventsForVideoWithServerId:visibleVideo.serverId
                                                                localId:visibleVideo.localId
                                                                inGroup:visibleVideo.group.serverId
                                                     withServerIdStatus:[YAVideo serverIdStatusForVideo:visibleVideo]];

    }
}

- (void)willEnterForeground:(NSNotification *)notif {
    YAVideoPage *visiblePage = self.pages[self.visibleTileIndex];
    YAVideo *visibleVideo = visiblePage ? visiblePage.video : nil;
    if (!visibleVideo || [visibleVideo isInvalidated]) return;
    [[YAEventManager sharedManager] setCurrentVideoServerId:visibleVideo.serverId localId:visibleVideo.localId serverIdStatus:[YAVideo serverIdStatusForVideo:visibleVideo]];
    [[YAEventManager sharedManager] fetchEventsForVideoWithServerId:visibleVideo.serverId
                                                            localId:visibleVideo.localId
                                                            inGroup:visibleVideo.group.serverId
                                                 withServerIdStatus:[YAVideo serverIdStatusForVideo:visibleVideo]];
}


- (void)showJpgPreview:(BOOL)show {
    if(show) {
        YAVideo *video  = [self.videos objectAtIndex:self.initialIndex];
        NSString *jpgPath = [YAUtils urlFromFileName:video.jpgFullscreenFilename].path;
        UIImage *jpgImage = [UIImage imageWithContentsOfFile:jpgPath];
        self.jpgImageView.image = jpgImage;
        if (!self.jpgImageView.superview)
            [self.view addSubview:self.jpgImageView];
    }
    else {
        [self.jpgImageView removeFromSuperview];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DELETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION      object:nil];
    [YAViewCountManager sharedManager].videoViewCountDelegate = nil;
    [[YAViewCountManager sharedManager] monitorVideoWithId:nil];
}

- (NSUInteger)firstTileIndexFromInitialPageIndex:(NSUInteger)pageIndex {
    NSUInteger result = 0;
    
    if(pageIndex == 0) {
        result = 0;
    }
    else {
        if(pageIndex == self.videos.count - 1) {
            if(pageIndex >= 2)
                result = pageIndex - 2;
            else
                result = pageIndex - 1;
        }
        else {
            result = pageIndex - 1;
        }
    }
    
    return result;
}

- (void)initPages {
    self.pages = [[NSMutableArray alloc] initWithCapacity:3];
    
    self.scrollView.contentSize = CGSizeMake(self.videos.count * self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    
    NSUInteger initialTileIndex = [self firstTileIndexFromInitialPageIndex:self.initialIndex];
    
    for(NSUInteger i = initialTileIndex; i < initialTileIndex + 3; i++) {
        CGRect pageFrame = CGRectMake(i * self.scrollView.bounds.size.width, 0, self.scrollView.bounds.size.width - kSeparator, self.scrollView.bounds.size.height);
        
        YAVideoPage *page = [[YAVideoPage alloc] initWithFrame:pageFrame];
        page.presentingVC = self;
        page.streamMode = self.streamMode;
        [page setShowAdminControls:self.pendingMode];
        
        pageFrame.origin.x = pageFrame.size.width;
        pageFrame.size.width = kSeparator;
        UIView *v = [[UIView alloc] initWithFrame:pageFrame];
        v.backgroundColor = [UIColor whiteColor];
        [page addSubview:v];
                
        [self.scrollView addSubview:page];
        [self.pages addObject:page];
    }
    
    //go to the initial page
    self.scrollView.contentOffset = CGPointMake(self.initialIndex  * self.scrollView.bounds.size.width, 0);
    [self updatePages:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self updatePages:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //make sure we are in fullscreen(swiping controller is on screen when transitioning back to the grid)
    if(self.scrollView.bounds.size.width < VIEW_WIDTH)
        return;
    
    NSUInteger index = scrollView.contentOffset.x/scrollView.frame.size.width;

    self.currentPageIndex = index;
    
    if(self.currentPageIndex != self.previousPageIndex) {
        [self.delegate swipingController:self didScrollToIndex:index];
        [self updatePages:NO];
    }
    
    self.previousPageIndex = self.currentPageIndex;
}

- (void)updatePages:(BOOL)preload {
    [self adjustPageFrames];
    
    self.visibleTileIndex = 0;
    
    //first page, current on the left
    if(self.currentPageIndex == 0) {
        self.visibleTileIndex = 0;
        
        [self updateTileAtIndex:0 withVideoAtIndex:0 shouldPreload:preload];
        
        if(self.videos.count > 1)
            [self updateTileAtIndex:1 withVideoAtIndex:1 shouldPreload:preload];
        
        if(self.videos.count > 2)
            [self updateTileAtIndex:2 withVideoAtIndex:2 shouldPreload:preload];
    }
    //last page, current on the right
    else if(self.currentPageIndex == self.videos.count - 1) {
        //special case when there is less than 3 videos
        if(self.videos.count < 3) {
            self.visibleTileIndex = 1;
            
            //index is always greater than 0 here, as previous condition index == 0 has already passed
            [self updateTileAtIndex:0 withVideoAtIndex:self.currentPageIndex - 1 shouldPreload:preload];
            [self updateTileAtIndex:1 withVideoAtIndex:self.currentPageIndex shouldPreload:preload];
        }
        else {
            self.visibleTileIndex = 2;
            
            if(self.currentPageIndex > 1)
                [self updateTileAtIndex:0 withVideoAtIndex:self.currentPageIndex - 2 shouldPreload:preload];
            
            if(self.currentPageIndex > 0)
                [self updateTileAtIndex:1 withVideoAtIndex:self.currentPageIndex - 1 shouldPreload:preload];
            
            [self updateTileAtIndex:2 withVideoAtIndex:self.currentPageIndex shouldPreload:preload];
        }
    }
    //rest of pages, current in the middle
    else if(self.currentPageIndex > 0) {
        self.visibleTileIndex = 1;
        
        if(self.videos.count > 0)
            [self updateTileAtIndex:0 withVideoAtIndex:self.currentPageIndex - 1 shouldPreload:preload];
        
        [self updateTileAtIndex:1 withVideoAtIndex:self.currentPageIndex shouldPreload:preload];
        
        if(self.currentPageIndex + 1 <= self.videos.count - 1)
            [self updateTileAtIndex:2 withVideoAtIndex:self.currentPageIndex + 1 shouldPreload:preload];
    }
    
    YAVideo *visibleVideo;
    NSMutableArray *nearbyVideos = [NSMutableArray array];
    
    for(NSUInteger i = 0; i < 3; i++) {
        YAVideoPage *page = self.pages[i];

        if (i == self.visibleTileIndex && preload) {
            visibleVideo = page.video;
            YAVideoServerIdStatus status = [YAVideo serverIdStatusForVideo:page.video];
            [YAEventManager sharedManager].eventReceiver = page;
            [[YAEventManager sharedManager] setCurrentVideoServerId:page.video.serverId localId:page.video.localId serverIdStatus:status];
            [[YAEventManager sharedManager] fetchEventsForVideoWithServerId:page.video.serverId localId:page.video.localId inGroup:page.video.group.serverId withServerIdStatus:status];
            
            [YAViewCountManager sharedManager].videoViewCountDelegate = page;
            [[YAViewCountManager sharedManager] monitorVideoWithId:(status == YAVideoServerIdStatusConfirmed) ? page.video.serverId : nil];

            if(![page.playerView isPlaying])
                page.playerView.playWhenReady = YES;
        } else {
            if (page.video) {
                [nearbyVideos addObject:page.video];
            }
            page.playerView.playWhenReady = NO;
            [page.playerView pause];
        }
    }
    
    [[YADownloadManager sharedManager] exclusivelyDownloadMp4IfNeededForVideo:visibleVideo thenPrioritizeNearbyDownloads:nearbyVideos];
}

- (void)adjustPageFrames {
    BOOL scrolledRight = NO;
    
    if(self.currentPageIndex == self.previousPageIndex) {
        return;
    }
    else if(self.currentPageIndex > self.previousPageIndex) {
        scrolledRight = YES;
    }
    
    NSUInteger lastPageIndex = self.videos.count - 1;
    
    if(self.currentPageIndex == lastPageIndex)
        return;
    
    YAVideoPage *left = self.pages[0];
    YAVideoPage *right = self.pages[2];
    
    [[Mixpanel sharedInstance] track:@"Swiped to Another Video"];

    //moving left page to the right
    if(self.currentPageIndex != 1 && scrolledRight) {
        CGRect frame = left.frame;
        frame.origin.x = right.frame.origin.x + right.frame.size.width + kSeparator;
        left.frame = frame;
        
        [self.pages removeObject:left];
        [self.pages addObject:left];
        
    }
    //moving right page to the left
    else if(self.currentPageIndex != 0 && !scrolledRight) {
        //do not do anything when swiped from the last one to the last but one
        if(self.currentPageIndex == lastPageIndex - 1)
            return;
        
        CGRect frame = right.frame;
        frame.origin.x = left.frame.origin.x - left.frame.size.width - kSeparator;
        right.frame = frame;
        
        [self.pages removeObject:right];
        [self.pages insertObject:right atIndex:0];
    }
}

- (void)updateTileAtIndex:(NSUInteger)tileIndex withVideoAtIndex:(NSUInteger)videoIndex shouldPreload:(BOOL)shouldPlay {
    YAVideo *video = self.videos[videoIndex];
    YAVideoPage *page = self.pages[tileIndex];
    [page setVideo:video shouldPreload:shouldPlay];
}

- (void)didDeleteVideo:(id)sender {
    // Need to dismiss the alert delete confirmation first.
    if (self.pendingMode) return;
    
    __weak YASwipingViewController *weakSelf = self;
    if ([[self presentedViewController] isKindOfClass:[MSAlertController class]]) {
        [self dismissViewControllerAnimated:NO completion:^{
            [weakSelf dismissAnimated];
        }];
    } else {
        [self dismissAnimated];
    }
}

- (void)currentVideoRemovedFromList {
    [self.videos removeObjectAtIndex:self.currentPageIndex];
    
    if(!self.videos.count) {
        [self dismissAnimated];
        return;
    }
    
    for(UIView *page in [self.scrollView.subviews copy]) {
        [page removeFromSuperview];
    }
    
    self.initialIndex = self.currentPageIndex - ((self.currentPageIndex == self.videos.count) ? 1 : 0);
    self.currentPageIndex = self.initialIndex;
    self.previousPageIndex = self.initialIndex;

    [self initPages];
}

#pragma mark - YASuspendableGestureDelegate

- (void)suspendAllGestures:(id)sender {
    // prevent non-visible pages from sending stray calls
    if ([sender isEqual:self.pages[self.visibleTileIndex]]) {
        self.panGesture.enabled = NO;
        self.scrollView.scrollEnabled = NO;
    }
}

- (void)restoreAllGestures:(id)sender  {
    // prevent non-visible pages from sending stray calls
    if ([sender isEqual:self.pages[self.visibleTileIndex]]) {
        self.panGesture.enabled = YES;
        self.scrollView.scrollEnabled = YES;
    }
}



@end
