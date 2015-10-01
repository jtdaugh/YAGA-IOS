//
//  NameGroupViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "NameGroupViewController.h"
#import "YAUser.h"
#import "YAContact.h"
#import "NSString+Hash.h"
#import <Realm/Realm.h>
#import "YAUtils.h"
#import "YAGroupAddMembersViewController.h"
#import "YaPostToGroupsViewController.h"
#import "YAGridViewController.h"

@interface NameGroupViewController ()
@property (strong, nonatomic) UITextField *groupNameTextField;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) YAGroup *group;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;

@end

@implementation NameGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:PRIMARY_COLOR];

    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 25, 34, 34)];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [backButton setImage:[[UIImage imageNamed:@"Back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    backButton.tintColor = [UIColor whiteColor];
    [backButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];

    CGFloat width = VIEW_WIDTH * .9;
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.1;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.08)];
    [titleLabel setText:@"Name this group"];
    [titleLabel setNumberOfLines:1];
    [titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:titleLabel];
    
    origin = [self getNewOrigin:titleLabel];
    
    CGFloat formWidth = VIEW_WIDTH *.8;
    self.groupNameTextField = [[UITextField alloc] initWithFrame:CGRectMake((VIEW_WIDTH-formWidth)/2, origin, formWidth, VIEW_HEIGHT*.08)];
    self.groupNameTextField.delegate = self;
    [self.groupNameTextField setBackgroundColor:[UIColor clearColor]];
    [self.groupNameTextField setKeyboardType:UIKeyboardTypeDefault];
    [self.groupNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.groupNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.groupNameTextField setTextAlignment:NSTextAlignmentCenter];
    [self.groupNameTextField setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.groupNameTextField setTextColor:[UIColor whiteColor]];
    [self.groupNameTextField becomeFirstResponder];
    [self.groupNameTextField setTintColor:[UIColor whiteColor]];
    [self.groupNameTextField setReturnKeyType:UIReturnKeyDone];
    [self.groupNameTextField addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.groupNameTextField];
    
    origin = [self getNewOrigin:self.groupNameTextField];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.nextButton setBackgroundColor:[UIColor whiteColor]];
    [self.nextButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
//    [self.nextButton.titleLabel setTextColor: [UIColor blackColor]];
//    self.nextButton.titleLabel.textColor = [UIColor blackColor];
    [self.nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.nextButton setAlpha:0.0];
    self.nextButton.layer.cornerRadius = 8.0;
    self.nextButton.layer.masksToBounds = YES;
    [self.nextButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    [self.groupNameTextField becomeFirstResponder];
}

- (CGFloat)getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editingChanged {
    if([self.groupNameTextField.text length] > 0){
        [UIView animateWithDuration:0.3 animations:^{
            [self.nextButton setAlpha:1.0];
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self.nextButton setAlpha:0.0];
        }];
        
    }
}

- (void)dismissWithNewGroup:(YAGroup *)group {
    UIViewController *presentingVC = self.presentingViewController;
    if ([presentingVC isKindOfClass:[UINavigationController class]]) {
        presentingVC = ((UINavigationController *) presentingVC).topViewController;
    }
    if ([presentingVC isKindOfClass:[YAGridViewController class]]) {
        [presentingVC dismissViewControllerAnimated:YES completion:^{
            [(YAGridViewController *)presentingVC createChatFinishedWithGroup:group wasPreexisting:NO];
        }];
        return;
    } else if ([presentingVC isKindOfClass:[YAPostToGroupsViewController class]]) {
        // Dismiss and go straight to new group
        [presentingVC dismissViewControllerAnimated:YES completion:^{
            [(YAPostToGroupsViewController *)presentingVC createChatFinishedWithGroup:group wasPreexisting:NO];
        }];
        return;
    }
}

- (void)showActivity:(BOOL)show {
    if(show) {
        self.nextButton.titleLabel.hidden = YES;
        self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.nextButton.frame.size.width/2 - 15, self.nextButton.frame.size.height/2 - 15, 30, 30)];
        [self.nextButton addSubview:self.activityView];
    }
    else {
        [self.activityView removeFromSuperview];
        self.activityView = nil;
        self.nextButton.titleLabel.hidden = NO;
    }
}

- (void)donePressed {
    __weak typeof(self) weakSelf = self;
    [YAGroup groupWithName:self.groupNameTextField.text withCompletion:^(NSError *error, id result) {
        if(error) {
            [weakSelf showActivity:NO];
        } else {
            YAGroup *newGroup = result;
            [YAUser currentUser].currentGroup = newGroup;
            __weak typeof(newGroup) weakGroup = newGroup;
            [newGroup addMembers:self.selectedContacts withCompletion:^(NSError *error) {
                [weakSelf.groupNameTextField resignFirstResponder];
                [weakSelf showActivity:NO];
                if(!error) {
                    [[Mixpanel sharedInstance] track:@"Group created" properties:@{@"friends added":[NSNumber numberWithInteger:weakSelf.selectedContacts.count]}];
                    [weakSelf dismissWithNewGroup:weakGroup];
                }
            }];
            
        }
    }];

    
}


#define MAXLENGTH 32

- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    
    return newLength <= MAXLENGTH || returnKey;
}

@end
