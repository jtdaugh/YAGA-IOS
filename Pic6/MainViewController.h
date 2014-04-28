//
//  MainViewController.h
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Firebase/Firebase.h>

@interface MainViewController : UIViewController<UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
@property (strong,nonatomic) UIImageView *cameraView;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) UICollectionView *grid;
@property (strong, nonatomic) NSMutableArray *gridData;
@property (strong, nonatomic) Firebase *firebase;

@end
