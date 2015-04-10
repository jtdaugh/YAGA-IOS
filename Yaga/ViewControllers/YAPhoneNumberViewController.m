//
//  SplashViewController.m
//  Pic6
//
//  Created by Raj Vir on 9/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAPhoneNumberViewController.h"
#import "NBPhoneNumberUtil.h"
#import "UsernameViewController.h"
#import "YAUser.h"
#import "YAUtils.h"

#import "NSString+Hash.h"

//#import "Yaga-Swift.h"
#import "YAServer.h"
#import "AFNetworking.h"

@interface YAPhoneNumberViewController ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@end

@implementation YAPhoneNumberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"";
    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    
    CGFloat width = VIEW_WIDTH * .8;
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.025;
    self.logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, origin, VIEW_WIDTH, VIEW_HEIGHT*.1)];
    [self.logo setImage:[UIImage imageNamed:@"Logo"]];
    [self.logo setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:self.logo];
    
    origin = [self getNewOrigin:self.logo];
    
    self.enterPhoneLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.12)];
    [self.enterPhoneLabel setText:@"Enter your phone\n number to get started"];
    [self.enterPhoneLabel setNumberOfLines:2];
    [self.enterPhoneLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.enterPhoneLabel setTextAlignment:NSTextAlignmentCenter];
    [self.enterPhoneLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:self.enterPhoneLabel];
    
    origin = [self getNewOrigin:self.enterPhoneLabel];

    CGFloat formWidth = VIEW_WIDTH *.7;
    CGFloat gutter = VIEW_WIDTH * .05;
    self.phoneTextField = [[UITextField alloc] initWithFrame:CGRectMake(VIEW_WIDTH-formWidth-gutter, origin, formWidth, VIEW_HEIGHT*.08)];
    [self.phoneTextField setBackgroundColor:[UIColor clearColor]];
    [self.phoneTextField setKeyboardType:UIKeyboardTypePhonePad];
    [self.phoneTextField setTextAlignment:NSTextAlignmentCenter];
    [self.phoneTextField setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.phoneTextField setTextColor:[UIColor whiteColor]];
    [self.phoneTextField setTintColor:[UIColor whiteColor]];
    [self.phoneTextField setReturnKeyType:UIReturnKeyDone];
    [self.phoneTextField addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.phoneTextField];
    
    self.countryButton = [[UIButton alloc] initWithFrame:CGRectMake(gutter, origin, VIEW_WIDTH - formWidth - gutter*3, VIEW_HEIGHT*.08)];
    [self.countryButton setTitle:[NSString stringWithFormat:@"%@ 〉", [[YAUser currentUser] countryCode]] forState:UIControlStateNormal];
    self.countryButton.layer.borderColor = [[UIColor blackColor] CGColor];
    self.countryButton.layer.borderWidth = 3.0f;
    self.countryButton.layer.cornerRadius = 8.0f;
    self.countryButton.layer.masksToBounds = YES;
    [self.countryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.countryButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
    [self.countryButton addTarget:self action:@selector(selectCountryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.countryButton setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.countryButton];
    
    origin = [self getNewOrigin:self.phoneTextField];
    
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, origin, buttonWidth, VIEW_HEIGHT*.1)];
    [self.nextButton setBackgroundColor:[UIColor whiteColor]];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.nextButton setAlpha:0.0];
    [self.nextButton addTarget:self action:@selector(nextScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.nextButton setTitle:@"" forState:UIControlStateDisabled];
    
    self.nextButton.layer.cornerRadius = 8.0;
    self.nextButton.layer.masksToBounds = YES;
    
    [self.view addSubview:self.nextButton];
    
    //Init activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.nextButton.center;
    self.activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator.color = PRIMARY_COLOR;
    [self.view addSubview:self.activityIndicator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [self layoutControls:VIEW_HEIGHT];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)layoutControls:(CGFloat)availableHeight {
    self.logo.frame = CGRectMake(0, 0, VIEW_WIDTH, availableHeight/4);
    self.enterPhoneLabel.frame = CGRectMake(0, availableHeight/4, VIEW_WIDTH, availableHeight/4);
    
    CGFloat gutter = VIEW_WIDTH * .05;
    CGFloat formWidth = VIEW_WIDTH *.7;
    CGFloat separator = 20;
    
    self.countryButton.frame = CGRectMake(gutter, availableHeight/2+separator, VIEW_WIDTH - formWidth - gutter*3, VIEW_HEIGHT*.08);
    self.phoneTextField.frame = CGRectMake(VIEW_WIDTH-formWidth-gutter, availableHeight/2+separator, formWidth, VIEW_HEIGHT*.08);
    CGFloat buttonWidth = VIEW_WIDTH * 0.7;
    
    CGFloat heightForButton = availableHeight - self.phoneTextField.frame.origin.y - self.phoneTextField.frame.size.height;
    CGFloat buttonOrigin = self.phoneTextField.frame.origin.y + self.phoneTextField.frame.size.height + heightForButton/2 - VIEW_HEIGHT*.1/2;
    
    self.nextButton.frame = CGRectMake((VIEW_WIDTH-buttonWidth)/2, buttonOrigin, buttonWidth, VIEW_HEIGHT*.1);
    self.activityIndicator.center = self.nextButton.center;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    CGFloat availableHeight = VIEW_HEIGHT - keyboardFrame.size.height;
    [self layoutControls:availableHeight];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self.countryButton setTitle:[NSString stringWithFormat:@"%@ ‣", [[YAUser currentUser] countryCode]] forState:UIControlStateNormal];

//    [self.countryButton setTitle:[[YAUser currentUser] countryCode] forState:UIControlStateNormal];
    self.nextButton.enabled = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.phoneTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.phoneTextField resignFirstResponder];
}
    
- (CGFloat) getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)editingChanged {
    
    if([self.phoneTextField.text length] > 6){
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil new];
        
        DLog(@"text: %@", self.phoneTextField.text);
        
        NSError *anError = nil;
        NBPhoneNumber *myNumber = [phoneUtil parse:self.phoneTextField.text
                                     defaultRegion:[YAUser currentUser].countryCode error:&anError];
        
        NSError *error = nil;
        NSString *text = [phoneUtil format:myNumber
                              numberFormat:NBEPhoneNumberFormatNATIONAL
                                     error:&error];
        
        [self.phoneTextField setText:text];
        
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
    if(![YAServer sharedServer].serverUp) {
        [YAUtils showNotification:NSLocalizedString(@"No internet connection, try later.", @"") type:YANotificationTypeError];
        return;
    }
    
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil new];
    
    DLog(@"text: %@", self.phoneTextField.text);
    
    NSError *anError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:self.phoneTextField.text
                                 defaultRegion:[YAUser currentUser].countryCode error:&anError];
    
    NSError *error = nil;
    NSString *formattedNumber = [phoneUtil format:myNumber
                                     numberFormat:NBEPhoneNumberFormatE164
                                            error:&error];
    
    //Auth manager testing
    [self.activityIndicator startAnimating];
    self.nextButton.enabled = NO;
    __weak typeof(self) weakSelf = self;

    [AnalyticsKit logEvent:@"Entered phone number" withProperties:@{@"value":formattedNumber}];
    
    [[YAServer sharedServer] authentificatePhoneNumberBySMS:formattedNumber withCompletion:^(NSString *responseDictionary, NSError *error) {
        if (error)
        {
            DLog(@"error response dictionary: %@", responseDictionary);
            dispatch_async(dispatch_get_main_queue(),  ^{
                NSString *errorBody = [[NSString alloc] initWithData:error.userInfo [AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                if([errorBody rangeOfString:@"Incorrect phone format."].location != NSNotFound) {
                     NSString *errorMessage = NSLocalizedString(@"Incorrect phone format", @"");
                
                    [YAUtils showNotification:errorMessage
                                         type:YANotificationTypeError];
                }
                else {
                    [weakSelf performSegueWithIdentifier:@"AuthentificationViewController" sender:self];
                }
            });
        } else {
            DLog(@"success response ditionary: %@", responseDictionary);
            [weakSelf performSegueWithIdentifier:@"AuthentificationViewController" sender:self];
        }
        
        weakSelf.nextButton.enabled = YES;
        [weakSelf.activityIndicator stopAnimating];
    }];
}

#pragma mark - Actions 
- (void)selectCountryTapped:(id)sender {
    [self performSegueWithIdentifier:@"PresentCountriesModally" sender:nil];
}

@end
