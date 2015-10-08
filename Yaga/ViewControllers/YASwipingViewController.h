//
//  ViewController.h
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YASwipeToDismissViewController.h"

@protocol YASuspendableGesturesDelegate
- (void)suspendAllGestures:(id)sender;
- (void)restoreAllGestures:(id)sender;
- (void)dismissAnimated;
@end

@protocol YASwipingViewControllerDelegate <NSObject>
- (void)swipingController:(id)controller scrollToIndex:(NSUInteger)index;
@end

@interface YASwipingViewController : YASwipeToDismissViewController <UIScrollViewDelegate, YASuspendableGesturesDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
- (id)initWithVideos:(NSArray *)videos initialIndex:(NSUInteger)initialIndex;

@property (nonatomic, weak) id<YASwipingViewControllerDelegate> delegate;

@end

