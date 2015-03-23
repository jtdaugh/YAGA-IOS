//
//  YACollectionSwipeViewController.m
//  Yaga
//
//  Created by Iegor on 3/20/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YACollectionViewController.h"
#import "YAUser.h"
#import "YACollectionSwipeViewController.h"
@interface YACollectionSwipeViewController ()

@property (nonatomic, strong) NSMutableArray *pages;

@property (nonatomic, assign) NSUInteger currentPageIndex;
@property (nonatomic, assign) NSUInteger previousPageIndex;

@property (nonatomic, assign) NSUInteger initialIndex;

@property (nonatomic, strong) UIImageView *jpgImageView;

@property (nonatomic, assign) BOOL dismissed;
@end

#define kSeparator 10
#define kDismissalTreshold 800.0f

@implementation YACollectionSwipeViewController
- (void)initPages {
    self.pages = [[NSMutableArray alloc] initWithCapacity:3];
    NSUInteger initialTileIndex = [self tileIndexFromPageIndex:self.initialIndex];
    
    for(NSUInteger i = initialTileIndex; i < initialTileIndex + 3; i++) {
        CGRect pageFrame = CGRectMake(i * self.scrollView.bounds.size.width, 0, self.scrollView.bounds.size.width - kSeparator, self.scrollView.bounds.size.height);
        YACollectionViewController *ctr = [YACollectionViewController new];
        ctr.view.frame = pageFrame;
       // YAVideoPage *page = [[YAVideoPage alloc] initWithFrame:pageFrame];
//        page.presentingVC = self;
//        page.backgroundColor = [UIColor blackColor];
        [self addChildViewController:ctr];
        [self.scrollView addSubview:ctr.view];
        
       // [self.scrollView addSubview:page];
        [self.pages addObject:ctr];
        ctr.delegate = self.delegate;
    }
    
    //go to the initial page
    self.scrollView.contentOffset = CGPointMake(self.initialIndex  * self.scrollView.bounds.size.width, 0);
    [self updatePages:YES];
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


- (void)updatePageAtIndex:(NSUInteger)pageIndex withVideoAtIndex:(NSUInteger)videoIndex shouldPlay:(BOOL)shouldPlay {
    YAVideo *video = [YAUser currentUser].currentGroup.videos[videoIndex];
    NSLog(@"swiped");
//    YAVideoPage *page = self.pages[pageIndex];
    //[page setVideo:video shouldPlay:shouldPlay];
}

- (void)updatePages:(BOOL)playVideo {
    [self adjustPageFrames];
    
    NSUInteger tilePageIndex = 0;
    
    //first page, current on the left
    if(self.currentPageIndex == 0) {
        [self updatePageAtIndex:0 withVideoAtIndex:0 shouldPlay:playVideo];
        
        if([YAUser currentUser].currentGroup.videos.count > 1)
            [self updatePageAtIndex:1 withVideoAtIndex:1 shouldPlay:playVideo];
        
        if([YAUser currentUser].currentGroup.videos.count > 2)
            [self updatePageAtIndex:2 withVideoAtIndex:2 shouldPlay:playVideo];
        
        tilePageIndex = 0;
    }
    //last page, current on the right
    else if(self.currentPageIndex == [YAUser currentUser].currentGroup.videos.count - 1) {
        //special case when there is less than 3 videos
        if([YAUser currentUser].currentGroup.videos.count < 3) {
            //index is always greater than 0 here, as previous condition index == 0 has already passed
            [self updatePageAtIndex:0 withVideoAtIndex:self.currentPageIndex - 1 shouldPlay:playVideo];
            [self updatePageAtIndex:1 withVideoAtIndex:self.currentPageIndex shouldPlay:playVideo];
            
            tilePageIndex = 1;
        }
        else {
            if(self.currentPageIndex > 1)
                [self updatePageAtIndex:0 withVideoAtIndex:self.currentPageIndex - 2 shouldPlay:playVideo];
            
            if(self.currentPageIndex > 0)
                [self updatePageAtIndex:1 withVideoAtIndex:self.currentPageIndex - 1 shouldPlay:playVideo];
            
            [self updatePageAtIndex:2 withVideoAtIndex:self.currentPageIndex shouldPlay:playVideo];
            
            tilePageIndex = 2;
        }
    }
    //rest of pages, current in the middle
    else if(self.currentPageIndex > 0) {
        
        if([YAUser currentUser].currentGroup.videos.count > 0)
            [self updatePageAtIndex:0 withVideoAtIndex:self.currentPageIndex - 1 shouldPlay:playVideo];
        
        [self updatePageAtIndex:1 withVideoAtIndex:self.currentPageIndex shouldPlay:playVideo];
        
        if(self.currentPageIndex + 1 <= [YAUser currentUser].currentGroup.videos.count - 1)
            [self updatePageAtIndex:2 withVideoAtIndex:self.currentPageIndex + 1 shouldPlay:playVideo];
        
        tilePageIndex = 1;
    }
    
    for(NSUInteger i = 0; i < 3; i++) {
//        YAVideoPage *page = self.pages[i];
//        if(i == tilePageIndex && playVideo) {
//            if(![page.playerView isPlaying])
//                page.playerView.playWhenReady = YES;
//        }
//        else {
//            page.playerView.playWhenReady = NO;
//            [page.playerView pause];
//        }
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
    
    YACollectionViewController *left = self.pages[0];
    YACollectionViewController *right = self.pages[2];
    
    //moving left page to the right
    if(self.currentPageIndex != 1 && scrolledRight) {
        CGRect frame = left.view.frame;
        frame.origin.x = right.view.frame.origin.x + right.view.frame.size.width + kSeparator;
        left.view.frame = frame;
        
        [self.pages removeObject:left];
        [self.pages addObject:left];
        
    }
    //moving right page to the left
    else if(self.currentPageIndex != 0 && !scrolledRight) {
        //do not do anything when swiped from the last one to the last but one
        if(self.currentPageIndex == lastPageIndex - 1)
            return;
        
        CGRect frame = right.view.frame;
        frame.origin.x = left.view.frame.origin.x - left.view.frame.size.width - kSeparator;
        right.view.frame = frame;
        
        [self.pages removeObject:right];
        [self.pages insertObject:right atIndex:0];
    }
}

- (YACollectionViewController *)currentCollectionView
{
    return self.pages[self.currentPageIndex];
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
@end
