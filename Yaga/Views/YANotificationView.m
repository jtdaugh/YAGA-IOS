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
@property (nonatomic, strong) UIView *messageView;
@property (nonatomic, assign) BOOL hidesStatusBar;
@end

#define kHeight 64

@implementation YANotificationView

- (void)showMessage:(NSString*)message viewType:(YANotificationType)type actionHandler:(void(^)(void))actionHandler {

    UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0, -kHeight, VIEW_WIDTH, kHeight)];
    
    CALayer *lowerBorder = [CALayer layer];
    lowerBorder.backgroundColor = [[UIColor whiteColor] CGColor];
    lowerBorder.frame = CGRectMake(0, kHeight-2.0f, VIEW_WIDTH, 2.0f);
    
    [messageView.layer addSublayer:lowerBorder];
    
    switch (type) {
        case YANotificationTypeSuccess:
            messageView.backgroundColor = SECONDARY_COLOR;
            break;
        case YANotificationTypeMessage:
            messageView.backgroundColor = SECONDARY_COLOR;
            break;
        case YANotificationTypeError:
            messageView.backgroundColor = [UIColor redColor];
            break;
        default:
            break;
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, messageView.frame.size.width - 10, messageView.frame.size.height - 10)];
    label.textColor = [UIColor whiteColor];
    label.text = message;
    if(actionHandler) {
        label.text = [label.text stringByAppendingString:@" →"];
    }
    
    label.numberOfLines = 0;
    label.font = [UIFont fontWithName:BIG_FONT size:16];
    [label sizeToFit];
    
    CGRect frame = label.frame;
    frame.origin.y = (kHeight - label.frame.size.height)/2;
    label.frame = frame;
    [messageView addSubview:label];
    [[UIApplication sharedApplication].keyWindow addSubview:messageView];
    
    if(actionHandler) {
        self.actionHandler = actionHandler;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [messageView addGestureRecognizer:tapRecognizer];
        
        //make view bigger if needed
        const CGFloat minHeightForTap = 50;
        if(messageView.frame.size.height < minHeightForTap) {
            CGRect r = messageView.frame;
            r.size.height = minHeightForTap;
            messageView.frame = r;
            label.frame = CGRectMake(5, 5, messageView.frame.size.width - 10, messageView.frame.size.height - 10);
        }
    }
    
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        messageView.center = CGPointMake(messageView.center.x, messageView.frame.size.height/2);
    } completion:^(BOOL finished) {
        if(finished) {
            CGFloat secondsToStayOnScreen = self.actionHandler ? 3 : 1;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(secondsToStayOnScreen * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeViewAnimated:messageView];
            });
        }
    }];
}

- (void)removeViewAnimated:(UIView*)messageView {
    if(messageView) {
        
        [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
            messageView.center = CGPointMake(messageView.center.x, -messageView.frame.size.height/2);
        } completion:^(BOOL finished) {
            [messageView removeFromSuperview];
        }];
    }
}

- (void)tapped:(UITapGestureRecognizer*)sender {
    [self removeViewAnimated:sender.view];
    
    self.actionHandler();
}

+ (void)showMessage:(NSString*)message viewType:(YANotificationType)type {
    YANotificationView *notificationView = [YANotificationView new];
    [notificationView showMessage:message viewType:type actionHandler:nil];
}

@end
