//
//  YAPopoverView.h
//  Yaga
//
//  Created by Raj Vir on 7/7/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YACameraViewController.h"

@interface YAPopoverView : UIView

//@property (strong,nonatomic) YACameraViewController *cameraVC;

- (id)initWithTitle:(NSString *)title bodyText:(NSString *)bodyText dismissText:(NSString *)dismissText addToView:(UIView *)view;
- (void)show;
@end
