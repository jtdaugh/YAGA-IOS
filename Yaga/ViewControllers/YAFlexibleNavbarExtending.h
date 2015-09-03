//
//  YAFlexibleNavbarExtending.h
//  Yaga
//
//  Created by valentinkovalski on 8/28/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAStandardFlexibleHeightBar.h"

@protocol YAFlexibleNavbarExtending <NSObject>
@property (nonatomic, strong) BLKFlexibleHeightBar *flexibleNavBar;
@end
