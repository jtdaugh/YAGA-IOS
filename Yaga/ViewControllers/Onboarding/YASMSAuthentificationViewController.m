//
//  YASMSAuthentificationViewController.m
//  Yaga
//
//  Created by Iegor on 12/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YASMSAuthentificationViewController.h"
#import "YAAuthManager.h"
#import "YAUser.h"

@interface YASMSAuthentificationViewController ()
@property (strong, nonatomic) UIImageView *logo;
@property (strong, nonatomic) UILabel *cta;
@property (strong, nonatomic) UITextField *number;
@property (strong, nonatomic) UIButton *country;
@property (strong, nonatomic) UIButton *next;
@end

@implementation YASMSAuthentificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"";
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    NSLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.025;
    self.logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, origin, VIEW_WIDTH, VIEW_HEIGHT*.1)];
    [self.logo setImage:[UIImage imageNamed:@"Logo"]];
    [self.logo setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:self.logo];
    
    origin = [self getNewOrigin:self.logo];
    
    self.cta = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.12)];

    [self.cta setText:@"Enter confirmation code"];
    [self.cta setNumberOfLines:2];
    [self.cta setFont:[UIFont fontWithName:BIG_FONT size:24]];

    [self.cta setTextAlignment:NSTextAlignmentCenter];
    [self.cta setTextColor:[UIColor whiteColor]];
    [self.view addSubview:self.cta];
    
    origin = [self getNewOrigin:self.cta];
    
    
    CGFloat formWidth = VIEW_WIDTH *.7;
    CGFloat gutter = VIEW_WIDTH * .05;
    self.number = [[UITextField alloc] initWithFrame:CGRectMake(VIEW_WIDTH-formWidth-gutter, origin, formWidth, VIEW_HEIGHT*.08)];
    
    CGPoint center = self.number.center;
    center.x = self.view.center.x;
    self.number.center = center;
    
    [self.number setBackgroundColor:[UIColor clearColor]];
    [self.number setKeyboardType:UIKeyboardTypePhonePad];
    [self.number setTextAlignment:NSTextAlignmentCenter];
    [self.number setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.number setTextColor:[UIColor whiteColor]];
    [self.number becomeFirstResponder];
    [self.number setTintColor:[UIColor whiteColor]];
    [self.number setReturnKeyType:UIReturnKeyDone];
    [self.number addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.number];
    
    origin = [self getNewOrigin:self.number];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.next = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.next setBackgroundColor:PRIMARY_COLOR];
    [self.next setTitle:@"Next" forState:UIControlStateNormal];
    [self.next.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.next setAlpha:0.0];
    [self.next addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.next];
    
}


- (CGFloat) getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)editingChanged {
    if([self.number.text length] > 3){
        [UIView animateWithDuration:0.3 animations:^{
            [self.next setAlpha:1.0];
        }];
        
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self.next setAlpha:0.0];
        }];
    }
}

- (void)nextScreen
{
    [[YAUser currentUser] setAuthCode:self.number.text];

    [[YAAuthManager sharedManager] sendTokenRequestWithCompletion:^(bool response, NSString *error) {

        if (response) {
            [[YAAuthManager sharedManager] getInfoForCurrentUserWithCompletion:^(bool response, NSString *error) {
                if (response) {
                    //This means that the user was already registered
                    //and have a name.
                    
                    //Get all groups for this user
                    [[YAAuthManager sharedManager] getGroupsWithCompletion:^(bool response, NSString *error) {
                        [self performSegueWithIdentifier:@"GridViewController" sender:self];
                    }];
                    
                } else {
                    //This means that this user was never registered
                    [self performSegueWithIdentifier:@"UserNameViewController" sender:self];
                }

            }];
        }
    }];
}

@end
