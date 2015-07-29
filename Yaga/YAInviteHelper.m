//
//  YAInviteHelper.m
//  Yaga
//
//  Created by Jesse on 7/27/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAInviteHelper.h"
#import "MBProgressHUD.h"
#import "YAUser.h"
#import "Constants.h"

#import <MessageUI/MFMessageComposeViewController.h>

#define kMaxUserNamesShown (6)

@interface YAInviteHelper () <MFMessageComposeViewControllerDelegate>

@property (nonatomic, copy) inviteCompletion completion;
@property (nonatomic, strong) NSArray *contactsThatNeedInvite;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, copy) NSString *cancelText;

@end

@implementation YAInviteHelper

- (instancetype)initWithContactsToInvite:(NSArray *)contactsToInvite viewController:(UIViewController *)viewController cancelText:(NSString *)cancelText completion:(inviteCompletion)completion {
    self = [super init];
    if (self ) {
        _contactsThatNeedInvite = contactsToInvite;
        _viewController = viewController;
        _cancelText = cancelText;
        _completion = completion;
    }
    return self;
}

- (void)show {
    MSAlertController *inviteAlert = [MSAlertController alertControllerWithTitle:@"Send Invites" message:[self getFriendNamesTitle] preferredStyle:MSAlertControllerStyleAlert];
    [inviteAlert addAction:[MSAlertAction actionWithTitle:self.cancelText style:MSAlertActionStyleCancel handler:^(MSAlertAction *action) {
        self.completion(NO);
    }]];
    [inviteAlert addAction:[MSAlertAction actionWithTitle:@"Invite" style:MSAlertActionStyleDefault handler:^(MSAlertAction *action) {
        [self.viewController dismissViewControllerAnimated:YES completion:^{
            [self showMessageController];
        }];
        
    }]];
    [self.viewController presentViewController:inviteAlert animated:YES completion:nil];
}

- (void)showMessageController {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = @"One sec...";
    [hud show:YES];
    
    if(![MFMessageComposeViewController canSendText]) {
        [YAUtils showNotification:@"Error: Couldn't send Message" type:YANotificationTypeError];
        [hud hide:NO];
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
    [self.viewController presentViewController:messageController animated:YES completion:^{
        [hud hide:NO];
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

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    BOOL sent = NO;
    switch (result) {
        case MessageComposeResultCancelled: {
            [[Mixpanel sharedInstance] track:@"iMessage cancelled"];
            break;
        }
        case MessageComposeResultFailed:
        {
            [[Mixpanel sharedInstance] track:@"iMessage failed"];
            [YAUtils showNotification:@"failed to send message" type:YANotificationTypeError];
            break;
        }
            
        case MessageComposeResultSent:
            [[Mixpanel sharedInstance] track:@"iMessage sent"];
            //            [YAUtils showNotification:@"message sent" type:YANotificationTypeSuccess];
            sent = YES;
            break;
    }
    self.completion(sent);
}

@end
