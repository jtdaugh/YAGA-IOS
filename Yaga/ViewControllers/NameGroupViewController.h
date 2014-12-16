//
//  NameGroupViewController.h
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MessageUI;

@interface NameGroupViewController : UIViewController <MFMessageComposeViewControllerDelegate>
@property (strong, nonatomic) NSMutableArray *membersDic;
@end
