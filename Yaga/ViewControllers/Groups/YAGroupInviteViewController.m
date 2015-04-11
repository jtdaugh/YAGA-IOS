//
//  YAGroupInviteViewController.m
//  Yaga
//
//  Created by Jesse on 4/10/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGroupInviteViewController.h"

#import "YAGroupInviteCameraViewController.h"
#import "YAUser.h"
#import "YAAssetsCreator.h"
#import "MBProgressHUD.h"

@interface YAGroupInviteViewController ()

@property (nonatomic, strong) UILabel* titleLable;
@property (nonatomic, strong) UILabel* friendNamesLabel;
@property (nonatomic, strong) UILabel* sendYagaLabel;
@property (nonatomic, strong) UIButton* sendTextButton;
@property (nonatomic, strong) YAGroupInviteCameraViewController *camViewController;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic) CGRect smallCameraFrame;

@end

@implementation YAGroupInviteViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    self.title = @"";
    
    CGFloat width = VIEW_WIDTH * .8;
    
    DLog(@" view width: %f", VIEW_WIDTH);
    
    CGFloat origin = VIEW_HEIGHT *.05;
    
//    self.titleLable = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.08)];
//    [self.titleLable setText:@"Invite"];
//    [self.titleLable setNumberOfLines:1];
//    [self.titleLable setFont:[UIFont fontWithName:BIG_FONT size:24]];
//    [self.titleLable setTextAlignment:NSTextAlignmentCenter];
//    [self.titleLable setTextColor:[UIColor whiteColor]];
//    [self.view addSubview:self.titleLable];
//    
//    origin = [self getNewOrigin:self.titleLable];
    
    self.friendNamesLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - width)/2, origin, width, VIEW_HEIGHT*.1f)];
    [self.friendNamesLabel setText:[self getFriendNamesTitle]];
    [self.friendNamesLabel setNumberOfLines:0];
    [self.friendNamesLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    [self.friendNamesLabel setTextAlignment:NSTextAlignmentCenter];
    [self.friendNamesLabel setTextColor:[UIColor whiteColor]];
    
    [self.view addSubview:self.friendNamesLabel];

    origin = [self getNewOrigin:self.friendNamesLabel];
    CGFloat camWidth = VIEW_WIDTH *.9;

    self.sendYagaLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH-width)/2, origin, width, VIEW_HEIGHT*.06)];
    [self.sendYagaLabel setText:@"Invite em with a Yaga!"];
    [self.sendYagaLabel setNumberOfLines:0];
    [self.sendYagaLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    [self.sendYagaLabel setTextAlignment:NSTextAlignmentCenter];
    [self.sendYagaLabel setTextColor:[UIColor whiteColor]];
    
    [self.view addSubview:self.sendYagaLabel];

    CGFloat bottomOfLabel = self.sendYagaLabel.frame.origin.y + self.sendYagaLabel.frame.size.height;

    self.smallCameraFrame = CGRectMake((VIEW_WIDTH-camWidth)/2, bottomOfLabel, camWidth, VIEW_HEIGHT*.5);
    
    self.camViewController = [YAGroupInviteCameraViewController new];
    self.camViewController.delegate = self;
    self.camViewController.smallCameraFrame = self.smallCameraFrame;
    self.camViewController.view.frame = self.smallCameraFrame;
    self.camViewController.view.layer.masksToBounds = YES;
    [self addChildViewController:self.camViewController];
    [self.view addSubview:self.camViewController.view];
    
    origin = [self getNewOrigin:self.camViewController.view];

    UILabel *orLable = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH-width)/2, origin, width, VIEW_HEIGHT*.06)];
    orLable.text = @"or";
    orLable.textAlignment = NSTextAlignmentCenter;
    orLable.textColor = [UIColor whiteColor];
    [orLable setFont:[UIFont fontWithName:BIG_FONT size:15]];
    [self.view addSubview:orLable];
    
    origin += 38;

    self.sendTextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-width)/2, origin, width, VIEW_HEIGHT*.09)];
    [self.sendTextButton setBackgroundColor:[UIColor whiteColor]];
    [self.sendTextButton setTitle:NSLocalizedString(@"Invite with a text", @"") forState:UIControlStateNormal];
    [self.sendTextButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    [self.sendTextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.sendTextButton.layer.cornerRadius = 8.0;
    self.sendTextButton.layer.masksToBounds = YES;
    
    [self.view addSubview:self.sendTextButton];

    [self.view bringSubviewToFront:self.camViewController.view];

    
}

- (void)sendiMessageToNumbers:(NSArray *)phoneNumbers withVidURL:(NSURL *)url completion:(completionBlock)completion {
    if(![MFMessageComposeViewController canSendText]) {
        [self.hud hide:NO];
        if(completion) {
            NSError *error = [NSError errorWithDomain:@"YAGA" code:0 userInfo:nil];
            completion(error);
        }
        
        return;
    }
    
    //    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"iMESSAGE_COME_JOIN_ME_TEXT", @""), group.name];
    NSString *message = NSLocalizedString(@"iMESSAGE_COME_JOIN_ME_TEXT", @"");
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:phoneNumbers];
    [messageController setBody:message];
    [messageController addAttachmentURL:url withAlternateFilename:@"GET_YAGA.mov"];
    [messageController setSubject:@"Yaga"];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:^{
        if(completion)
            completion(nil);
    }];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    [self.hud hide:NO];
    [controller dismissViewControllerAnimated:YES completion:nil];
    switch (result) {
        case MessageComposeResultCancelled: {
            [controller dismissViewControllerAnimated:YES completion:nil];
            [AnalyticsKit logEvent:@"iMessage cancelled"];
            break;
        }
        case MessageComposeResultFailed:
        {
            [self dismissViewControllerAnimated:YES completion:nil];
            [AnalyticsKit logEvent:@"iMessage failed"];
            [YAUtils showNotification:@"failed to send message" type:YANotificationTypeError];
            if (self.inOnboardingFlow) {
                [self performSegueWithIdentifier:@"CompeteOnboardingAfterInvite" sender:self];
            } else {
                [self.navigationController popToRootViewControllerAnimated:YES];
                NSString *notificationMessage = NSLocalizedString(@"Success", @"");
                [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
            }

            break;
        }
            
        case MessageComposeResultSent:
            [AnalyticsKit logEvent:@"iMessage sent"];
            [YAUtils showNotification:@"message sent" type:YANotificationTypeSuccess];
            if (self.inOnboardingFlow) {
                [self performSegueWithIdentifier:@"CompeteOnboardingAfterInvite" sender:self];
            } else {
                [self.navigationController popToRootViewControllerAnimated:YES];
                NSString *notificationMessage = NSLocalizedString(@"Success", @"");
                [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
            }
            break;
            
        default:
            break;
    }
    
}

- (void)finishedRecordingVideoToURL:(NSURL *)videoURL {
    NSMutableArray *friendNumbers = [NSMutableArray new];
    for(NSDictionary *contact in self.contactsThatNeedInvite) {
        if([YAUtils validatePhoneNumber:contact[nPhone] error:nil])
            [friendNumbers addObject:contact[nPhone]];
    }
    
    self.hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:self.hud];
    self.hud.labelText = NSLocalizedString(@"Preparing Invite", nil);
    [self.hud show:YES];

    
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURLAndSaveToCameraRoll:videoURL
                                                                    completion:^(NSURL *filePath, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (error) {
                [self.hud hide:NO];
                DLog(@"error");
            } else {
                [self sendiMessageToNumbers:friendNumbers withVidURL:filePath completion:^(NSError *error) {
                    if(error)
                        [YAUtils showNotification:@"Error: Couldn't send Message" type:YANotificationTypeError];
                }];
            }
        });
        
                                                                    }];
}

- (NSString *)getFriendNamesTitle {
    NSString *title = self.contactsThatNeedInvite[0][nFirstname];
    
    for (int i = 1; i < [self.contactsThatNeedInvite count] - 1; i++) {
        NSString *contactName = self.contactsThatNeedInvite[i][nFirstname];
        title = [[title stringByAppendingString:@", "] stringByAppendingString:contactName];
    }
    if ([self.contactsThatNeedInvite count] >= 2) {
        NSString *lastContactName = [self.contactsThatNeedInvite lastObject][nFirstname];
        title = [[[title stringByAppendingString:@" and "]
                  stringByAppendingString:lastContactName]
                 stringByAppendingString:@" don't have Yaga yet."];
    } else {
        title = [title stringByAppendingString:@" doesn't have Yaga yet."];
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

//- (void)showCamera:(BOOL)show showPart:(BOOL)showPart animated:(BOOL)animated completion:(cameraCompletion)completion {
//    
//    void (^showHideBlock)(void) = ^void(void) {
//        if(show) {
//            self.camViewController.view.frame = CGRectMake(0, 0, self.camViewController.view.frame.size.width, self.camViewController.view.frame.size.height);
//        }
//        else {
//            self.camViewController.view.frame = self.smallCameraFrame;
//        }
//    };
//    
//    if(animated) {
//        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
//            showHideBlock();
//            
//        } completion:^(BOOL finished) {
//            if(finished && completion)
//                completion();
//        }];
//    }
//    else {
//        showHideBlock();
//    }
//}

@end
