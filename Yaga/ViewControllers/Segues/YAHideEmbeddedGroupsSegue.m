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
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        
        gridController.cameraViewController.view.frame = CGRectMake(0, 0, gridController.cameraViewController.view.frame.size.width, gridController.cameraViewController.view.frame.size.height);
        
        CGFloat origin = gridController.cameraViewController.view.frame.origin.y + gridController.cameraViewController.view.frame.size.height - recordButtonWidth / 2;
        gridController.collectionViewController.view.frame = CGRectMake(0, origin - VIEW_HEIGHT/2 + CAMERA_MARGIN, gridController.collectionViewController.view.frame.size.width, VIEW_HEIGHT - CAMERA_MARGIN);
        
        [gridController.cameraViewController showCameraAccessories:YES];
        
        [groupsController.view setTransform:CGAffineTransformMakeScale(0.75, 0.75)];
        groupsController.view.alpha = 0;
        
        //group can change
        [gridController.cameraViewController updateCurrentGroup];
        [gridController.collectionViewController reload];
    } completion:^(BOOL finished) {
        [groupsController removeFromParentViewController];
        [groupsController.view removeFromSuperview];
        gridController.elevatorOpen = NO;
        
        [gridController.cameraViewController.view removeGestureRecognizer:groupsController.cameraTapToClose];
        [gridController.collectionViewController.view removeGestureRecognizer:groupsController.collectionTapToClose];
        
        gridController.cameraViewController.cameraView.tapToFocusRecognizer.enabled = YES;
        
    }];

}

@end
