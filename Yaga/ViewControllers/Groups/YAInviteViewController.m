//
//  YAGroupInviteViewController.m
//  Yaga
//
//  Created by Jesse on 4/10/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAInviteViewController.h"

#import "YAInviteCameraViewController.h"
#import "YAPostCaptureViewController.h"
#import "YAUser.h"
#import "YAAssetsCreator.h"
#import "MBProgressHUD.h"
#import "YAGridViewController.h"

#define kMaxUserNamesShown (6)

@interface YAInviteViewController ()

@property (nonatomic, strong) UILabel* titleLable;
@property (nonatomic, strong) UILabel* friendNamesLabel;
@property (nonatomic, strong) UILabel* sendYagaLabel;
@property (nonatomic, strong) UIButton* sendTextButton;
@property (nonatomic, strong) UILabel* suggestQuoteLabel;
@property (nonatomic) NSInteger quoteIndex;

@property (nonatomic, strong) NSTimer* quoteTimer;
@property (nonatomic, strong) NSMutableArray* suggestedQuoteAttributedStrings;
@property (nonatomic, strong) YAInviteCameraViewController *camViewController;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic) CGRect smallCameraFrame;

@property (nonatomic, strong) NSURL *recordingURL;

@end

@implementation YAInviteViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    self.title = @"";
    
    CGFloat width = VIEW_WIDTH * .8;
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = floorf(VIEW_HEIGHT *.075);
    
    if(self.canNavigateBack) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 12, 34, 34)];
        backButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        [backButton setImage:[[UIImage imageNamed:@"Back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        backButton.tintColor = [UIColor whiteColor];
        [backButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:backButton];

    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        
        CGFloat skipWidth = 70;
        UIButton *skipButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - skipWidth - 10, 17, skipWidth, 28)];
        [skipButton setTitle:@"Skip" forState:UIControlStateNormal];
        [skipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [skipButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [skipButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
        skipButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [skipButton addTarget:self action:@selector(skipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:skipButton];
    }
    
    self.friendNamesLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.1f)];
    [self.friendNamesLabel setText:[self getFriendNamesTitle]];
    [self.friendNamesLabel setNumberOfLines:4];
    self.friendNamesLabel.minimumScaleFactor = 0.33f;
    self.friendNamesLabel.adjustsFontSizeToFitWidth = YES;
    [self.friendNamesLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    [self.friendNamesLabel setTextAlignment:NSTextAlignmentCenter];
    [self.friendNamesLabel setTextColor:[UIColor whiteColor]];
    
    [self.view addSubview:self.friendNamesLabel];

    origin = [self getNewOrigin:self.friendNamesLabel];
    CGFloat camWidth = VIEW_WIDTH *.9;

    self.sendYagaLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH-width)/2, origin, width, VIEW_HEIGHT*.07)];
    [self.sendYagaLabel setText:@"Invite em with a Yaga!"];
    [self.sendYagaLabel setNumberOfLines:0];
    [self.sendYagaLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    [self.sendYagaLabel setTextAlignment:NSTextAlignmentCenter];
    [self.sendYagaLabel setTextColor:[UIColor whiteColor]];
    
    [self.view addSubview:self.sendYagaLabel];

    CGFloat bottomOfLabel = self.sendYagaLabel.frame.origin.y + self.sendYagaLabel.frame.size.height;

    self.smallCameraFrame = CGRectMake((VIEW_WIDTH-camWidth)/2, bottomOfLabel, camWidth, VIEW_HEIGHT*.5);
    
    self.camViewController = [YAInviteCameraViewController new];
    self.camViewController.delegate = self;
    self.camViewController.smallCameraFrame = self.smallCameraFrame;
    self.camViewController.view.frame = self.smallCameraFrame;
    self.camViewController.view.layer.masksToBounds = YES;
    [self addChildViewController:self.camViewController];
    [self.view addSubview:self.camViewController.view];
    
    CGFloat quoteWidth = camWidth - 20.f;
    
    self.suggestQuoteLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH-quoteWidth)/2, self.smallCameraFrame.origin.y + 80, quoteWidth, self.smallCameraFrame.size.height - 160)];
    self.suggestQuoteLabel.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:26];
    self.suggestQuoteLabel.textAlignment = NSTextAlignmentCenter;
    self.suggestQuoteLabel.numberOfLines = 2;
    self.suggestQuoteLabel.adjustsFontSizeToFitWidth = YES;
    self.suggestQuoteLabel.minimumScaleFactor = 0.5f;
    self.suggestQuoteLabel.textColor = PRIMARY_COLOR;
    self.suggestQuoteLabel.alpha = 0.8f;
    [self.view addSubview:self.suggestQuoteLabel];
    [self populateSuggestedQuotes];

    origin = [self getNewOrigin:self.camViewController.view];

    UILabel *orLable = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH-width)/2, origin - 10, width, VIEW_HEIGHT*.06)];
    orLable.text = @"or";
    orLable.textAlignment = NSTextAlignmentCenter;
    orLable.textColor = [UIColor whiteColor];
    [orLable setFont:[UIFont fontWithName:BIG_FONT size:15]];
    [self.view addSubview:orLable];
    
    origin += 32;

    self.sendTextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-width)/2, origin, width, VIEW_HEIGHT*.09)];
    [self.sendTextButton setBackgroundColor:[UIColor whiteColor]];
    [self.sendTextButton setTitle:NSLocalizedString(@"Invite with a text", @"") forState:UIControlStateNormal];
    [self.sendTextButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:20]];
    [self.sendTextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.sendTextButton.layer.cornerRadius = 8.0;
    self.sendTextButton.layer.masksToBounds = YES;
    [self.view addSubview:self.sendTextButton];
    [self.sendTextButton addTarget:self action:@selector(sendTextOnlyInvites) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view bringSubviewToFront:self.camViewController.view];
    [self.view bringSubviewToFront:self.suggestQuoteLabel];

    
}

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)populateSuggestedQuotes {
    NSArray *quotes = @[@"You should get Yaga.", @"Yaga is dope. Get it!", @"You gotta get this app", @"Download this. It's worth it."];
    self.suggestedQuoteAttributedStrings = [NSMutableArray array];
    for (NSString *quote in quotes) {
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\"%@\"", quote]
                                                                     attributes:@{
                                                                                  NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                  NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-3]
                                                                                  }];
        [self.suggestedQuoteAttributedStrings addObject:string];
    }
    self.quoteIndex = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    self.quoteTimer = [NSTimer scheduledTimerWithTimeInterval:2.f target:self selector:@selector(switchToNextQuote) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.quoteTimer invalidate];
}

- (void)beganHold {
    self.suggestQuoteLabel.hidden = YES;
}

- (void)endedHold {
    self.hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:self.hud];
    self.hud.labelText = NSLocalizedString(@"Preparing Invite", nil);
    [self.hud show:YES];

    self.suggestQuoteLabel.hidden = NO;
}

- (void)switchToNextQuote {
    if (self.quoteIndex == 0) { // kinda hacky way to make the first quote show up after 2 secs, and then switch every 4 secs
        [self.quoteTimer invalidate];
        self.quoteTimer = [NSTimer scheduledTimerWithTimeInterval:4.f target:self selector:@selector(switchToNextQuote) userInfo:nil repeats:YES];
    }
    self.quoteIndex += 1;
    self.quoteIndex %= [self.suggestedQuoteAttributedStrings count];
    
    CATransition *animation = [CATransition animation];
    animation.duration = 1.f;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.suggestQuoteLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
    [UIView animateWithDuration:0.3f animations:^{
        self.suggestQuoteLabel.layer.transform = CATransform3DMakeRotation((self.quoteIndex % 2) ? .08f : -.08f, 0, 0, .08f);
    } completion:nil];
    self.suggestQuoteLabel.attributedText = self.suggestedQuoteAttributedStrings[self.quoteIndex];
}

- (void)skipButtonPressed:(id)sender {
    // If we presented the create group flow on top of the post-capture screen, dimisss that as well.
    if (self.inCreateGroupFlow) {
        if (self.presentingViewController.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        [self popToGridViewController];
    }
}

- (void)popToGridViewController {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)sendTextOnlyInvites {
    self.hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:self.hud];
    self.hud.labelText = @"One sec...";
    [self.hud show:YES];

    if(![MFMessageComposeViewController canSendText]) {
        [YAUtils showNotification:@"Error: Couldn't send Message" type:YANotificationTypeError];
        [self.hud hide:NO];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"iMESSAGE_COME_JOIN_ME_TEXT", @""), [YAUser currentUser].currentGroup.name];
    NSMutableArray *phoneNumbers = [NSMutableArray new];
    
    for(NSDictionary *contact in self.contactsThatNeedInvite) {
        if([YAUtils validatePhoneNumber:contact[nPhone]])
            [phoneNumbers addObject:contact[nPhone]];
    }
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:phoneNumbers];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:^{
        [self.hud hide:NO];
    }];
}


- (void)sendiMessageToNumbers:(NSArray *)phoneNumbers withVidURL:(NSURL *)url {
    if(![MFMessageComposeViewController canSendText]) {
        [YAUtils showNotification:@"Error: Couldn't send Message" type:YANotificationTypeError];
        [self.hud hide:NO];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"iMESSAGE_COME_JOIN_ME_TEXT", @""), [YAUser currentUser].currentGroup.name];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:phoneNumbers];
    [messageController setBody:message];
    [messageController addAttachmentURL:url withAlternateFilename:@"GET_YAGA.mov"];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:^{
        [self.hud hide:NO];
    }];

}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    [self dismissViewControllerAnimated:YES completion:nil];
    switch (result) {
        case MessageComposeResultCancelled: {
            [[Mixpanel sharedInstance] track:@"iMessage cancelled"];
            break;
        }
        case MessageComposeResultFailed:
        {
            [[Mixpanel sharedInstance] track:@"iMessage failed"];
            [YAUtils showNotification:@"failed to send message" type:YANotificationTypeError];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
            
        case MessageComposeResultSent:
            [[Mixpanel sharedInstance] track:@"iMessage sent"];
//            [YAUtils showNotification:@"message sent" type:YANotificationTypeSuccess];
            [self dismissViewControllerAnimated:YES completion:nil];
            
            break;
    }
}

- (void)popToGrid {
    
}

- (void)finishedRecordingVideoToURL:(NSURL *)videoURL {
    self.recordingURL = videoURL;
    
    NSMutableArray *friendNumbers = [NSMutableArray new];
    for(NSDictionary *contact in self.contactsThatNeedInvite) {
        if([YAUtils validatePhoneNumber:contact[nPhone]])
            [friendNumbers addObject:contact[nPhone]];
    }
    
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURL:videoURL completion:^(NSURL *filePath, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self.hud hide:NO];
                DLog(@"error");
            } else {
                [self sendiMessageToNumbers:friendNumbers withVidURL:filePath];
            }
        });
        
                                                                    }];
}

// Unneccessarily long method :/
- (NSString *)getFriendNamesTitle {
    int andMore = 0;

    YAContact *firstContact = self.contactsThatNeedInvite[0];
    NSString *title = @"";
    if(![firstContact[nFirstname] length]) {
        andMore++;
    } else {
        title = firstContact[nFirstname];
    }
    for (int i = 1; i < MIN([self.contactsThatNeedInvite count] - 1, kMaxUserNamesShown - 1); i++) {
        NSString *contactName = self.contactsThatNeedInvite[i][nFirstname];
        if ([contactName length]) {
            if ([title length]) {
                title = [[title stringByAppendingString:@", "] stringByAppendingString:contactName];
            } else {
                title = contactName;
            }
        } else {
            andMore++;
        }
    }
    if ([self.contactsThatNeedInvite count] > 1 && [self.contactsThatNeedInvite count] <= kMaxUserNamesShown) {
        NSString *contactName = [self.contactsThatNeedInvite lastObject][nFirstname];
        if ([contactName length]) {
            if ([title length] && !andMore) {
                title = [[title stringByAppendingString:@" and "] stringByAppendingString:contactName];
            } else if ([title length] && andMore) {
                title = [[title stringByAppendingString:@", "] stringByAppendingString:contactName];
            } else {
                title = contactName;
            }
        } else {
            andMore++;
        }
    }
    
    if ([self.contactsThatNeedInvite count] > kMaxUserNamesShown) {
        andMore += [self.contactsThatNeedInvite count] - kMaxUserNamesShown;
    }
    
    if (andMore) {
        if ([title length]) {
            if (andMore > 1) {
                title = [NSString stringWithFormat:@"%@ and %d others don't have Yaga yet", title, andMore];
            } else {
                title = [NSString stringWithFormat:@"%@ and %d other don't have Yaga yet", title, andMore];
            }
        } else {
            if (andMore > 1) {
                title = [NSString stringWithFormat:@"%d of those friends don't have Yaga yet", andMore];
            } else {
                title = [NSString stringWithFormat:@"%d of those friends doesn't have Yaga yet", andMore];
            }
        }
    } else {
        if ([self.contactsThatNeedInvite count] == 1) {
            title = [title stringByAppendingString:@" doesn't have Yaga yet."];
        } else {
            title = [title stringByAppendingString:@" don't have Yaga yet."];
        }
    }
    return title;
}


- (CGFloat)getNewOrigin:(UIView *) anchor {
    return anchor.frame.origin.y + anchor.frame.size.height + (VIEW_HEIGHT*.04);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
