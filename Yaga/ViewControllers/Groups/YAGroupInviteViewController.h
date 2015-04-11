//
//  YAGroupInviteViewController.h
//  Yaga
//
//  Created by Jesse on 4/10/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "YAGroupInviteCameraViewController.h"
#import <MessageUI/MessageUI.h>

@interface YAGroupInviteViewController : UIViewController <YAInviteCameraViewControllerDelegate,
MFMessageComposeViewControllerDelegate>

@property (nonatomic) BOOL inOnboardingFlow;
@property (strong, nonatomic) NSArray *contactsThatNeedInvite;

@end
