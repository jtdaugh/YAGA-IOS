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


@interface YASwipingViewController ()

@property (nonatomic, strong) NSMutableArray *pages;

@property (nonatomic, assign) CGFloat lastContentOffset;

@property (nonatomic, readonly) BOOL scrollingRight;

@property (nonatomic, strong) NSMutableSet *previousVisiblePage;

@property (nonatomic, strong) NSMutableArray *players;
@property (nonatomic, strong) YAVideoPage *currentPage;

@property (nonatomic, assign) NSUInteger initialIndex;

@property (nonatomic, strong) NSArray *videos;
@end

#define kSeparator 10

@implementation YASwipingViewController

- (id)initWithVideos:(NSArray*)videos andInitialIndex:(NSUInteger)initialIndex {
    self = [super init];
    if(self) {
        self.initialIndex = initialIndex;
        self.videos = videos;
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
    
    //self.view.backgroundColor = [UIColor redColor];
    
    CGRect rect = self.view.bounds;
    rect.size.width += kSeparator;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:rect];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    self.pages = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < self.videos.count; i++) {
        CGRect frame = self.scrollView.bounds;
        
        frame.origin.x = i * frame.size.width;
        frame.size.width = frame.size.width - kSeparator;
        
        YAVideoPage *page = [[YAVideoPage alloc] initWithFrame:frame];
        page.video = self.videos[i];
        page.backgroundColor = [UIColor blackColor];
        
        [self.scrollView addSubview:page];
        
        [self.pages addObject:page];
    }
    
    self.scrollView.contentSize = CGSizeMake(self.pages.count * self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    self.scrollView.pagingEnabled = YES;
    
    //init players
    [self initPlayers];
    
    //gesture recognizers
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pageTapped:)];
    [self.view addGestureRecognizer:tap];
    
    UILongPressGestureRecognizer *hold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pageHeld:)];
    [self.view addGestureRecognizer:hold];
}

- (void)pageTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pageHeld:(UITapGestureRecognizer *)recognizer {
    NSLog(@"%ld", (unsigned long)recognizer.state);
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.currentPage.playerView.player.rate = 1.0;
    } else if (recognizer.state == UIGestureRecognizerStateBegan){
        self.currentPage.playerView.player.rate = 3.0;
    }
}

- (void)initPlayers {
    YAVideoPlayerView *player1 = [YAVideoPlayerView new];
    YAVideoPlayerView *player2 = [YAVideoPlayerView new];
    YAVideoPlayerView *player3 = [[YAVideoPlayerView alloc] initWithFrame:CGRectZero];
    self.players = [@[player1, player2, player3] mutableCopy];
    
    //play video at initial index
    self.scrollView.contentOffset = CGPointMake(self.initialIndex  * self.scrollView.bounds.size.width, 0);
    YAVideoPage *initialPage = self.pages[self.initialIndex];
    [self didEndScrollingOnPage:initialPage];
    NSUInteger initialPlayerIndex;
    if(self.initialIndex == 0) {
        initialPlayerIndex = 0;
    }
    else {
        if(self.initialIndex == self.pages.count - 1) {
            initialPlayerIndex = 2;
        }
        else {
            initialPlayerIndex = 1;
        }
    }
    
    [self.players[initialPlayerIndex] setPlayWhenReady:YES];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    NSUInteger pageIndex = scrollView.contentOffset.x/scrollView.frame.size.width;
    
    [self shiftPlayersForCurrentPageAtIndex:pageIndex];
    
    [self didEndScrollingOnPage:self.pages[pageIndex]];
    
    //NSLog(@"scrolling stopped on page %lu", (unsigned long)pageIndex);
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    //NSLog(@"scrollViewWillEndDragging velocity %f", fabs(velocity.x));
}

- (void)willDisplayPage:(YAVideoPage*)page partially:(BOOL)partially {
    //NSLog(@"willDisplayPage, playerView: %@", page.playerView);
    if(!partially)
        page.playerView.playWhenReady = YES;
    
    if(!page.playerView)
        [page showLoading:YES];
}

- (void)didEndDisplayingPage:(YAVideoPage*)page {
    //NSLog(@"didEndDisplayingPage %lu", [self.pages indexOfObject:page]);
    [page.playerView pause];
    page.playerView.playWhenReady = NO;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //scrolling direction
    CGFloat currentOffset = scrollView.contentOffset.x;
    _scrollingRight = self.lastContentOffset < currentOffset;
    self.lastContentOffset = currentOffset;
    
    //willDisplayPage, didEndDisplayingPage
    NSMutableSet *visiblePages = [NSMutableSet set];
    for (YAVideoPage *page in self.pages) {
        if (CGRectIntersectsRect(page.frame, self.scrollView.bounds)) {
            [visiblePages addObject:page];
            if(![self.previousVisiblePage containsObject:page]) {
                CGRect pageRectWithSeparator = page.frame;
                pageRectWithSeparator.size.width += kSeparator;
                [self willDisplayPage:page partially:!CGRectEqualToRect(pageRectWithSeparator, self.scrollView.bounds)];
            }
        }
        else {
            if([self.previousVisiblePage containsObject:page])
                [self didEndDisplayingPage:page];
        }
    }
    
    self.previousVisiblePage = visiblePages;
}

- (void)shiftPlayersForCurrentPageAtIndex:(NSUInteger)pageIndex {
    NSUInteger lastPageIndex = self.pages.count - 1;
    
    if(self.currentPage == self.pages[pageIndex])
        return;
    
    if(pageIndex == lastPageIndex) {
        //additional check for quick swipe to the end
        YAVideoPlayerView *playerView = self.players[2];
        YAVideo *video = self.videos[pageIndex];
        if([playerView.URL.absoluteString isEqualToString:[YAUtils urlFromFileName:video.movFilename].absoluteString])
            return;
    }
    
    if(pageIndex != 1 && self.scrollingRight) {
        YAVideoPlayerView *tmp = self.players[0];
        [self.players removeObjectAtIndex:0];
        [self.players addObject:tmp];
    }
    else if(pageIndex != 0 && !self.scrollingRight) {
        //do not do anything when swiped from the last one to the last but one
        if(pageIndex == lastPageIndex - 1)
            return;
        
        YAVideoPlayerView *tmp = self.players[2];
        [self.players removeObjectAtIndex:2];
        [self.players insertObject:tmp atIndex:0];
    }
}

- (void)didEndScrollingOnPage:(YAVideoPage*)page {
    NSUInteger pageIndex = [self.pages indexOfObject:page];
    
    //first page, current on the left
    if(pageIndex == 0) {
        [self setPlayerAtIndex:0 forPage:page];
        
        if(self.pages.count > 1) {
            [self setPlayerAtIndex:1 forPage:[self.pages objectAtIndex:1]];
        }
        
        if(self.pages.count > 2)
            [self setPlayerAtIndex:2 forPage:[self.pages objectAtIndex:2]];
    }
    //last page, current on the right
    else if(pageIndex == self.pages.count - 1) {
        //special case when there is less than 3 videos
        if(self.pages.count < 3) {
            //pageIndex is always greater than 0 here, as previous condition pageIndex == 0 has already passed
            [self setPlayerAtIndex:0 forPage:[self.pages objectAtIndex:pageIndex - 1]];
            
            [self setPlayerAtIndex:1 forPage:[self.pages objectAtIndex:pageIndex]];

        }
        else {
            if(pageIndex > 1)
                [self setPlayerAtIndex:0 forPage:[self.pages objectAtIndex:pageIndex - 2]];
            
            if(pageIndex > 0)
                [self setPlayerAtIndex:1 forPage:[self.pages objectAtIndex:pageIndex - 1]];
            
            [self setPlayerAtIndex:2 forPage:[self.pages objectAtIndex:pageIndex]];
        }
    }
    //rest of pages, current in the middle
    else if(pageIndex > 0) {
        
        if(self.pages.count > 0)
            [self setPlayerAtIndex:0 forPage:[self.pages objectAtIndex:pageIndex - 1]];
        
        [self setPlayerAtIndex:1 forPage:page];
        
        if(pageIndex + 1 <= self.pages.count - 1)
            [self setPlayerAtIndex:2 forPage:[self.pages objectAtIndex:pageIndex + 1]];
    }
    
    
    self.currentPage = page;
    
    if(![page.playerView isPlaying])
        page.playerView.playWhenReady = YES;
    
    [self logState];
}

- (void)setPlayerAtIndex:(NSUInteger)playerIndex forPage:(YAVideoPage*)page {
    YAVideoPlayerView *playerView = self.players[playerIndex];
    
    page.playerView = playerView;
    
    YAVideo *video = self.videos[[self.pages indexOfObject:page]];
    if(video.movFilename.length)
        page.playerView.URL = [YAUtils urlFromFileName:video.movFilename];
    else
        page.playerView.URL = nil;
}

- (void)logState {
    //NSLog(@"State: %@ | %@ | %@", [self.players[0] URL].lastPathComponent, [self.players[1] URL].lastPathComponent, [self.players[2] URL].lastPathComponent);
}

@end
