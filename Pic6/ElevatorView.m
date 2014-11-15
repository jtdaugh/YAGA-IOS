//
//  ElevatorView.m
//  Pic6
//
//  Created by Raj Vir on 11/6/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "ElevatorView.h"

@implementation ElevatorView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tapOut = [[UIView alloc] initWithFrame:frame];
//        [self.tapOut setBackgroundColor:[UIColor greenColor]];
        [self.tapOut setUserInteractionEnabled:YES];
        [self addSubview:self.tapOut];
        
//        self.groupsList = [[GroupListTableView alloc] initWithFrame:CGRectMake(0, ELEVATOR_MARGIN, frame.size.width, frame.size.height - ELEVATOR_MARGIN*2)];
        
    }
    return self;
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
