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
#import "MediaPlayer/MediaPlayer.h"

@interface MainViewController : UIViewController<UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, AVCaptureFileOutputRecordingDelegate>
@property (strong,nonatomic) UIView *cameraView;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (strong, nonatomic) UICollectionView *grid;
@property (strong, nonatomic) NSMutableArray *gridData;
@property (strong, nonatomic) Firebase *firebase;

@property (strong, nonatomic) NSMutableArray *moviePlayers;
@property (strong, nonatomic) MPMoviePlayerController *moviePlayer1;
@property (strong, nonatomic) MPMoviePlayerController *moviePlayer2;
@property (strong, nonatomic) MPMoviePlayerController *moviePlayer3;
@property (strong, nonatomic) MPMoviePlayerController *moviePlayer4;
@property (strong, nonatomic) MPMoviePlayerController *moviePlayer5;
@property (strong, nonatomic) MPMoviePlayerController *moviePlayer6;

@end
