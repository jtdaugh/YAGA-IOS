//
//  GroupDetailView.h
//  Pic6
//
//  Created by Veeral Patel on 9/1/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupInfo.h"

@interface GroupDetailView : UITextView

@property (nonatomic, strong) GroupInfo *info;

- (void)flash;

@end
