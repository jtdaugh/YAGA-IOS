//
//  MainViewController.h
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAUser.h"

#import "YACollectionViewController.h"
#import "YACameraViewController.h"
#import "MyGroupsViewController.h"

//@protocol YACollectionViewControllerDelegate;
//@protocol YACameraViewControllerDe;

@interface GridViewController : UIViewController <UIApplicationDelegate, YACameraViewControllerDelegate, YACollectionViewControllerDelegate, MyGroupsViewControllerDelegate>

@property (assign, nonatomic) BOOL elevatorOpen;
@property (nonatomic, readonly) YACameraViewController *cameraViewController;
@property (nonatomic, readonly) YACollectionViewController *collectionViewController;

@end
