//
//  UsernameViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/2/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "UsernameViewController.h"
#import "CNetworking.h"
#import "MyCrewsViewController.h"

@interface UsernameViewController ()

@end

@implementation UsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    NSLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.05;
    self.cta = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.08)];
    [self.cta setText:@"Pick a username"];
    [self.cta setNumberOfLines:1];
    [self.cta setFont:[UIFont fontWithName:BIG_FONT size:24]];
    //    [self.cta setBackgroundColor:PRIMARY_COLOR];
    //    [self.cta sizeToFit];
    [self.cta setTextAlignment:NSTextAlignmentCenter];
    [self.cta setTextColor:[UIColor whiteColor]];
    [self.view addSubview:self.cta];
    
    origin = [self getNewOrigin:self.cta];
    
    CGFloat formWidth = VIEW_WIDTH *.8;
    self.username = [[UITextField alloc] initWithFrame:CGRectMake((VIEW_WIDTH-formWidth)/2, origin, formWidth, VIEW_HEIGHT*.08)];
    [self.username setBackgroundColor:[UIColor clearColor]];
    [self.username setKeyboardType:UIKeyboardTypeAlphabet];
    [self.username setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.username setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.username setTextAlignment:NSTextAlignmentCenter];
    [self.username setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.username setTextColor:[UIColor whiteColor]];
    [self.username becomeFirstResponder];
    [self.username setTintColor:[UIColor whiteColor]];
    [self.username setReturnKeyType:UIReturnKeyDone];
    [self.username addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    //    self.username.delegate = self;
    [self.view addSubview:self.username];
    
    origin = [self getNewOrigin:self.username];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.next = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.next setBackgroundColor:PRIMARY_COLOR];
    [self.next setTitle:@"Finish" forState:UIControlStateNormal];
    [self.next.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.next setAlpha:0.0];
    [self.next addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.next];
    
}

- (CGFloat) getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)editingChanged {
    
    if([self.username.text length] > 1){
        
        [UIView animateWithDuration:0.3 animations:^{
            [self.next setAlpha:1.0];
        }];
        
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self.next setAlpha:0.0];
        }];
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)nextScreen {
    
    [self.next setTitle:@"" forState:UIControlStateNormal];
    UIActivityIndicatorView *myIndicator = [[UIActivityIndicatorView alloc]
                                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // Position the spinner
    [self.next addSubview:myIndicator];
    [myIndicator setCenter:CGPointMake(self.next.frame.size.width / 2, self.next.frame.size.height / 2)];
    
    // Start the animation
    [myIndicator startAnimating];
    
    CNetworking *currentUser = [CNetworking currentUser];
    [[CNetworking currentUser] saveUserData:self.username.text forKey:nUsername];
    
    [currentUser registerUserWithCompletionBlock:^(void){
        NSLog(@"completed! %@", (NSString *)[currentUser userDataForKey:nToken]);
        
        if([[currentUser groupInfo] count] > 0){
            MyCrewsViewController *vc = [[MyCrewsViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                //
            }];
        }
    }];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
