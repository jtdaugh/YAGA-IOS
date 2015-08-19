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

@interface NameGroupViewController ()
@property (strong, nonatomic) UITextField *groupNameTextField;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) YAGroup *group;
@property (strong, nonatomic) UISwitch *publicSwitch;
@end

@implementation NameGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.navigationItem.title = @"Name Group";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeButtonPressed:)];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.1;
    
    CGFloat formWidth = VIEW_WIDTH *.8;
    self.groupNameTextField = [[UITextField alloc] initWithFrame:CGRectMake((VIEW_WIDTH-formWidth)/2, origin, formWidth, VIEW_HEIGHT*.08)];
    self.groupNameTextField.delegate = self;
    [self.groupNameTextField setBackgroundColor:[UIColor clearColor]];
    [self.groupNameTextField setKeyboardType:UIKeyboardTypeDefault];
    [self.groupNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.groupNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.groupNameTextField setTextAlignment:NSTextAlignmentCenter];
    [self.groupNameTextField setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.groupNameTextField setTextColor:PRIMARY_COLOR];
    [self.groupNameTextField becomeFirstResponder];
    [self.groupNameTextField setTintColor:PRIMARY_COLOR];
    [self.groupNameTextField setReturnKeyType:UIReturnKeyDone];
    [self.groupNameTextField addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.groupNameTextField];
    
    origin = [self getNewOrigin:self.groupNameTextField];
    
    UILabel *publicGroupLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH-formWidth)/2, origin, formWidth, VIEW_HEIGHT*.08)];
    publicGroupLabel.textAlignment = NSTextAlignmentCenter;
    publicGroupLabel.font = [UIFont fontWithName:BIG_FONT size:30];
    publicGroupLabel.text = @"Public group?";
    publicGroupLabel.textColor = PRIMARY_COLOR;
    [self.view addSubview:publicGroupLabel];
    
    origin = [self getNewOrigin:publicGroupLabel];
    
    self.publicSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - 30, origin - 20, 30, 30)];
     self.publicSwitch.thumbTintColor = PRIMARY_COLOR;
    [self.view addSubview: self.publicSwitch];
    
    origin = [self getNewOrigin: self.publicSwitch];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.nextButton setBackgroundColor:[UIColor clearColor]];
    [self.nextButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
//    [self.nextButton.titleLabel setTextColor: [UIColor blackColor]];
//    self.nextButton.titleLabel.textColor = [UIColor blackColor];
    [self.nextButton setTitleColor:SECONDARY_COLOR forState:UIControlStateNormal];
    [self.nextButton setAlpha:0.0];
    self.nextButton.layer.cornerRadius = VIEW_HEIGHT*.1/2.0f;
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.layer.borderWidth = 4.0f;
    self.nextButton.layer.borderColor = SECONDARY_COLOR.CGColor;
    [self.nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
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
            [self.nextButton setAlpha:1.0];
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self.nextButton setAlpha:0.0];
        }];
        
    }
}

- (void)nextScreen {
    YAGroupAddMembersViewController *vc = [YAGroupAddMembersViewController new];
    vc.inCreateGroupFlow = YES;
    vc.publicGroup = self.publicSwitch.isOn;
//    vc.initialVideo = self.initialVideo;
    vc.groupName = self.groupNameTextField.text;
    [self.navigationController pushViewController:vc animated:YES];
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
