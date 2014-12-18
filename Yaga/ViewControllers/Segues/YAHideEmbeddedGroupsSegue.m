//
//  YAGroupSelectedSegue.m
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAHideEmbeddedGroupsSegue.h"
#import "MyGroupsViewController.h"

@implementation YAHideEmbeddedGroupsSegue

- (void)perform {
    MyGroupsViewController *groupsController = (MyGroupsViewController*)self.sourceViewController;
    
    //self.groupsViewController.view.transform = CGAffineTransformIdentity;
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        [gridController.cameraView setFrame:CGRectMake(0, 0, gridController.cameraView.frame.size.width, gridController.cameraView.frame.size.height)];
        CGRect ballFrame = groupsController.view.frame;
        ballFrame.origin.y = gridController.cameraView.frame.origin.y + gridController.cameraView.frame.size.height - ballFrame.size.height;
        [groupsController.view setFrame:ballFrame];
//        
//        CGRect frame = self.gridTiles.frame;
//        frame.origin.y = 0;
//        [gridController.gridTiles setFrame:frame];

        
//        for(UIView *view in self.cameraAccessories){
//            [view setAlpha:1.0];
//        }
        
        [groupsController.view setAlpha:0.0];
        // self.groupsViewController.view.transform = CGAffineTransformMakeScale(0.75, 0.75);
        
    } completion:^(BOOL finished) {
        gridController.elevatorOpen = NO;
        [groupsController.view removeFromSuperview];
        [groupsController removeFromParentViewController];
        
        for(UIGestureRecognizer *gr in [groupsController.view.gestureRecognizers mutableCopy])
            [groupsController.view removeGestureRecognizer:gr];
    }];

}

@end
