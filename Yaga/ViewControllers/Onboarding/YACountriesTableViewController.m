//
//  YACountriesTableViewController.m
//  Yaga
//
//  Created by Iegor on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YACountriesTableViewController.h"
#import "CountryListDataSource.h"
#import "CountryCell.h"
#import "YAUser.h"

@interface YACountriesTableViewController ()
@property (strong, nonatomic) NSArray *dataRows;
@end

@implementation YACountriesTableViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    CountryListDataSource *dataSource = [CountryListDataSource new];
    self.dataRows = [dataSource countries];
    [self.tableView reloadData];
}

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    CountryCell *cell = (CountryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[CountryCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    id obj = [_dataRows objectAtIndex:indexPath.row];
    if (![obj isKindOfClass:[NSNull class]]) {
        cell.textLabel.text = [obj valueForKey:kCountryName];

        cell.detailTextLabel.text = [obj valueForKey:kCountryCallingCode];
    } else {
        cell.textLabel.text = @"Unknown error";
    }
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark -
#pragma mark Actions
- (IBAction)dismiss:(id)sender {
    NSDictionary *obj = [_dataRows objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    [[YAUser currentUser] setDialCode:obj[DIAL_CODE]];
    [[YAUser currentUser] setCountryCode:obj[COUNTRY_CODE]];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
