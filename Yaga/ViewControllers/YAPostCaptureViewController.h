//
//  YAPostCaptureViewController.h
//  Yaga
//
//  Created by Jesse on 6/23/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YASwipingViewController.h"
#import "YASwipeToDismissViewController.h"
#import "YACameraViewController.h"

@interface YAPostCaptureViewController : YASwipeToDismissViewController <YASuspendableGesturesDelegate>

- (id)initWithVideo:(YAVideo *)video cameraViewController:(YACameraViewController *)cameraViewController;

@end
