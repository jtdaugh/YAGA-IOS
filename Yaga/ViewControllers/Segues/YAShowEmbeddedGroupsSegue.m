//
//  YAShowUserGroupsSegue.m
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAShowEmbeddedGroupsSegue.h"
#import "YAGroupsViewController.h"
#import "GridViewController.h"

@implementation YAShowEmbeddedGroupsSegue

- (void)perform {
    YAGroupsViewController *groupsViewController = (YAGroupsViewController*)self.destinationViewController;
    groupsViewController.embeddedMode = YES;
    
    GridViewController *gridController = (GridViewController*)self.sourceViewController;
    gridController.groupsViewController = groupsViewController;
    
    groupsViewController.view.backgroundColor = [UIColor whiteColor];
    
    [gridController addChildViewController:groupsViewController];
    [gridController.view addSubview:groupsViewController.view];
    [groupsViewController didMoveToParentViewController:gridController];
    
    groupsViewController.view.alpha = 0;
    groupsViewController.view.transform = CGAffineTransformMakeScale(0.0, 0.0);
    
    UITapGestureRecognizer *tapToClose1 = [[UITapGestureRecognizer alloc] initWithTarget:gridController action:@selector(closeGroups)];
    [gridController.cameraViewController.view addGestureRecognizer:tapToClose1];
    groupsViewController.cameraTapToClose = tapToClose1;
    
    UITapGestureRecognizer *tapToClose2 = [[UITapGestureRecognizer alloc] initWithTarget:gridController action:@selector(closeGroups)];
    [gridController.collectionSwipe.view addGestureRecognizer:tapToClose2];
    groupsViewController.collectionTapToClose = tapToClose2;
    
    
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
        
        CGFloat origin = -gridController.cameraViewController.view.frame.size.height + ELEVATOR_MARGIN + recordButtonWidth / 2;
        gridController.cameraViewController.view.frame = CGRectMake(0, origin, VIEW_WIDTH, gridController.cameraViewController.view.frame.size.height);
        
        [gridController.cameraViewController showCameraAccessories:NO];
        
        groupsViewController.view.alpha = 1.0;
        groupsViewController.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
        
        origin += gridController.cameraViewController.view.frame.size.height - recordButtonWidth/2;
        
        groupsViewController.view.frame = CGRectMake(0, origin, VIEW_WIDTH, VIEW_HEIGHT - origin * 2);
        
        origin += groupsViewController.view.frame.size.height;
        
        gridController.collectionSwipe.view.frame = CGRectMake(0, origin - VIEW_HEIGHT/2 + CAMERA_MARGIN, gridController.collectionSwipe.view.frame.size.width, gridController.collectionSwipe.view.frame.size.height);
        
    } completion:^(BOOL finished) {
        gridController.elevatorOpen = YES;
        gridController.cameraViewController.cameraView.tapToFocusRecognizer.enabled = NO;
    }];
}

//to suppress warning
- (void)closeGroups {
    
}

@end
