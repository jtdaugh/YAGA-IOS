//
//  YANotificationView.m
//  Yaga
//
//  Created by valentinkovalski on 2/10/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YANotificationView.h"


@interface YANotificationView ()
@property (nonatomic, copy) actionHandlerBlock actionHandler;
@end

#define kHeight 80

@implementation YANotificationView

- (void)showMessage:(NSString*)message viewType:(YANotificationType)type actionHandler:(void(^)(void))actionHandler {

    UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0, -kHeight, VIEW_WIDTH, kHeight)];
    
    switch (type) {
        case YANotificationTypeSuccess:
            messageView.backgroundColor = PRIMARY_COLOR;
            break;
        case YANotificationTypeMessage:
            messageView.backgroundColor = PRIMARY_COLOR;
            break;
        case YANotificationTypeError:
            messageView.backgroundColor = [UIColor redColor];
            break;
        default:
            break;
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, messageView.frame.size.width - 10, messageView.frame.size.height - 10)];
    label.textColor = [UIColor whiteColor];
    label.text = message;
    label.numberOfLines = 0;
    label.font = [UIFont fontWithName:BIG_FONT size:14];
    [label sizeToFit];
    messageView.frame = CGRectMake(0, messageView.frame.origin.y, VIEW_WIDTH, label.frame.size.height + 10);
    [messageView addSubview:label];
    
    [[UIApplication sharedApplication].keyWindow addSubview:messageView];
    
    if(actionHandler) {
        self.actionHandler = actionHandler;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [messageView addGestureRecognizer:tapRecognizer];
    }
    
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        messageView.center = CGPointMake(messageView.center.x, messageView.frame.size.height/2);
    } completion:^(BOOL finished) {
        if(finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
                    messageView.center = CGPointMake(messageView.center.x, -messageView.frame.size.height/2);
                } completion:nil];
                
            });
        }
    }];
}

- (void)tapped:(id)sender {
    self.actionHandler();
}

+ (void)showMessage:(NSString*)message viewType:(YANotificationType)type {
    YANotificationView *notificationView = [YANotificationView new];
    [notificationView showMessage:message viewType:type actionHandler:nil];
}

@end
