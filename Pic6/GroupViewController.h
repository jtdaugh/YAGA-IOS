//
//  MainViewController.h
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>
#import "TileCell.h"
#import "CNetworking.h"
#import "CameraViewController.h"

@interface GroupViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIApplicationDelegate, CNetworkingDelegate>

@property (strong, nonatomic) CameraViewController *cameraViewController;

@property (strong, nonatomic) NSNumber *setup;
@property (strong, nonatomic) NSNumber *appeared;
@property (strong, nonatomic) NSNumber *onboarding;

@property (strong, nonatomic) GroupInfo *groupInfo;

@property (strong, nonatomic) UIView *gridView;
@property (strong, nonatomic) UICollectionView *gridTiles;
@property (strong, nonatomic) NSMutableArray *gridData;
@property (strong, nonatomic) NSNumber *scrolling;
@property (strong, nonatomic) UIRefreshControl *pull;
@property (strong, nonatomic) UIActivityIndicatorView *loader;

@property (strong, nonatomic) UIView *banner;

@property (strong, nonatomic) UIView *overlay;

@property (strong, nonatomic) Firebase *firebase;

@property (strong, nonatomic) TileCell *loaderTile;

- (void)collapse:(TileCell *)tile speed:(CGFloat)speed;

- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL;

- (void)pagingStarted;
- (void)pagingEnded;
- (void)scrollingEnded;

- (void)conserveTiles;

- (void)pauseVideos;
- (void)unpauseVideos;

@end
