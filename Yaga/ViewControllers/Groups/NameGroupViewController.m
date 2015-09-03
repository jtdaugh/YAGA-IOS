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
#import "YAPostToGroupsViewController.h"

@interface NameGroupViewController ()
@property (strong, nonatomic) UITextField *groupNameTextField;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) UIButton *doneButton;
@property (strong, nonatomic) UISegmentedControl *publicControl;
@property (strong, nonatomic) UIButton *addCohostsButton;
@property (strong, nonatomic) YAGroup *group;
@end

@implementation NameGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.backgroundColor = PRIVATE_GROUP_COLOR;
    self.navigationController.navigationBar.barTintColor = PRIVATE_GROUP_COLOR;

    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.navigationItem.title = @"New Channel";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeButtonPressed:)];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.03;
    
    CGSize segSize = CGSizeMake(VIEW_WIDTH *.8, 30);
    self.publicControl = [[UISegmentedControl alloc] initWithFrame:CGRectMake((VIEW_WIDTH - segSize.width)/2, origin, segSize.width, segSize.height)];
    self.publicControl.tintColor = PRIVATE_GROUP_COLOR;
    [self.publicControl insertSegmentWithTitle:@"Private" atIndex:0 animated:NO];
    [self.publicControl insertSegmentWithTitle:@"Public" atIndex:1 animated:NO];
    self.publicControl.selectedSegmentIndex = 0;
    [self.publicControl addTarget:self action:@selector(publicSwitchChanged) forControlEvents:UIControlEventValueChanged];
    
    UIFont *font = [UIFont fontWithName:BIG_FONT size:20.0];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                           forKey:NSFontAttributeName];
    [self.publicControl setTitleTextAttributes:attributes
                                         forState:UIControlStateNormal];

    [self.view addSubview: self.publicControl];

    origin = [self getNewOrigin:self.publicControl] + 10;
    
    CGFloat formWidth = VIEW_WIDTH *.8;
    self.groupNameTextField = [[UITextField alloc] initWithFrame:CGRectMake((VIEW_WIDTH-formWidth)/2, origin, formWidth, VIEW_HEIGHT*.12)];
    self.groupNameTextField.delegate = self;
    self.groupNameTextField.placeholder = @"Channel Name";
    self.groupNameTextField.layer.cornerRadius = 5;
    self.groupNameTextField.layer.masksToBounds = YES;
    [self.groupNameTextField setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
    [self.groupNameTextField setKeyboardType:UIKeyboardTypeDefault];
    [self.groupNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.groupNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.groupNameTextField setTextAlignment:NSTextAlignmentCenter];
    [self.groupNameTextField setFont:[UIFont fontWithName:BIG_FONT size:30]];
    [self.groupNameTextField setTextColor:PRIVATE_GROUP_COLOR];
    [self.groupNameTextField becomeFirstResponder];
    [self.groupNameTextField setTintColor:PRIVATE_GROUP_COLOR];
    [self.groupNameTextField setReturnKeyType:UIReturnKeyDone];
    [self.groupNameTextField addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.groupNameTextField];
    
    origin = [self getNewOrigin:self.groupNameTextField];
    
    CGFloat halfButtonWidth = (VIEW_WIDTH * .4) - 10;
    self.addCohostsButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - 10 - halfButtonWidth, origin, halfButtonWidth, VIEW_HEIGHT*.1)];
    [self.addCohostsButton setBackgroundColor:[UIColor clearColor]];
    [self.addCohostsButton setTitle:NSLocalizedString(@"Add Hosts", @"") forState:UIControlStateNormal];
    [self.addCohostsButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    [self.addCohostsButton setTitleColor:HOSTING_GROUP_COLOR forState:UIControlStateNormal];
    [self.addCohostsButton setAlpha:0.0];
    self.addCohostsButton.layer.cornerRadius = VIEW_HEIGHT*.1/2.0f;
    self.addCohostsButton.layer.masksToBounds = YES;
    self.addCohostsButton.layer.borderWidth = 4.0f;
    self.addCohostsButton.layer.borderColor = HOSTING_GROUP_COLOR.CGColor;
    [self.addCohostsButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addCohostsButton];
    
    self.doneButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 + 10, origin, halfButtonWidth, VIEW_HEIGHT*.1)];
    [self.doneButton setBackgroundColor:HOSTING_GROUP_COLOR];
    [self.doneButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
    [self.doneButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.doneButton setAlpha:0.0];
    self.doneButton.layer.cornerRadius = VIEW_HEIGHT*.1/2.0f;
    self.doneButton.layer.masksToBounds = YES;
    [self.doneButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.8;
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.nextButton setBackgroundColor:[UIColor clearColor]];
    [self.nextButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.nextButton setTitleColor:PRIVATE_GROUP_COLOR forState:UIControlStateNormal];
    [self.nextButton setAlpha:0.0];
    self.nextButton.layer.cornerRadius = VIEW_HEIGHT*.1/2.0f;
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.layer.borderWidth = 4.0f;
    self.nextButton.layer.borderColor = PRIVATE_GROUP_COLOR.CGColor;
    [self.nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    self.nextButton.alpha = 0;
    [self.view addSubview:self.nextButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.groupNameTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
}

- (CGFloat)getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)closeButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)editingChanged {
    if([self.groupNameTextField.text length] > 0){
        [UIView animateWithDuration:0.3 animations:^{
            if (self.publicControl.selectedSegmentIndex == 1) {
                [self.doneButton setAlpha:1.0];
                [self.addCohostsButton setAlpha:1.0];
            } else {
                [self.nextButton setAlpha:1.0];
            }
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            if (self.publicControl.selectedSegmentIndex == 1) {
                [self.doneButton setAlpha:0.0];
                [self.addCohostsButton setAlpha:0.0];
            } else {
                [self.nextButton setAlpha:0.0];
            }
        }];
    }
}

- (void)publicSwitchChanged {
    CGFloat doneAlpha, addAlpha, nextAlpha;
    UIColor *color;
    if (self.publicControl.selectedSegmentIndex == 1) {
        // Public
        doneAlpha = 1;
        addAlpha = 1;
        nextAlpha = 0;
        color = HOSTING_GROUP_COLOR;
    } else {
        doneAlpha = 0;
        addAlpha = 0;
        nextAlpha = 1;
        color = PRIVATE_GROUP_COLOR;
    }
    if (![self.groupNameTextField.text length]) {
        doneAlpha = addAlpha = nextAlpha = 0;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.doneButton.alpha = doneAlpha;
        self.addCohostsButton.alpha = addAlpha;
        self.nextButton.alpha = nextAlpha;
        self.publicControl.tintColor = color;
        self.groupNameTextField.textColor = color;
        self.groupNameTextField.tintColor = color;
        self.navigationController.navigationBar.backgroundColor = color;
        self.navigationController.navigationBar.barTintColor = color;
    }];
}

- (void)nextScreen {
    [[Mixpanel sharedInstance] track:@"Next Pressed"];

    YAGroupAddMembersViewController *vc = [YAGroupAddMembersViewController new];
    vc.inCreateGroupFlow = YES;
    vc.publicGroup = (self.publicControl.selectedSegmentIndex == 1);
//    vc.initialVideo = self.initialVideo;
    vc.groupName = self.groupNameTextField.text;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)donePressed {
    DLog(@"Done pressed");
    [[Mixpanel sharedInstance] track:@"Done Creating Public Channel"];

    NSString *groupName = self.groupNameTextField.text;
    BOOL isPrivate = (self.publicControl.selectedSegmentIndex == 0);
    __weak typeof(self) weakSelf = self;
    [YAGroup groupWithName:groupName isPrivate:isPrivate withCompletion:^(NSError *error, id result) {
        if(error) {
        } else {
            weakSelf.group = result;
            [weakSelf dismiss];
        }
    }];
}

- (void)dismiss {
    UIViewController *presentingVC = self.presentingViewController;
    if ([presentingVC isKindOfClass:[UINavigationController class]]) {
        UIViewController *previousTopVC = ((UINavigationController *)presentingVC).topViewController;
        if ([previousTopVC isKindOfClass:[YAPostToGroupsViewController class]]) {
            YAGroup *group = self.group;
            [presentingVC dismissViewControllerAnimated:YES completion:^{
                [(YAPostToGroupsViewController *)previousTopVC addNewlyCreatedGroupToList:group];
            }];
            return;
        }
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
