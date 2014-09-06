//
//  OverlayViewController.h
//  Pic6
//
//  Created by Raj Vir on 7/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TileCell.h"
#import "CameraViewController.h"
#import <Firebase/Firebase.h>

@interface OverlayViewController : UIViewController <UIActionSheetDelegate>
@property (strong, nonatomic) TileCell *tile;
@property (strong, nonatomic) UIView *bg;
@property (strong, nonatomic) CameraViewController *previousViewController;
@property (strong, nonatomic) UILabel *userLabel;
@property (strong, nonatomic) UITextView *captionField;
@property (strong, nonatomic) UIButton *likeButton;
@property (strong, nonatomic) UIButton *settingsButton;

@property (strong, nonatomic) Firebase *firebase;

@end