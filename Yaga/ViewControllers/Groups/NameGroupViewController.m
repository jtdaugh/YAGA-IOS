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
@property (strong, nonatomic) YAGroup *group;
@end

@implementation NameGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    self.title = @"";
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.05;
    
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
    [self.groupNameTextField setBackgroundColor:[UIColor clearColor]];
    [self.groupNameTextField setKeyboardType:UIKeyboardTypeAlphabet];
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
    [self.nextButton setBackgroundColor:PRIMARY_COLOR];
    [self.nextButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.nextButton setAlpha:0.0];
    [self.nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [self.groupNameTextField becomeFirstResponder];
}

- (CGFloat)getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
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
    if(!self.group) {
        self.group = [YAGroup groupWithName:self.groupNameTextField.text];
        
        //set current date as updatedAt for new group so unviewed badge isn't shown
        NSMutableDictionary *groupsUpdatedAt = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT]];
        [groupsUpdatedAt setObject:[NSDate date] forKey:self.group.localId];
        [[NSUserDefaults standardUserDefaults] setObject:groupsUpdatedAt forKey:YA_GROUPS_UPDATED_AT];
    }
    
    [YAUser currentUser].currentGroup = self.group;
    
    if(!self.embeddedMode) {
        [self performSegueWithIdentifier:@"AddMembers" sender:self];
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[YAGroupAddMembersViewController class]]) {
        ((YAGroupAddMembersViewController *)segue.destinationViewController).embeddedMode = self.embeddedMode;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (IBAction)unwindToGrid:(UIStoryboardSegue *)segue {}


@end
