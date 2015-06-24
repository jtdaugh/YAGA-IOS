//
//  YAPostCaptureViewController.h
//  Yaga
//
//  Created by Jesse on 6/23/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YASwipingViewController.h"

@interface YAPostCaptureViewController : UIViewController <YASuspendableGesturesDelegate>

@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
- (id)initWithVideo:(YAVideo *)video;
- (void)dismissAnimated;


@end
