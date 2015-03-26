//
//  YAGroupSelectedSegue.m
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAHideEmbeddedGroupsSegue.h"
#import "YAGroupsViewController.h"
#import "GridViewController.h"

@implementation YAHideEmbeddedGroupsSegue

- (void)perform {
    YAGroupsViewController *groupsController = (YAGroupsViewController*)self.sourceViewController;
    GridViewController *gridController = (GridViewController*)[groupsController parentViewController];
    
    [groupsController.view setTransform:CGAffineTransformIdentity];
    
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
        
        
//        CGFloat origin = gridController.cameraViewController.view.frame.origin.y + gridController.cameraViewController.view.frame.size.height - recordButtonWidth / 2;
        
        gridController.collectionSwipe.view.frame = CGRectMake(0, CAMERA_MARGIN, gridController.collectionSwipe.view.frame.size.width, VIEW_HEIGHT - CAMERA_MARGIN);
        
        gridController.cameraViewController.view.frame = CGRectMake(0, 0, gridController.cameraViewController.view.frame.size.width, gridController.cameraViewController.view.frame.size.height);

        [gridController.cameraViewController showCameraAccessories:YES];
        
        [groupsController.view setTransform:CGAffineTransformMakeScale(0.75, 0.0)];
        groupsController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [groupsController removeFromParentViewController];
        [groupsController.view removeFromSuperview];
        gridController.elevatorOpen = NO;
        
        [gridController.cameraViewController.view removeGestureRecognizer:groupsController.cameraTapToClose];
        [gridController.collectionSwipe.view removeGestureRecognizer:groupsController.collectionTapToClose];
        
        gridController.cameraViewController.cameraView.tapToFocusRecognizer.enabled = YES;
        [gridController.cameraViewController updateCurrentGroupName];
    }];

}

@end
