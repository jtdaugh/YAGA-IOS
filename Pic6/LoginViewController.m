//
//  LoginViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "LoginViewController.h"
#import "GridViewController.h"
#import <Parse/Parse.h>
#import "NBPhoneNumberUtil.h"
#import "NSString+Hash.h"

@implementation LoginViewController

- (void)viewDidLoad {
    NSLog(@"poo");
    
    [self.view setBackgroundColor:SECONDARY_COLOR];
    [self setTitle:@"Log In"];
    
    int size = 50;
    int top_padding = 8;
    int margin = 16;
    
    self.phoneField = [self textFieldSkeleton:0];
    [self.phoneField setPlaceholder:@"Phone Number"];
    [self.phoneField setKeyboardType:UIKeyboardTypePhonePad];
    [self.view addSubview:self.phoneField];
    
    //    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    //    [keyboardDoneButtonView setTranslucent:NO];
    //    [keyboardDoneButtonView sizeToFit];
    //    [keyboardDoneButtonView setBarTintColor:TERTIARY_COLOR];
    //    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Next"
    //                                                                   style:UIBarButtonItemStyleBordered target:self
    //                                                                  action:@selector(doneClicked:)];
    //    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    //    [doneButton setTintColor:[UIColor whiteColor]];
    //    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:flex, doneButton, nil]];
    //    self.phoneField.inputAccessoryView = keyboardDoneButtonView;
    
    self.passwordField = [self textFieldSkeleton:1];
    [self.passwordField setSecureTextEntry:YES];
    [self.passwordField setPlaceholder:@"Password"];
    [self.view addSubview:self.passwordField];
    
    self.submitButton = [[UIButton alloc] initWithFrame:CGRectMake(0, top_padding + (size+margin)*2, VIEW_WIDTH, size)];
    [self.submitButton setBackgroundColor:TERTIARY_COLOR];
    [self.submitButton addTarget:self action:@selector(loginPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.submitButton setTitle:@"Log In" forState:UIControlStateNormal];
    [self.submitButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.submitButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    [self.submitButton setAlpha:0.0];
    [self.view addSubview:self.submitButton];
    // Do any additional setup after loading the view.

}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController.navigationBar setBarTintColor:SECONDARY_COLOR];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.phoneField becomeFirstResponder];
}

- (void)loginPressed {
    NSLog(@"login pressed!");
    NSLog(@"submit pressed");
    // validate form items
    // create user
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:self.phoneField.text
                                 defaultRegion:@"US" error:&aError];
    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&aError];
    NSString *phoneHash = [num sha1];
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"phoneHash" equalTo:phoneHash];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        PFUser *user = [objects firstObject];
        if(user){
            NSLog(@"found user, loggin in!!");
            [PFUser logInWithUsernameInBackground:user.username password:self.passwordField.text block:^(PFUser *user, NSError *error) {
                if(error){
                    NSString *errorString = [error userInfo][@"error"];
                    [[[UIAlertView alloc] initWithTitle: @"Error"
                                                message: errorString //, [contact readableNumber]]
                                               delegate: self
                                      cancelButtonTitle:@"ok"
                                      otherButtonTitles:nil]
                     show];
                } else {
                    NSLog(@"logged in!");
                    [self exit];
                }
            }];
        } else {
            NSLog(@"did not find");
        }
    }];
}

- (void)exit {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (UITextField *)textFieldSkeleton:(int)i {
    int size = 50;
    int top_padding = 8;
    int margin = 16;
    
    UITextField *v = [[UITextField alloc] initWithFrame:CGRectMake(0, top_padding + (size + margin)*i, VIEW_WIDTH, size)];
    [v setBackgroundColor:[UIColor whiteColor]];
    [v setFont:[UIFont fontWithName:BIG_FONT size:18]];
    
    v.delegate = self;
    
    v.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"" attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor], NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18]}];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    [v setLeftViewMode:UITextFieldViewModeAlways];
    [v setLeftView:paddingView];
    
    return v;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    bool done;
    
    if(([self.phoneField.text length] > 0) && ([self.passwordField.text length] > 0)){
        done = 1;
    } else {
        done = 0;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        if(done){
            [self.submitButton setAlpha:1.0];
        } else {
            [self.submitButton setAlpha:0.0];
        }
    }];
    
    return YES;
}


@end
