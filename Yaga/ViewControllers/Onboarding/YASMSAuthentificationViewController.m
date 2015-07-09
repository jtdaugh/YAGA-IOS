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
    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
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
    [self.nextButton setBackgroundColor:[UIColor whiteColor]];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.nextButton setTitle:@"" forState:UIControlStateDisabled];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.nextButton setAlpha:0.0];
    self.nextButton.layer.cornerRadius = 8.0;
    self.nextButton.layer.masksToBounds = YES;
    [self.nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    
    //Init activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.nextButton.center;
    self.activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator.color = PRIMARY_COLOR;
    [self.view addSubview:self.activityIndicator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [self layoutControls:VIEW_HEIGHT];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
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
    
    CGFloat heightForButton = availableHeight - self.codeTextField.frame.origin.y - self.codeTextField.frame.size.height;
    CGFloat buttonOrigin = self.codeTextField.frame.origin.y + self.codeTextField.frame.size.height + heightForButton/2 - VIEW_HEIGHT*.1/2;
    
    self.nextButton.frame = CGRectMake((VIEW_WIDTH-buttonWidth)/2, buttonOrigin, buttonWidth, VIEW_HEIGHT*.1);
    self.activityIndicator.center = self.nextButton.center;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    CGFloat availableHeight = VIEW_HEIGHT - keyboardFrame.size.height - self.navigationController.navigationBar.frame.size.height;
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
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showNotification:NSLocalizedString(@"No internet connection, try later.", @"") type:YANotificationTypeError];
        return;
    }

    [self.activityIndicator startAnimating];
    self.nextButton.enabled = NO;
    
    [[YAServer sharedServer] requestAuthTokenWithAuthCode:self.codeTextField.text withCompletion:^(id response, NSError *error) {
        if (!error) {
            
            [[Mixpanel sharedInstance] track:@"Verification code entered correctly"];
            [[Mixpanel sharedInstance] identify:[YAUser currentUser].phoneNumber];
            [[Mixpanel sharedInstance].people set:@{@"$phone":[YAUser currentUser].phoneNumber}];

            //register device token
            if([YAUser currentUser].deviceToken.length) {
                [[YAServer sharedServer] registerDeviceTokenWithCompletion:^(id response, NSError *error) {
                    if(error) {
                        DLog(@"YASMSAuthentificationViewControlller error: %@", [NSString stringWithFormat:@"Can't register device token. %@", error.localizedDescription]);
                    }
                }];
            }
            
            [[YAServer sharedServer] getInfoForCurrentUserWithCompletion:^(id response, NSError *error) {
                //old user
                if (!error) {
                    if(response) {
                        NSString *username = (NSString*)response;
                        [[YAUser currentUser] saveObject:username forKey:nUsername];
                        [[Mixpanel sharedInstance].people set:@{@"$name":[YAUser currentUser].username}];

                        //Get all groups for this user
                        [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
                            if(!error) {
                                [self performSegueWithIdentifier:@"ShowGroupsAfterAuthentication" sender:self];
                            }
                            else {
                                [self.activityIndicator stopAnimating];
                                self.nextButton.enabled = YES;
                                
                                [YAUtils showNotification:NSLocalizedString(@"Can't load user groups", @"") type:YANotificationTypeError];
                            }
                        }];
                        
                        [[YAServer sharedServer] searchGroupsWithCompletion:^(id response, NSError *error) {
                            if(!error) {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                    NSArray *readableArray = [YAUtils readableGroupsArrayFromResponse:response];
                                    [[NSUserDefaults standardUserDefaults] setObject:readableArray forKey:kFindGroupsCachedResponse];
                                });
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
                    
                    [YAUtils showNotification:NSLocalizedString(@"Can't get user info", @"") type:YANotificationTypeError];
                }
                
            }];
        }
        else {
            [self.activityIndicator stopAnimating];
            self.nextButton.enabled = YES;
            
            [YAUtils showNotification:NSLocalizedString(@"Incorrect confirmation code entered, try again", @"") type:YANotificationTypeError];
            [[Mixpanel sharedInstance] track:@"Verification code entered incorrectly"];
        }
    }];
}

@end
