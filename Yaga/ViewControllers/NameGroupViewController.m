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

@interface NameGroupViewController ()

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
    
    self.cta = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.08)];
    [self.cta setText:@"Name this group"];
    [self.cta setNumberOfLines:1];
    [self.cta setFont:[UIFont fontWithName:BIG_FONT size:24]];
    //    [self.cta setBackgroundColor:PRIMARY_COLOR];
    //    [self.cta sizeToFit];
    [self.cta setTextAlignment:NSTextAlignmentCenter];
    [self.cta setTextColor:[UIColor whiteColor]];
    [self.view addSubview:self.cta];
    
    origin = [self getNewOrigin:self.cta];
    
    CGFloat formWidth = VIEW_WIDTH *.8;
    self.groupTitle = [[UITextField alloc] initWithFrame:CGRectMake((VIEW_WIDTH-formWidth)/2, origin, formWidth, VIEW_HEIGHT*.08)];
    [self.groupTitle setBackgroundColor:[UIColor clearColor]];
    [self.groupTitle setKeyboardType:UIKeyboardTypeAlphabet];
    [self.groupTitle setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.groupTitle setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.groupTitle setTextAlignment:NSTextAlignmentCenter];
    [self.groupTitle setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.groupTitle setTextColor:[UIColor whiteColor]];
    [self.groupTitle becomeFirstResponder];
    [self.groupTitle setTintColor:[UIColor whiteColor]];
    [self.groupTitle setReturnKeyType:UIReturnKeyDone];
    [self.groupTitle addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    //    self.username.delegate = self;
    [self.view addSubview:self.groupTitle];
    
    origin = [self getNewOrigin:self.groupTitle];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.next = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.next setBackgroundColor:PRIMARY_COLOR];
    [self.next setTitle:@"Finish" forState:UIControlStateNormal];
    [self.next.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.next setAlpha:0.0];
    [self.next addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.next];
}

- (CGFloat)getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)editingChanged {
    
    if([self.groupTitle.text length] > 1){
        
        [UIView animateWithDuration:0.3 animations:^{
            [self.next setAlpha:1.0];
        }];
        
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self.next setAlpha:0.0];
        }];
        
    }
}

- (void)nextScreen {
    return;
    
    //not implemented
    [self.next setTitle:@"" forState:UIControlStateNormal];
    UIActivityIndicatorView *myIndicator = [[UIActivityIndicatorView alloc]
                                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // Position the spinner
    [self.next addSubview:myIndicator];
    [myIndicator setCenter:CGPointMake(self.next.frame.size.width / 2, self.next.frame.size.height / 2)];
    
    // Start the animation
    [myIndicator startAnimating];
    
    YAUser *currentUser = [YAUser currentUser];
    
    NSMutableArray *hashes = [[NSMutableArray alloc] init];
    
    for(YAContact *member in self.members){
        [hashes addObject:[member.number md5]];
    }
    
    [currentUser createCrew:self.groupTitle.text withMembers:hashes withCompletionBlock:^{
        [currentUser myCrewsWithCompletion:^{
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                NSLog(@"completed?");
            }];
        }];
        
//        if(![MFMessageComposeViewController canSendText]) {
//            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//            [warningAlert show];
//            return;
//        }
//        
//        NSMutableArray *recipients = [[NSMutableArray alloc] init];
//        for(YAContact *contact in self.members){
//            [recipients addObject:contact.number];
//        }
//        
//        //    NSArray *recipents = @[@"12345678", @"72345524"];
//        NSString *message = [NSString stringWithFormat:@"Hey, come join my Yaga group, %@. http://getyaga.com", self.groupTitle.text];
//        
//        MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
//        messageController.messageComposeDelegate = self;
//        [messageController setRecipients:recipients];
//        [messageController setBody:message];
//        
//        // Present message view controller on screen
//        [self presentViewController:messageController animated:YES completion:nil];
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
