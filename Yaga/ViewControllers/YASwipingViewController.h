//
//  ViewController.h
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YASwipingViewControllerDelegate <NSObject>
- (void)swipingController:(id)controller scrollToIndex:(NSUInteger)index;
@end

@interface YASwipingViewController : UIViewController<UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
- (id)initWithInitialIndex:(NSUInteger)initialIndex;
@property (nonatomic, weak) id<YASwipingViewControllerDelegate> delegate;
@end

