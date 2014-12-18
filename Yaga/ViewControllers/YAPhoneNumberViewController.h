//
//  SplashViewController.h
//  Pic6
//
//  Created by Raj Vir on 9/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YAPhoneNumberViewController : UIViewController<UITextFieldDelegate>
@property (strong, nonatomic) UIImageView *logo;
@property (strong, nonatomic) UILabel *cta;
@property (strong, nonatomic) UITextField *number;
@property (strong, nonatomic) UIButton *country;
@property (strong, nonatomic) UIButton *next;
@end
