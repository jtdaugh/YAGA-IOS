//
//  OverlayViewController.h
//  Pic6
//
//  Created by Raj Vir on 7/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TileCell.h"
#import "GridViewController.h"
#import <Firebase/Firebase.h>

@interface OverlayViewController : UIViewController
@property (strong, nonatomic) TileCell *tile;
@property (strong, nonatomic) GridViewController *previousViewController;
@property (strong, nonatomic) UILabel *userLabel;
@property (strong, nonatomic) UITextView *captionField;

@property (strong, nonatomic) Firebase *firebase;

@end