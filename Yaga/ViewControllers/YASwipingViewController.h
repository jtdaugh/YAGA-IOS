//
//  ViewController.h
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YASuspendableGesturesDelegate <NSObject>

- (void)suspendAllGestures;
- (void)restoreAllGestures;

@end

@interface YASwipingViewController : UIViewController<UIScrollViewDelegate, YASuspendableGesturesDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
- (id)initWithInitialIndex:(NSUInteger)initialIndex;
@end

