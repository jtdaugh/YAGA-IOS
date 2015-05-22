//
//  YACommentsOverlayViewController.m
//  Yaga
//
//  Created by Christopher Wendel on 5/21/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACommentsOverlayViewController.h"
#import "UIWindow+YASnapshot.h"
#import "YACommentsOverlayView.h"

@interface YACommentsOverlayViewController ()

@end

@implementation YACommentsOverlayViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.commentsOverlayView];
    self.commentsOverlayView.frame = self.view.bounds;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.commentsOverlayView.frame = self.view.bounds;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIWindow *window = self.commentsOverlayView.previousKeyWindow;
    if (!window) {
        window = [[UIApplication sharedApplication].windows firstObject];
    }
    return [[window ya_viewControllerForStatusBarStyle] preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    UIWindow *window = self.commentsOverlayView.previousKeyWindow;
    if (!window) {
        window = [[UIApplication sharedApplication].windows firstObject];
    }
    return [[window ya_viewControllerForStatusBarHidden] prefersStatusBarHidden];
}

@end
