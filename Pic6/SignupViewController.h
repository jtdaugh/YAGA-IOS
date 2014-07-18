//
//  SignupViewController.h
//  Pic6
//
//  Created by Raj Vir on 7/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupViewController : UIViewController <UITextFieldDelegate>

@property (strong,nonatomic) UITextField *nameField;
@property (strong,nonatomic) UITextField *phoneField;
@property (strong,nonatomic) UITextField *passwordField;

@property (strong, nonatomic) UIButton *submitButton;

@end
