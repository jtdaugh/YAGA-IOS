//
//  CliqueViewController.h
//  Pic6
//
//  Created by Raj Vir on 7/13/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CliqueViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UITableView *list;

@end
