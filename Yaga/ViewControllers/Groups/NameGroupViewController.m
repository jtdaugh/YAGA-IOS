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

    CGFloat width = VIEW_WIDTH * .8;
    
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
    [self.nextButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
//    [self.nextButton.titleLabel setTextColor: [UIColor blackColor]];
//    self.nextButton.titleLabel.textColor = [UIColor blackColor];
    [self.nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.nextButton setAlpha:0.0];
    self.nextButton.layer.cornerRadius = 8.0;
    self.nextButton.layer.masksToBounds = YES;
    [self.nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

    [self.groupNameTextField becomeFirstResponder];
}

- (CGFloat)getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editingChanged {
    if([self.groupNameTextField.text length] > 1){
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
//    YAGroupAddMembersViewController *vc = [YAGroupAddMembersViewController new];
//    vc.inCreateGroupFlow = YES;
//    vc.initialVideo = self.initialVideo;
//    vc.groupName = self.groupNameTextField.text;
//    [self.navigationController pushViewController:vc animated:YES];
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
