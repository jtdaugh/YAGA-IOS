//
//  YAInviteHelper.h
//  Yaga
//
//  Created by Jesse on 7/27/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^inviteCompletion)(BOOL sent);

@interface YAInviteHelper : NSObject

- (instancetype)initWithContactsToInvite:(NSArray *)contactsToInvite
                               groupName:(NSString *)groupName
                          viewController:(UIViewController *)viewController
                              cancelText:(NSString *)cancelText
                              completion:(inviteCompletion)completion;
- (void)show;

@end