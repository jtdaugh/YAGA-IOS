//
//  YACountriesTableViewController.h
//  Yaga
//
//  Created by Iegor on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YACountriesTableViewController : UITableViewController <UISearchBarDelegate>
- (IBAction)dismiss:(id)sender;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@end
