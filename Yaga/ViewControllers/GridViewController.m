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
    
    [self setupView];
    
    
}

- (void)switchGroupsTapped:(id)sender {
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
    [self addChildViewController:_collectionViewController];
    [self.view addSubview:_collectionViewController.view];
    
//    _cameraViewController.view.backgroundColor = [UIColor blueColor];
//    
//    _cameraViewController = [YACameraViewController new];
//    _cameraViewController.toggleGroupDelegate = self;
//    _cameraViewController.toggleGroupSeletor = @selector(switchGroupsTapped:);
//    
//    [self addChildViewController:_cameraViewController];
//    [self.view addSubview:_cameraViewController.view];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [Crashlytics setUserIdentifier:(NSString *) [[YAUser currentUser] objectForKey:nUsername]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    
    //    [self initFirebase];
    // look at afterCameraInit to see what happens after the camera gets initialized. eg initFirebase.
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)initCameraView {
    
    //  self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    
}


- (void)openGroups {
    [self performSegueWithIdentifier:@"ShowEmbeddedUserGroups" sender:self];
}

- (void)closeGroups {
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

- (void)willResignActive {
    //    [self removeAudioInput];
    // remove microphone
    
}

- (void)didBecomeActive {
    //    [self addAudioInput];
    // add microphone
}

- (void)didEnterBackground {
    //    NSLog(@"did enter background");
    //    [self.view setAlpha:0.0];
    
    if(self.cameraViewController.flash && [[self.cameraViewController.videoInput device] position] == AVCaptureDevicePositionFront){
        [self.cameraViewController switchFlashMode:nil];
    }
    [self.cameraViewController closeCamera];
}

- (void)willEnterForeground {
    [self.cameraViewController initCamera:^{
        [self.collectionViewController.collectionView reloadData];
    }];
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
