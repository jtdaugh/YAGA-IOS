//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GridViewController.h"

#import "YagaNavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import "YAPhoneNumberViewController.h"
#import "AddMembersViewController.h"

#import "YAUtils.h"
#import "YAHideEmbeddedGroupsSegue.h"

//Swift headers
//#import "Yaga-Swift.h"

@interface GridViewController ()
@end

@implementation GridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [Crashlytics setUserIdentifier:(NSString *) [[YAUser currentUser] objectForKey:nUsername]];
    
    [self setupView];
}

- (void)toggleGroups {
    if(!self.collectionViewController.scrolling){
        if(self.collectionViewController.collectionView.contentOffset.y <= 0){
            if(self.elevatorOpen){
                [self closeGroups];
            } else {
                [self openGroups];
            }
        }
    }
}

- (void)showCamera:(BOOL)show showPart:(BOOL)showPart completion:(cameraCompletion)block {
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        if(show) {
            self.cameraViewController.view.frame = CGRectMake(0, 0, self.cameraViewController.view.frame.size.width, self.cameraViewController.view.frame.size.height);
        }
        else {
            self.cameraViewController.view.frame = CGRectMake(0, -self.cameraViewController.view.frame.size.height + (showPart ? ELEVATOR_MARGIN : 0), self.cameraViewController.view.frame.size.width, self.cameraViewController.view.frame.size.height);
        }
        CGFloat origin = self.cameraViewController.view.frame.origin.y + self.cameraViewController.view.frame.size.height;
        self.collectionViewController.view.frame = CGRectMake(0, origin + 2, self.collectionViewController.view.frame.size.width, VIEW_HEIGHT - origin - 2);
        
        self.cameraViewController.recordButton.alpha = (show && !showPart) == YES ? 1 : 0;
        self.cameraViewController.switchGroupsButton.alpha = (show && !showPart) == YES ? 1 : 0;
        
    } completion:^(BOOL finished) {
        //make sure record button is on top
        if (show && !showPart) {
            [self.view bringSubviewToFront:self.cameraViewController.view];
        }
        
        if(finished)
            block();
    }];
     
}

- (void)logout {
    [[YAUser currentUser] logout];
    
    YagaNavigationController *vc = [[YagaNavigationController alloc] init];
    [vc setViewControllers:@[[[YAPhoneNumberViewController alloc] init]]];
    
    [self closeGroups];
    
    [self presentViewController:vc animated:NO completion:^{
    }];
    
}

- (void)setupView {
    _collectionViewController = [YACollectionViewController new];
    _collectionViewController.delegate = self;
    _collectionViewController.view.frame = CGRectMake(0, VIEW_HEIGHT/2 + 2, VIEW_WIDTH, VIEW_HEIGHT/2 - 2);
    [self addChildViewController:_collectionViewController];
    [self.view addSubview:_collectionViewController.view];
    
    _cameraViewController = [YACameraViewController new];
    _cameraViewController.delegate = self;
    
     _cameraViewController.view.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2);
    [self addChildViewController:_cameraViewController];
    [self.view addSubview:_cameraViewController.view];
    

    [self.view setBackgroundColor:[UIColor blackColor]];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)openGroups {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [UIColor whiteColor];
        self.collectionViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished) {
        [self.collectionViewController.view removeFromSuperview];
    }];
    
    [self performSegueWithIdentifier:@"ShowEmbeddedUserGroups" sender:self];
}

- (void)closeGroups {
    [self.view addSubview:self.collectionViewController.view];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [UIColor blackColor];
        self.collectionViewController.view.transform = CGAffineTransformIdentity;
    }];

    [[NSNotificationCenter defaultCenter] postNotificationName:kYACloseGroupsNotification object:nil];
}

- (void) deleteUid:(NSString *)uid {
    //val TODO:
    
    //    CNetworking *currentUser = [CNetworking currentUser];
    //    [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"groups/%@/%@/%@", self.YAGroup.groupId, STREAM, uid]] removeValueWithCompletionBlock:^(NSError *error, Firebase *ref) {
    //
    //        int index = 0;
    //        int toDelete = -1;
    //        for(FDataSnapshot *snapshot in [[CNetworking currentUser] gridDataForGroupId:self.YAGroup.groupId]){
    //            if([snapshot.name isEqualToString:uid]){
    //                toDelete = index;
    //            }
    //            index++;
    //        };
    //        if(toDelete > -1){
    //            [[[CNetworking currentUser] gridDataForGroupId:self.YAGroup.groupId] removeObjectAtIndex:toDelete];
    //        }
    //        [self.gridTiles reloadData];
    //    }];
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Segues
- (UIViewController*)viewControllerForUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return fromViewController;
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    // Instantiate a new CustomUnwindSegue
    YAHideEmbeddedGroupsSegue *segue = [[YAHideEmbeddedGroupsSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    // Set the target point for the animation to the center of the button in this VC
    segue.gridViewController = self;
    return segue;
}



@end
