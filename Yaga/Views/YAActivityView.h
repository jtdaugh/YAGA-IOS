//
//  YAActivityView.h
//  Yaga
//
//  Created by valentinkovalski on 1/8/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YAActivityView : UIView

- (void)startAnimating;
- (void)stopAnimating;

@property (nonatomic, readonly) BOOL isAnimating;
@end
