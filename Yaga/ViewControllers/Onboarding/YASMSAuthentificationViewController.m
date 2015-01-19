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
@property (strong, nonatomic) UILabel *enterCodeLabel;
@property (strong, nonatomic) UITextField *codeTextField;
@property (strong, nonatomic) UIButton *nextButton;
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
    
    self.enterCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.12)];
    
    [self.enterCodeLabel setText:@"Enter confirmation code"];
    [self.enterCodeLabel setNumberOfLines:2];
    [self.enterCodeLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    
    [self.enterCodeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.enterCodeLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:self.enterCodeLabel];
    
    origin = [self getNewOrigin:self.enterCodeLabel];
    
    
    CGFloat formWidth = VIEW_WIDTH *.7;
    CGFloat gutter = VIEW_WIDTH * .05;
    self.codeTextField = [[UITextField alloc] initWithFrame:CGRectMake(VIEW_WIDTH-formWidth-gutter, origin, formWidth, VIEW_HEIGHT*.08)];
    
    CGPoint center = self.codeTextField.center;
    center.x = self.view.center.x;
    self.codeTextField.center = center;
    
    [self.codeTextField setBackgroundColor:[UIColor clearColor]];
    [self.codeTextField setKeyboardType:UIKeyboardTypePhonePad];
    [self.codeTextField setTextAlignment:NSTextAlignmentCenter];
    [self.codeTextField setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.codeTextField setTextColor:[UIColor whiteColor]];
    [self.codeTextField becomeFirstResponder];
    [self.codeTextField setTintColor:[UIColor whiteColor]];
    [self.codeTextField setReturnKeyType:UIReturnKeyDone];
    [self.codeTextField addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.codeTextField];
    
    origin = [self getNewOrigin:self.codeTextField];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.nextButton setBackgroundColor:PRIMARY_COLOR];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.nextButton setTitle:@"" forState:UIControlStateDisabled];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.nextButton setAlpha:0.0];
    [self.nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    
    //Init activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.nextButton.center;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [self layoutControls:VIEW_HEIGHT];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.codeTextField becomeFirstResponder];
}


- (void)layoutControls:(CGFloat)availableHeight {
    self.logo.frame = CGRectMake(0, 0, VIEW_WIDTH, availableHeight/4);
    self.enterCodeLabel.frame = CGRectMake(0, availableHeight/4, VIEW_WIDTH, 30);
    self.codeTextField.frame = CGRectMake(0, self.enterCodeLabel.frame.origin.y + self.enterCodeLabel.frame.size.height + 20, VIEW_WIDTH, VIEW_HEIGHT*.08);
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.nextButton.frame = CGRectMake((VIEW_WIDTH-buttonWidth)/2, self.codeTextField.frame.origin.y + self.codeTextField.frame.size.height + 10, buttonWidth, VIEW_HEIGHT*.1);
    self.activityIndicator.center = self.nextButton.center;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    CGFloat availableHeight = VIEW_HEIGHT - keyboardFrame.size.height;
    [self layoutControls:availableHeight];
}

- (CGFloat) getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)editingChanged {
    if([self.codeTextField.text length] > 3){
        [UIView animateWithDuration:0.3 animations:^{
            [self.nextButton setAlpha:1.0];
        }];
        
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self.nextButton setAlpha:0.0];
        }];
    }
}

- (void)nextScreen
{
    [self.activityIndicator startAnimating];
    self.nextButton.enabled = NO;
    
    [[YAUser currentUser] setAuthCode:self.codeTextField.text];
    
    [[YAServer sharedServer] requestAuthTokenWithCompletion:^(id response, NSError *error) {
        if (!error) {
            
            //register device token
            if([YAUser currentUser].deviceToken.length) {
                [[YAServer sharedServer] registerDeviceTokenWithCompletion:^(id response, NSError *error) {
                    if(error) {
                        [YAUtils showNotification:[NSString stringWithFormat:@"Can't register device token. %@", error.localizedDescription] type:AZNotificationTypeError];
                    }
                }];
            }
            
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
                                self.nextButton.enabled = YES;
                                
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
                    self.nextButton.enabled = YES;
                    
                    [YAUtils showNotification:NSLocalizedString(@"Can't get user info", @"") type:AZNotificationTypeError];
                }
                
            }];
        }
        else {
            [self.activityIndicator stopAnimating];
            self.nextButton.enabled = YES;
            
            [YAUtils showNotification:NSLocalizedString(@"Incorrect confirmation code entered, try again", @"") type:AZNotificationTypeError];
        }
    }];
}

@end
