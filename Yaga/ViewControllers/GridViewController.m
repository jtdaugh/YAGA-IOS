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
#import "YAGroupAddMembersViewController.h"

#import "YAUtils.h"
#import "YAHideEmbeddedGroupsSegue.h"

//Swift headers
//#import "Yaga-Swift.h"

@implementation GridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [Crashlytics setUserIdentifier:(NSString *) [[YAUser currentUser] objectForKey:nUsername]];
    
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
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
    _collectionViewController.view.frame = CGRectMake(0, CAMERA_MARGIN, VIEW_WIDTH, VIEW_HEIGHT - CAMERA_MARGIN);
//    [_collectionViewController.view.layer setMasksToBounds:NO];
    [_collectionViewController.collectionView.layer setMasksToBounds:NO];

    [self addChildViewController:_collectionViewController];
    [self.view addSubview:_collectionViewController.view];
    
    _cameraViewController = [YACameraViewController new];
    _cameraViewController.delegate = self;
    
    _cameraViewController.view.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2 + recordButtonWidth/2);
    [self addChildViewController:_cameraViewController];
    [self.view addSubview:_cameraViewController.view];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self.navigationController setNavigationBarHidden:YES];
}

#pragma mark - YACollectionViewControllerDelegate
- (void)showCamera:(BOOL)show showPart:(BOOL)showPart animated:(BOOL)animated completion:(cameraCompletion)completion {
    
    void (^showHideBlock)(void) = ^void(void) {
        if(show) {
            self.cameraViewController.view.frame = CGRectMake(0, 0, self.cameraViewController.view.frame.size.width, self.cameraViewController.view.frame.size.height);
        }
        else {
            self.cameraViewController.view.frame = CGRectMake(0, -self.cameraViewController.view.frame.size.height + (showPart ? ELEVATOR_MARGIN : 0) + recordButtonWidth / 2, self.cameraViewController.view.frame.size.width, self.cameraViewController.view.frame.size.height);
        }
        CGFloat origin = self.cameraViewController.view.frame.origin.y + self.cameraViewController.view.frame.size.height - recordButtonWidth / 2;
        CGFloat separator = show ? 2 : 0;
        self.collectionViewController.view.frame = CGRectMake(0, origin + separator, self.collectionViewController.view.frame.size.width, VIEW_HEIGHT - origin - separator);
        
        [self.cameraViewController showCameraAccessories:(show && !showPart)];
    };
    
    if(animated) {
        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
            showHideBlock();
            
        } completion:^(BOOL finished) {
            if(finished && completion)
                completion();
        }];
    }
    else {
        showHideBlock();
    }
}

- (void)enableRecording:(BOOL)enable {
    [self.cameraViewController enableRecording:enable];
}

- (void)collectionViewDidScroll {
    CGRect cameraFrame = self.cameraViewController.view.frame;
    CGRect gridFrame = self.collectionViewController.view.frame;
    
    CGFloat scrollOffset = self.collectionViewController.collectionView.contentOffset.y;
    CGFloat offset = self.collectionViewController.collectionView.contentInset.top + scrollOffset;
    
    if(offset > VIEW_HEIGHT/2 - CAMERA_MARGIN) {
        offset = VIEW_HEIGHT/2 - CAMERA_MARGIN;
    }
    
    cameraFrame.origin.y = -offset;

    self.cameraViewController.view.frame = cameraFrame;
    self.collectionViewController.view.frame = gridFrame;
}

#pragma mark -
- (void)toggleGroups {
    if(self.elevatorOpen){
        [self closeGroups];
    } else {
        [self openGroups];
    }
}

- (void)openGroups {
    [self performSegueWithIdentifier:@"ShowEmbeddedUserGroups" sender:self];
}

- (void)closeGroups {
    [self.groupsViewController performSegueWithIdentifier:@"HideEmbeddedUserGroups" sender:self];
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
    return segue;
}



@end
