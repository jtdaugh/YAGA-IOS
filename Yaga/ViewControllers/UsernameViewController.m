//
//  UsernameViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/2/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "UsernameViewController.h"
#import "YAUser.h"
//#import "Yaga-Swift.h"
#import "MyGroupsViewController.h"
#import "YAAuthManager.h"

@interface UsernameViewController ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UITextField *usernameTextField;
@end

@implementation UsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"";
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    NSLog(@" view width: %f", VIEW_WIDTH);
    
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
    [self.nextButton setBackgroundColor:PRIMARY_COLOR];
    [self.nextButton setTitle:NSLocalizedString(@"Finish", @"") forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.nextButton setAlpha:0.0];
    [self.nextButton addTarget:self action:@selector(nextButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.nextButton setTitle:@"" forState:UIControlStateDisabled];
    [self.view addSubview:self.nextButton];
    
    //Init activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.nextButton.center;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
    
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
    //Auth manager testing
//    [self.activityIndicator startAnimating];
//    self.nextButton.enabled = NO;
//    
    __weak typeof(self) weakSelf = self;
//    [[YAAuthManager sharedManager] sendTokenRequestWithCompletion:^(bool response, NSString *error) {
        [[YAUser currentUser] saveUserData:weakSelf.usernameTextField.text forKey:nUsername];
        [[YAUser currentUser] saveObject:weakSelf.usernameTextField.text forKey:nUsername];
//
        if([[YAGroup allObjects] count] > 0){
            [weakSelf performSegueWithIdentifier:@"MyGroups" sender:weakSelf];
        } else {
            [weakSelf performSegueWithIdentifier:@"NoGroups" sender:weakSelf];
        }
//        
//        [weakSelf.activityIndicator stopAnimating];
//    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[MyGroupsViewController class]]) {
        MyGroupsViewController *groupsVC = ((MyGroupsViewController*)segue.destinationViewController);
        groupsVC.titleText = @"Looks like you're already a part of a group. Pick which one you'd like to go to now.";
        groupsVC.backgroundColor = [UIColor blackColor];
        groupsVC.showEditButton = NO;
        groupsVC.showCreateGroupButton = NO;
    }
}

@end
