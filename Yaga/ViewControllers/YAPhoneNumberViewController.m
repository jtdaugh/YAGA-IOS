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

    self.logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT *.025, VIEW_WIDTH, VIEW_HEIGHT*.1)];
    [self.logo setImage:[UIImage imageNamed:@"Logo"]];
    [self.logo setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:self.logo];
    
    self.countryButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.countryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.countryButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:23]];
    self.countryButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.countryButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self.countryButton setImage:[UIImage imageNamed:@"Disclosure"] forState:UIControlStateNormal];
    
    [self.countryButton addTarget:self action:@selector(selectCountryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.countryButton setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.countryButton];

    self.phoneTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.phoneTextField setBackgroundColor:[UIColor whiteColor]];
    [self.phoneTextField setKeyboardType:UIKeyboardTypePhonePad];
    [self.phoneTextField setTextAlignment:NSTextAlignmentCenter];
    [self.phoneTextField setFont:[UIFont fontWithName:BIG_FONT size:32]];
    [self.phoneTextField setTextColor:[UIColor blackColor]];
    [self.phoneTextField setTintColor:[UIColor blackColor]];
    [self.phoneTextField setReturnKeyType:UIReturnKeyDone];
    [self.phoneTextField setPlaceholder:NSLocalizedString(@"Enter phone number", @"")];
    [self.phoneTextField addTarget:self action:@selector(editingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.phoneTextField];
    
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
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
    
    CGFloat separator = 20;
    
    self.countryButton.frame = CGRectMake(0, availableHeight/2+separator - VIEW_HEIGHT*.08, VIEW_WIDTH, VIEW_HEIGHT*.08);
    self.countryButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    self.countryButton.imageEdgeInsets = UIEdgeInsetsMake(0, self.countryButton.frame.size.width - 30, 0, 0);
    self.phoneTextField.frame = CGRectMake(0, availableHeight/2+separator, VIEW_WIDTH, VIEW_HEIGHT*.08);
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
//    [self.countryButton setTitle:[NSString stringWithFormat:@"%@ ‣", [[YAUser currentUser] countryCode]] forState:UIControlStateNormal];
    [self.countryButton setTitle:@"United States (+1)" forState:UIControlStateNormal];

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

    [[Mixpanel sharedInstance] track:@"Entered phone number" properties:@{@"value":formattedNumber}];
    
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
