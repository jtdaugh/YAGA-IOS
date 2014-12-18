//
//  MainViewController.h
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TileCell.h"
#import "YAUser.h"
#import "AVCamPreviewView.h"
#import "FBShimmeringView.h"

@interface GridViewController : UIViewController <AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIApplicationDelegate, CNetworkingDelegate>

@property (strong, nonatomic) AVCamPreviewView *cameraView;
@property (assign, nonatomic) BOOL elevatorOpen;
@end
