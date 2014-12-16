//
//  AddMembersViewController.h
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAUser.h"
#import "VENTokenField.h"

@interface AddMembersViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, VENTokenFieldDelegate, VENTokenFieldDataSource>
@property (strong, nonatomic) NSMutableArray *selectedContacts;
@end
