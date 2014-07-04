//
//  OverlayViewController.h
//  Pic6
//
//  Created by Raj Vir on 7/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TileCell.h"
#import "MainViewController.h"

@interface OverlayViewController : UIViewController
@property (strong, nonatomic) UIView *bg;
@property (strong, nonatomic) TileCell *tile;
@property (strong, nonatomic) MainViewController *previousViewController;
@property (strong, nonatomic) UILabel *userLabel;
@property CGRect previousFrame;
@property CGRect adjustedPreviousFrame;
@end