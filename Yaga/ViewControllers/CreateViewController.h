//
//  CreateGroupViewController.h
//  Pic6
//
//  Created by Raj Vir on 8/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CliqueTextField.h"

@interface CreateViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UITableView *list;
@property (strong, nonatomic) NSMutableArray *data;
@property (strong, nonatomic) CliqueTextField *groupName;
@end
