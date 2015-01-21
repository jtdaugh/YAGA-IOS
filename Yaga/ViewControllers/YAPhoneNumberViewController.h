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
@property (strong, nonatomic) UILabel *enterPhoneLabel;
@property (strong, nonatomic) UITextField *phoneTextField;
@property (strong, nonatomic) IBOutlet UIButton *countryButton;
@property (strong, nonatomic) UIButton *nextButton;
@end
