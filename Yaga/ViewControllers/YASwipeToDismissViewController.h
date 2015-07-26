//
//  YASwipeToDismissViewController.h
//  
//
//  Created by valentinkovalski on 6/24/15.
//
//

#import <UIKit/UIKit.h>

@interface YASwipeToDismissViewController : UIViewController
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) BOOL showsStatusBarOnDismiss;
- (void)dismissAnimated;
@end
