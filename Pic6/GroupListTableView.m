//
//  ElevatorTableView.m
//  Pic6
//
//  Created by Raj Vir on 9/22/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupListTableView.h"
#import "GroupListCell.h"
#import "CNetworking.h"

@implementation GroupListTableView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        self.dataSource = self;
        [self setContentInset:UIEdgeInsetsZero];
//        self.delegate = self;
        // Initialization code
    }
    return self;
}

@end
