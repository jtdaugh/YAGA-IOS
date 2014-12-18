//
//  SplashViewController.m
//  Pic6
//
//  Created by Raj Vir on 9/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAPhoneNumberViewController.h"
#import "NBPhoneNumberUtil.h"
#import "VerifyViewController.h"
#import "UsernameViewController.h"
#import "YAUser.h"
#import "NSString+Hash.h"

//#import "Yaga-Swift.h"
#import "YAAuthManager.h"

@interface YAPhoneNumberViewController ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@end

@implementation YAPhoneNumberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"";
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    NSLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.025;
    self.logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, origin, VIEW_WIDTH, VIEW_HEIGHT*.1)];
    [self.logo setImage:[UIImage imageNamed:@"Logo"]];
    [self.logo setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:self.logo];
    
    origin = [self getNewOrigin:self.logo];
    
    self.cta = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.12)];
    [self.cta setText:@"Enter your phone\n number to get started"];
    [self.cta setNumberOfLines:2];
    [self.cta setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.cta setTextAlignment:NSTextAlignmentCenter];
    [self.cta setTextColor:[UIColor whiteColor]];
    [self.view addSubview:self.cta];
    
    origin = [self getNewOrigin:self.cta];

    
    CGFloat formWidth = VIEW_WIDTH *.7;
    CGFloat gutter = VIEW_WIDTH * .05;
    self.number = [[UITextField alloc] initWithFrame:CGRectMake(VIEW_WIDTH-formWidth-gutter, origin, formWidth, VIEW_HEIGHT*.08)];
    [self.number setBackgroundColor:[UIColor clearColor]];
    [self.number setKeyboardType:UIKeyboardTypePhonePad];
    [self.number setTextAlignment:NSTextAlignmentCenter];
    [self.number setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.number setTextColor:[UIColor whiteColor]];
    [self.number becomeFirstResponder];
    [self.number setTintColor:[UIColor whiteColor]];
    [self.number setReturnKeyType:UIReturnKeyDone];
    [self.number addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.number];
    
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];

    self.country = [[UIButton alloc] initWithFrame:CGRectMake(gutter, origin, VIEW_WIDTH - formWidth - gutter*3, VIEW_HEIGHT*.08)];
    [self.country setTitle:countryCode forState:UIControlStateNormal];
    self.country.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.country.layer.borderWidth = 3.0f;
    [self.country.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    
    [self.country setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.country];
    
    origin = [self getNewOrigin:self.number];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.next = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.next setBackgroundColor:PRIMARY_COLOR];
    [self.next setTitle:@"Next" forState:UIControlStateNormal];
    [self.next.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.next setAlpha:0.0];
    [self.next addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.next setTitle:@"" forState:UIControlStateDisabled];
    [self.view addSubview:self.next];
    //Init activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.next.center;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.next.enabled = YES;
}

- (CGFloat) getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)editingChanged {
    
    if([self.number.text length] > 6){
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        
        NSLog(@"text: %@", self.number.text);
        
        NSError *anError = nil;
        NBPhoneNumber *myNumber = [phoneUtil parse:self.number.text
                                     defaultRegion:@"US" error:&anError];
        
        NSError *error = nil;
        NSString *text = [phoneUtil format:myNumber
                              numberFormat:NBEPhoneNumberFormatNATIONAL
                                     error:&error];
        
        [self.number setText:text];
        
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
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    NSLog(@"text: %@", self.number.text);
    
    NSError *anError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:self.number.text
                                 defaultRegion:@"UA" error:&anError];
    
    NSError *error = nil;
    NSString *formattedNumber = [phoneUtil format:myNumber
                                     numberFormat:NBEPhoneNumberFormatE164
                                            error:&error];
    [[YAUser currentUser] saveUserData:formattedNumber forKey:nPhone];
    
    //Auth manager testing
    [self.activityIndicator startAnimating];
    self.next.enabled = NO;
    __weak typeof(self) weakSelf = self;
    [[YAAuthManager sharedManager] isPhoneNumberRegistered:formattedNumber completion:^(bool registered, NSString *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            [[YAUser currentUser] setPhoneNumberIsRegistered:registered];
            [[YAAuthManager sharedManager] sendSMSAuthRequestWithCompletion:^(bool response, NSString *error) {
                
                [weakSelf performSegueWithIdentifier:@"AuthentificationViewController" sender:self];
                [weakSelf.activityIndicator stopAnimating];
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
