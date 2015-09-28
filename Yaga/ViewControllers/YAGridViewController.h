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
- (void)updateCameraAccessoriesWithViewIndex:(NSUInteger)index;
- (void)setInitialAnimationFrame:(CGRect)initialFrame;
- (void)swapOutOfOnboardingState;
- (void)showFindGroups;


@end


@interface YAGridViewController : UIViewController <UIApplicationDelegate,
YACameraViewControllerDelegate, YAGridViewControllerDelegate>

@property (nonatomic, readonly) YACameraViewController *cameraViewController;

- (void)createChatFinishedWithGroup:(YAGroup *)group wasPreexisting:(BOOL)preexisting;

@end
