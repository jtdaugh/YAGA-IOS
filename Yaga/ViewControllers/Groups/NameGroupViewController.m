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
#import "YAAuthManager.h"
#import "YAGroupCreator.h"

@interface NameGroupViewController ()
@property (strong, nonatomic) UITextField *groupNameTextField;
@property (strong, nonatomic) UIButton *nextButton;

@end

@implementation NameGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    self.title = @"";
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    NSLog(@" view width: %f", VIEW_WIDTH);
    
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
    [self.nextButton setTitle:@"Finish" forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.nextButton setAlpha:0.0];
    [self.nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
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
    [self.nextButton setTitle:@"" forState:UIControlStateNormal];
    UIActivityIndicatorView *myIndicator = [[UIActivityIndicatorView alloc]
                                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // Position the spinner
    [self.nextButton addSubview:myIndicator];
    [myIndicator setCenter:CGPointMake(self.nextButton.frame.size.width / 2, self.nextButton.frame.size.height / 2)];
    
    // Start the animation
    [myIndicator startAnimating];
    
    [[YAAuthManager sharedManager] sendGroupRenamingWithName:self.groupNameTextField.text
                                                  forGroupId:[YAGroupCreator sharedCreator].groupId
                                              withCompletion:^(bool response, NSString *error) {
                                                      
                                                  
                                                  RLMRealm *realm = [RLMRealm defaultRealm];
                                                  [realm beginWriteTransaction];
                                                  
                                                  YAGroup *group = [YAGroup new];
                                                  group.groupId = [YAGroup generateGroupId];
                                                  group.tempGroupId = [[YAGroupCreator sharedCreator].groupId integerValue];
                                                  group.name = self.groupNameTextField.text;
                                                  
                                                  for(NSDictionary *memberDic in self.membersDic){
                                                      YAContact *contact = [YAContact new];
                                                      contact.name = memberDic[nCompositeName];
                                                      contact.firstName = memberDic[nFirstname];
                                                      contact.number = memberDic[nPhone];
                                                      contact.registered = [memberDic[nRegistered] boolValue];
                                                      
                                                      [group.members addObject:contact];
                                                  }
                                                  
                                                  [realm addObject:group];
                                                  [realm commitWriteTransaction];
                                                  
                                                  
                                                  [YAUser currentUser].currentGroup = group;
                                                  
                                                  [self performSegueWithIdentifier:@"NameNewGroupAndCompleteOnboarding" sender:self];
                                                  }];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        //
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            //
        }];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation


@end
