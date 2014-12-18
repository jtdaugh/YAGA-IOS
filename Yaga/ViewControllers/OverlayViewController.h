//
//  OverlayViewController.h
//  Pic6
//
//  Created by Raj Vir on 7/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GridViewController.h"

@interface OverlayViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate>
@property (strong, nonatomic) UIView *bg;
@property (strong, nonatomic) GridViewController *previousViewController;

@property (strong, nonatomic) UILabel *userLabel;
@property (strong, nonatomic) UILabel *timestampLabel;
@property (strong, nonatomic) UITextField *captionField;
@property (strong, nonatomic) UIButton *likeButton;
@property (strong, nonatomic) UIButton *captionButton;
@property (strong, nonatomic) UIButton *saveButton;
@property (strong, nonatomic) UIButton *deleteButton;

@property (strong, nonatomic) NSMutableArray *labels;



@end