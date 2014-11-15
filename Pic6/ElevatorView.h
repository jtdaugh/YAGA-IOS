//
//  ElevatorView.h
//  Pic6
//
//  Created by Raj Vir on 11/6/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupListTableView.h"

@interface ElevatorView : UIView

@property (strong, nonatomic) UITableView *groupsList;
@property (strong, nonatomic) UIView *tapOut;
@property (strong, nonatomic) UIView *border;
@property (strong, nonatomic) UIButton *createGroup;

@end
