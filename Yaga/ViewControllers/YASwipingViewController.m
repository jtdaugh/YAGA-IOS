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
#import "Yaga-Bridging-Header.h"

@interface YASwipingViewController ()

@property (nonatomic, strong) NSMutableArray *pages;

@property (nonatomic, assign) NSUInteger currentPageIndex;
@property (nonatomic, assign) NSUInteger previousPageIndex;

@property (nonatomic, assign) NSUInteger initialIndex;

@property (nonatomic, strong) UIImageView *jpgImageView;

@property (nonatomic, assign) BOOL dismissed;

@end

#define kSeparator 10
#define kDismissalTreshold 400.0f

@implementation YASwipingViewController

- (id)initWithInitialIndex:(NSUInteger)initialIndex {
    self = [super init];
    if(self) {
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
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:rect];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    self.scrollView.contentSize = CGSizeMake([YAUser currentUser].currentGroup.videos.count * self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    self.scrollView.pagingEnabled = YES;
    
    //gesture recognizers
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pageTapped:)];
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteVideo:)  name:VIDEO_DID_DELETE_NOTIFICATION  object:nil];
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.view addGestureRecognizer:self.panGesture];
    
    //show selected video fullscreen jpg preview
    [self showJpgPreview:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //hide selected video fullscreen jpg preview
    [self showJpgPreview:NO];
    
    [self initPages];
}

- (void)showJpgPreview:(BOOL)show {
    if(show) {
        YAVideo *video  = [[YAUser currentUser].currentGroup.videos objectAtIndex:self.initialIndex];
        NSString *jpgPath = [YAUtils urlFromFileName:video.jpgFullscreenFilename].path;
        UIImage *jpgImage = [UIImage imageWithContentsOfFile:jpgPath];
        if(!self.jpgImageView) {
            self.jpgImageView = [[UIImageView alloc] initWithImage:jpgImage];
            self.jpgImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        }
        else
            self.jpgImageView.image = jpgImage;
        

        [self.view addSubview:self.jpgImageView];
    }
    else {
        [self.jpgImageView removeFromSuperview];
        self.jpgImageView = nil;
    }
}

#pragma mark - Animated dismissal
- (void)panGesture:(UIPanGestureRecognizer *)rec
{
    if(self.dismissed)
        return;
    
    CGPoint vel = [rec velocityInView:self.view];
    CGPoint tr = [rec translationInView:self.view];

    
    if(tr.y > 0) {
        CGFloat f = tr.y / [UIScreen mainScreen].bounds.size.height;
        if(f < 1) {
            CGRect r = self.view.frame;
            r.origin.y = tr.y;
            r.origin.x = tr.x;
            self.view.frame = r;
        }
        else {
            [self dismissAnimated];
            return;
        }
    }
    else {
        [self restoreAnimated];
    }
    
    if(rec.state == UIGestureRecognizerStateEnded) {
        if(vel.y > kDismissalTreshold) {
            [self dismissAnimated];
            return;
        }
        
        //put back
        [self restoreAnimated];
    }
    
}

- (void)dismissAnimated {
    self.dismissed = YES;
    
    //dismiss
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height * .5, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.view.alpha = 0.0;
        self.view.transform = CGAffineTransformMakeScale(0.5,0.5);
    } completion:^(BOOL finished) {
        if(finished)
            [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)restoreAnimated {
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        self.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    } completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DELETE_NOTIFICATION object:nil];
}

- (void)pageTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)tileIndexFromPageIndex:(NSUInteger)pageIndex {
    NSUInteger result = 0;
    
    if(pageIndex == 0) {
        result = 0;
    }
    else {
        if(pageIndex == [YAUser currentUser].currentGroup.videos.count - 1) {
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
    
    NSUInteger initialTileIndex = [self tileIndexFromPageIndex:self.initialIndex];
    
    for(NSUInteger i = initialTileIndex; i < initialTileIndex + 3; i++) {
        CGRect pageFrame = CGRectMake(i * self.scrollView.bounds.size.width, 0, self.scrollView.bounds.size.width - kSeparator, self.scrollView.bounds.size.height);
        
        YAVideoPage *page = [[YAVideoPage alloc] initWithFrame:pageFrame];
        page.presentingVC = self;
        page.backgroundColor = [UIColor blackColor];
        
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
    
    if(self.currentPageIndex != self.previousPageIndex)
        [self updatePages:NO];
    
    self.previousPageIndex = self.currentPageIndex;
}

- (void)updatePages:(BOOL)preload {
    [self adjustPageFrames];
    
    NSUInteger tilePageIndex = 0;
    
    //first page, current on the left
    if(self.currentPageIndex == 0) {
        [self updatePageAtIndex:0 withVideoAtIndex:0 shouldPreload:preload];
        
        if([YAUser currentUser].currentGroup.videos.count > 1)
            [self updatePageAtIndex:1 withVideoAtIndex:1 shouldPreload:preload];
        
        if([YAUser currentUser].currentGroup.videos.count > 2)
            [self updatePageAtIndex:2 withVideoAtIndex:2 shouldPreload:preload];
        
        tilePageIndex = 0;
    }
    //last page, current on the right
    else if(self.currentPageIndex == [YAUser currentUser].currentGroup.videos.count - 1) {
        //special case when there is less than 3 videos
        if([YAUser currentUser].currentGroup.videos.count < 3) {
            //index is always greater than 0 here, as previous condition index == 0 has already passed
            [self updatePageAtIndex:0 withVideoAtIndex:self.currentPageIndex - 1 shouldPreload:preload];
            [self updatePageAtIndex:1 withVideoAtIndex:self.currentPageIndex shouldPreload:preload];
            
            tilePageIndex = 1;
        }
        else {
            if(self.currentPageIndex > 1)
                [self updatePageAtIndex:0 withVideoAtIndex:self.currentPageIndex - 2 shouldPreload:preload];
            
            if(self.currentPageIndex > 0)
                [self updatePageAtIndex:1 withVideoAtIndex:self.currentPageIndex - 1 shouldPreload:preload];
            
            [self updatePageAtIndex:2 withVideoAtIndex:self.currentPageIndex shouldPreload:preload];
            
            tilePageIndex = 2;
        }
    }
    //rest of pages, current in the middle
    else if(self.currentPageIndex > 0) {
        
        if([YAUser currentUser].currentGroup.videos.count > 0)
            [self updatePageAtIndex:0 withVideoAtIndex:self.currentPageIndex - 1 shouldPreload:preload];
        
        [self updatePageAtIndex:1 withVideoAtIndex:self.currentPageIndex shouldPreload:preload];
        
        if(self.currentPageIndex + 1 <= [YAUser currentUser].currentGroup.videos.count - 1)
            [self updatePageAtIndex:2 withVideoAtIndex:self.currentPageIndex + 1 shouldPreload:preload];
        
        tilePageIndex = 1;
    }
    
    for(NSUInteger i = 0; i < 3; i++) {
        YAVideoPage *page = self.pages[i];
        if(i == tilePageIndex && preload) {
            if(![page.playerView isPlaying])
                page.playerView.playWhenReady = YES;
        }
        else {
            page.playerView.playWhenReady = NO;
            [page.playerView pause];
        }
    }
}

- (void)adjustPageFrames {
    BOOL scrolledRight = NO;
    
    if(self.currentPageIndex == self.previousPageIndex) {
        return;
    }
    else if(self.currentPageIndex > self.previousPageIndex) {
        scrolledRight = YES;
    }
    
    NSUInteger lastPageIndex = [YAUser currentUser].currentGroup.videos.count - 1;
    
    if(self.currentPageIndex == lastPageIndex)
        return;
    
    YAVideoPage *left = self.pages[0];
    YAVideoPage *right = self.pages[2];
    
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

- (void)updatePageAtIndex:(NSUInteger)pageIndex withVideoAtIndex:(NSUInteger)videoIndex shouldPreload:(BOOL)shouldPlay {
    YAVideo *video = [YAUser currentUser].currentGroup.videos[videoIndex];
    YAVideoPage *page = self.pages[pageIndex];
    [page setVideo:video shouldPreload:shouldPlay];
}

#pragma mark - YAVideoPageDelegate 
- (void)didDeleteVideo:(id)sender {
    if(![YAUser currentUser].currentGroup.videos.count) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    self.scrollView.contentSize = CGSizeMake([YAUser currentUser].currentGroup.videos.count * self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    
    [self updatePages:YES];
}
@end
