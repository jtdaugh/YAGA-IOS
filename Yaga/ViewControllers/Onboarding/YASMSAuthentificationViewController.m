//
//  YASMSAuthentificationViewController.m
//  Yaga
//
//  Created by Iegor on 12/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YASMSAuthentificationViewController.h"
#import "YAServer.h"
#import "YAUser.h"
#import "YAUtils.h"

@interface YASMSAuthentificationViewController ()
@property (strong, nonatomic) UIImageView *logo;
@property (strong, nonatomic) UILabel *cta;
@property (strong, nonatomic) UITextField *number;
@property (strong, nonatomic) UIButton *country;
@property (strong, nonatomic) UIButton *next;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
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
    [self.next setTitle:@"" forState:UIControlStateDisabled];
    [self.next.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.next setAlpha:0.0];
    [self.next addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.next];
    
    //Init activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.next.center;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
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
    [self.activityIndicator startAnimating];
    self.next.enabled = NO;
    
    [[YAUser currentUser] setAuthCode:self.number.text];
    
    [[YAServer sharedServer] requestAuthTokenWithCompletion:^(id response, NSError *error) {
        if (!error) {
            [[YAServer sharedServer] getInfoForCurrentUserWithCompletion:^(id response, NSError *error) {
                //old user
                if (!error) {
                    if(response) {
                        NSString *username = (NSString*)response;
                        [[YAUser currentUser] saveObject:username forKey:nUsername];
                        
                        //Get all groups for this user
                        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
                            if(!error) {
                                if([YAGroup allObjects].count)
                                    [self performSegueWithIdentifier:@"ShowExistingGroupsAfterAuthenitificatioon" sender:self];
                                else
                                    [self performSegueWithIdentifier:@"ShowNoGroupsForExistingUser" sender:self];
                            }
                            else {
                                [self.activityIndicator stopAnimating];
                                self.next.enabled = YES;
                                
                                [YAUtils showNotification:NSLocalizedString(@"Can't load user groups", @"") type:AZNotificationTypeError];
                            }
                        }];
                    }
                    else {
                        //new user
                        [self performSegueWithIdentifier:@"UserNameViewController" sender:self];
                    }
                } else {
                    [self.activityIndicator stopAnimating];
                    self.next.enabled = YES;
                    
                    [YAUtils showNotification:NSLocalizedString(@"Can't get user info", @"") type:AZNotificationTypeError];
                }
                
            }];
        }
        else {
            [self.activityIndicator stopAnimating];
            self.next.enabled = YES;
            
            [YAUtils showNotification:NSLocalizedString(@"Incorrect confirmation code entered, try again", @"") type:AZNotificationTypeError];
        }
    }];
}

@end
