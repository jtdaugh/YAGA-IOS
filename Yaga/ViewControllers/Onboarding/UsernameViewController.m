//
//  UsernameViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/2/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "UsernameViewController.h"
#import "YAUser.h"
#import "YAGroupsViewController.h"
#import "YAServer.h"
#import "YAUtils.h"
#import "NSDictionary+ResponseObject.h"

@interface UsernameViewController ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UITextField *usernameTextField;
@end

@implementation UsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"";
    [self.view setBackgroundColor:PRIMARY_COLOR];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.05;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.08)];
    [titleLabel setText:@"Pick a username"];
    [titleLabel setNumberOfLines:1];
    [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:titleLabel];
    
    origin = [self getNewOrigin:titleLabel];
    
    CGFloat formWidth = VIEW_WIDTH *.8;
    self.usernameTextField = [[UITextField alloc] initWithFrame:CGRectMake((VIEW_WIDTH-formWidth)/2, origin, formWidth, VIEW_HEIGHT*.08)];
    [self.usernameTextField setBackgroundColor:[UIColor clearColor]];
    [self.usernameTextField setKeyboardType:UIKeyboardTypeAlphabet];
    [self.usernameTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.usernameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.usernameTextField setTextAlignment:NSTextAlignmentCenter];
    [self.usernameTextField setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.usernameTextField setTextColor:[UIColor whiteColor]];
    [self.usernameTextField becomeFirstResponder];
    [self.usernameTextField setTintColor:[UIColor whiteColor]];
    [self.usernameTextField setReturnKeyType:UIReturnKeyDone];
    [self.usernameTextField addTarget:self action:@selector(editingChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.usernameTextField];
    
    origin = [self getNewOrigin:self.usernameTextField];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.nextButton setBackgroundColor:[UIColor whiteColor]];
    [self.nextButton setTitle:NSLocalizedString(@"Finish", @"") forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.nextButton setAlpha:0.0];
    self.nextButton.layer.cornerRadius = 8.0;
    self.nextButton.layer.masksToBounds = YES;
    [self.nextButton addTarget:self action:@selector(nextButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.nextButton setTitle:@"" forState:UIControlStateDisabled];
    [self.view addSubview:self.nextButton];
    
    //Init activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.nextButton.center;
    self.activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator.color = PRIMARY_COLOR;
    [self.view addSubview:self.activityIndicator];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (CGFloat) getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)editingChanged:(UITextField*)sender {
    if([sender.text length] > 1){
        [UIView animateWithDuration:0.3 animations:^{
            [self.nextButton setAlpha:1.0];
        }];
        
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self.nextButton setAlpha:0.0];
        }];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)nextButtonTapped:(id)sender {
    
    if([self.usernameTextField.text rangeOfString:@" "].location != NSNotFound) {
        [YAUtils showNotification:NSLocalizedString(@"Spaces are not allowed in username", @"") type:YANotificationTypeError];
        return;
    }
    
    //Auth manager testing
    [self.activityIndicator startAnimating];
    self.nextButton.enabled = NO;
    //
    __weak typeof(self) weakSelf = self;
    [[YAServer sharedServer] registerUsername:self.usernameTextField.text
                                             withCompletion:^(id response, NSError *error) {
                                                 if(error) {
                                                     [weakSelf.activityIndicator stopAnimating];
                                                     self.nextButton.enabled = YES;
                                                     NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:response withError:nil];
                                                     if(dict && dict[nName]) {
                                                         NSString *serverError = [dict[nName] componentsJoinedByString:@"\n"];
                                                         [YAUtils showNotification:serverError type:YANotificationTypeError];
                                                     }
                                                     else
                                                         [YAUtils showNotification:error.localizedDescription type:YANotificationTypeError];
                                                 }
                                                 else {
                                                     [[YAUser currentUser] saveObject:weakSelf.usernameTextField.text forKey:nUsername];
                                                     [[Mixpanel sharedInstance].people set:@{@"$name":[YAUser currentUser].username}];

                                                     [YAGroup updateGroupsFromServerWithCompletion:^(NSError *error) {
                                                         
                                                         if(!error) {
                                                             // TODO: Adjust mixpanel for humanity
                                                             if([YAGroup allObjects].count) {
                                                                 [[Mixpanel sharedInstance] track:@"Onboarding user already a part of some groups"];
                                                             }
                                                             else {
                                                                 [[Mixpanel sharedInstance] track:@"Onboarding user doesn't have any groups"];
                                                             }
                                                             [self performSegueWithIdentifier:@"MyGroupsFromUsername" sender:self];
                                                         }
                                                         else {
                                                             [weakSelf.activityIndicator stopAnimating];
                                                             self.nextButton.enabled = YES;
                                                             
                                                             [YAUtils showNotification:error.localizedDescription type:YANotificationTypeError];
                                                         }
                                                     }];
                                                 }
                                             }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[YAGroupsViewController class]]) {
    }
}

@end
