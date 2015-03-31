//
//  ViewController.h
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YASwipingViewController : UIViewController<UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

- (id)initWithInitialIndex:(NSUInteger)initialIndex;

- (void)removeGestures;

@end

