//
//  CameraViewController.h
//  Pic6
//
//  Created by Raj Vir on 8/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraViewController : UIViewController
@property (strong, nonatomic) UIViewController *currentViewController;
- (void)customPresentViewController:(UIViewController *)viewControllerToPresent;
@end
