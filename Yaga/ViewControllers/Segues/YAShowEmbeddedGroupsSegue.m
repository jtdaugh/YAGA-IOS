//
//  YAShowUserGroupsSegue.m
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAShowEmbeddedGroupsSegue.h"
#import "MyGroupsViewController.h"
#import "GridViewController.h"

@implementation YAShowEmbeddedGroupsSegue

- (void)perform {
    MyGroupsViewController *groupsController = (MyGroupsViewController*)self.destinationViewController;
    GridViewController *gridController = (GridViewController*)self.sourceViewController;
    
    groupsController.showCreateGroupButton = YES;
    groupsController.showEditButton = YES;
    
    [gridController addChildViewController:groupsController];
    //self.groupsViewController.view.frame = CGRectMake(0, ELEVATOR_MARGIN, self.groupsViewController.view.frame.size.width, self.view.bounds.size.height - ELEVATOR_MARGIN);
    [gridController.view addSubview:groupsController.view];
    [groupsController didMoveToParentViewController:gridController];
    
    // self.groupsViewController.view.transform = CGAffineTransformMakeScale(0.75, 0.75);
    groupsController.view.alpha = 0.0;
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        [gridController.cameraView setFrame:CGRectMake(0, -gridController.cameraView.frame.size.height + ELEVATOR_MARGIN, gridController.cameraView.frame.size.width, gridController.cameraView.frame.size.height)];
        
        groupsController.view.frame = CGRectMake(0, ELEVATOR_MARGIN, groupsController.view.frame.size.width, gridController.view.bounds.size.height - ELEVATOR_MARGIN);
        //
//        CGRect frame = self.gridTiles.frame;
//        frame.origin.y += VIEW_HEIGHT/2 - ELEVATOR_MARGIN;
//        [self.gridTiles setFrame:frame];
//        
//        for(UIView *view in self.cameraAccessories){
//            [view setAlpha:0.0];
//        }
        
        //  self.groupsViewController.view.transform = CGAffineTransformIdentity;
        groupsController.view.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        gridController.elevatorOpen = YES;
    }];

}
@end
