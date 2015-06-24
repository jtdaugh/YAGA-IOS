//
//  MainViewController.h
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAUser.h"
#import "YAGroupsNavigationController.h"
#import "YACameraViewController.h"

@class YAGroupsViewController;

typedef void (^cameraCompletion)(void);

@protocol YAGridViewControllerDelegate <UIViewControllerTransitioningDelegate>
- (void)showCamera:(BOOL)show showPart:(BOOL)showPart animated:(BOOL)animated completion:(cameraCompletion)completion;
- (void)enableRecording:(BOOL)enable;
- (void)scrollViewDidScroll;
- (void)updateCameraAccessories;
- (void)setInitialAnimationFrame:(CGRect)initialFrame;
@end


@interface YAGridViewController : UIViewController <UIApplicationDelegate,
YACameraViewControllerDelegate, YAGridViewControllerDelegate>

@property (nonatomic, readonly) YACameraViewController *cameraViewController;
@property (nonatomic, strong) YAGroupsNavigationController *groupsNavigationController;

@end
