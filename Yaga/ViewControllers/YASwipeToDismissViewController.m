//
//  YASwipeToDismissViewController.m
//  
//
//  Created by valentinkovalski on 6/24/15.
//
//

#import "YASwipeToDismissViewController.h"

@interface YASwipeToDismissViewController ()
@property (nonatomic, assign) BOOL dismissed;
@end

#define kDismissalTreshold 400.0f

@implementation YASwipeToDismissViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.panGesture setMaximumNumberOfTouches:1];
    [self.view addGestureRecognizer:self.panGesture];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

#pragma mark - Animated dismissal
- (void)panGesture:(UIPanGestureRecognizer *)rec
{
    if(self.dismissed)
        return;
    
    if(self.showsStatusBarOnDismiss){
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }

    
    CGPoint vel = [rec velocityInView:self.view];
    CGPoint tr = [rec translationInView:self.view];
    
    if(tr.y != 0) {
        CGFloat f = fabs(tr.y / [UIScreen mainScreen].bounds.size.height);
        if(f < 1) {
            CGRect r = self.view.frame;
            r.origin.y = tr.y;
            r.origin.x = tr.x;
            self.view.frame = r;
        }
        else {
            [self dismissAnimated: vel.y > 0];
            return;
        }
    }
    else {
        [self restoreAnimated];
    }
    
    if(rec.state == UIGestureRecognizerStateEnded) {
        if(fabs(vel.y) > kDismissalTreshold) {
            [self dismissAnimated: vel.y > 0];
            return;
        }
        
        //put back
        [self restoreAnimated];
    }
    
}

- (void)dismissAnimated:(BOOL)dismissToBottom {
    
    self.dismissed = YES;
    [[Mixpanel sharedInstance] track:@"Swiped to Dismiss"];

    if(self.showsStatusBarOnDismiss){
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)dismissAnimated {
    [self dismissAnimated:YES];
}

- (void)restoreAnimated {

    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        self.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finished){
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }];
}


@end
