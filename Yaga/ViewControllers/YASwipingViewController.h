//
//  ViewController.h
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YASwipeToDismissViewController.h"

@protocol YASwipableContainer <NSObject>

- (void)suspendAllGestures:(id)sender;
- (void)restoreAllGestures:(id)sender;
- (void)dismissAnimated;
- (void)currentVideoRemovedFromList;

@end

@protocol YASwipingViewControllerDelegate <NSObject>
- (void)swipingController:(id)controller didScrollToIndex:(NSUInteger)index;
@end

@interface YASwipingViewController : YASwipeToDismissViewController <UIScrollViewDelegate, YASwipableContainer>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, weak) id<YASwipingViewControllerDelegate> delegate;

- (id)initWithVideos:(NSArray *)videos initialIndex:(NSUInteger)initialIndex;

@property (nonatomic, assign) BOOL pendingMode;

@end

